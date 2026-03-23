//
//  LocalCoreMLAssistant.swift
//  PriorityTaskManager
//
//  On-device AI inference for iOS using Core ML.
//  Downloads the model from HuggingFace on first use (~900 MB).
//
//  SETUP:
//  1. Run: python3 ai_training/convert_to_coreml.py
//  2. Run: python3 ai_training/push_coreml_to_hub.py
//  3. Build and run — model downloads automatically on first AI use.
//

import Foundation
import CoreML

#if os(iOS)

private let COREML_REPO     = "AlonBBar/qwen25-task-assistant-coreml"
private let COREML_HF_BASE  = "https://huggingface.co/\(COREML_REPO)/resolve/main"
private let MODEL_CACHE_DIR : URL = {
    FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("qwen25-coreml", isDirectory: true)
}()

@MainActor
final class LocalCoreMLAssistant: ObservableObject {
    @Published var isModelLoaded    = false
    @Published var isDownloading    = false
    @Published var downloadProgress : Double = 0

    private var mlModel    : MLModel?
    private var vocab      : [String: Int] = [:]
    private var merges     : [(String, String)] = []
    private var byteToChar : [UInt8: Character] = [:]
    private var charToByte : [Character: UInt8] = [:]

    // MARK: - Public API

    /// Delete all cached model files and unload from memory (~900 MB freed).
    func deleteModel() {
        mlModel = nil
        isModelLoaded = false
        try? FileManager.default.removeItem(at: MODEL_CACHE_DIR)
    }

    /// True if the compiled model is already downloaded on this device.
    var isModelDownloaded: Bool {
        let compiledURL = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlmodelc")
        let packageURL  = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlpackage")
        return FileManager.default.fileExists(atPath: compiledURL.path) ||
               FileManager.default.fileExists(atPath: packageURL.path)
    }

    func ensureLoaded() async throws {
        guard mlModel == nil else { return }
        isDownloading = true
        defer { isDownloading = false }

        try await downloadModelIfNeeded()
        downloadProgress = 0
        try await loadModel()
        try loadTokenizer()
        isModelLoaded = true
    }

    /// Generate a response for the given system prompt + user input.
    func run(userInput: String, systemPrompt: String) async throws -> String {
        if mlModel == nil { try await ensureLoaded() }
        guard let model = mlModel else { throw CoreMLError.modelNotLoaded }

        // Qwen2.5 chat template
        let prompt = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n<|im_start|>user\n\(userInput)<|im_end|>\n<|im_start|>assistant\n"
        var inputIds = tokenize(prompt)
        if inputIds.count > 512 { inputIds = Array(inputIds.prefix(512)) }

        let capturedVocab = vocab
        let capturedC2B   = charToByte
        let eosId = capturedVocab["<|im_end|>"] ?? capturedVocab["<|endoftext|>"] ?? 2

        // Run inference off the main thread to keep UI responsive
        let generated = try await _Concurrency.Task.detached(priority: .userInitiated) {
            var ids = inputIds
            var tokens: [Int] = []

            for _ in 0 ..< 512 {
                let seqLen = ids.count
                let shape  = [1, seqLen] as [NSNumber]
                guard let array = try? MLMultiArray(shape: shape, dataType: .int32) else {
                    throw CoreMLError.inferenceError
                }
                for (i, id) in ids.enumerated() { array[i] = NSNumber(value: id) }

                let input  = try MLDictionaryFeatureProvider(dictionary: ["input_ids": array])
                let output = try model.prediction(from: input)

                guard let logits = output.featureValue(for: "logits")?.multiArrayValue else {
                    throw CoreMLError.inferenceError
                }

                let vocabSize  = logits.shape[2].intValue
                let lastOffset = (seqLen - 1) * vocabSize
                var maxLogit: Double = -.infinity
                var maxIdx = 0
                for v in 0 ..< vocabSize {
                    let val = logits[lastOffset + v].doubleValue
                    if val > maxLogit { maxLogit = val; maxIdx = v }
                }

                if maxIdx == eosId { break }
                tokens.append(maxIdx)
                ids.append(maxIdx)
                if ids.count > 512 { break }
            }
            return tokens
        }.value

        return detokenize(generated)
    }

    // MARK: - Download

    private func downloadModelIfNeeded() async throws {
        let compiledURL = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlmodelc")
        let tokenizerURL = MODEL_CACHE_DIR.appendingPathComponent("tokenizer/tokenizer.json")
        guard !FileManager.default.fileExists(atPath: compiledURL.path) ||
              !FileManager.default.fileExists(atPath: tokenizerURL.path) else { return }

        let modelDir = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlpackage")
        guard !FileManager.default.fileExists(atPath: modelDir.path) else { return }

        try FileManager.default.createDirectory(at: MODEL_CACHE_DIR, withIntermediateDirectories: true)

        let filesToDownload = [
            "qwen25-task-assistant.mlpackage/Manifest.json",
            "qwen25-task-assistant.mlpackage/Data/com.apple.CoreML/model.mlmodel",
            "qwen25-task-assistant.mlpackage/Data/com.apple.CoreML/weights/weight.bin",
            "tokenizer/tokenizer.json",
        ]

        let total = Double(filesToDownload.count)
        for (i, file) in filesToDownload.enumerated() {
            let remoteURL = URL(string: "\(COREML_HF_BASE)/\(file)")!
            let localURL  = MODEL_CACHE_DIR.appendingPathComponent(file)
            try FileManager.default.createDirectory(
                at: localURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try await downloadFile(from: remoteURL, to: localURL)
            downloadProgress = Double(i + 1) / total
        }
    }

    private func downloadFile(from remote: URL, to local: URL) async throws {
        let (tmpURL, response) = try await URLSession.shared.download(from: remote)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw CoreMLError.downloadError("HTTP \(http.statusCode) for \(remote.lastPathComponent)")
        }
        if FileManager.default.fileExists(atPath: local.path) {
            try FileManager.default.removeItem(at: local)
        }
        try FileManager.default.moveItem(at: tmpURL, to: local)
    }

    // MARK: - Model Loading

    private func loadModel() async throws {
        let packageURL  = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlpackage")
        let compiledURL = MODEL_CACHE_DIR.appendingPathComponent("qwen25-task-assistant.mlmodelc")

        if !FileManager.default.fileExists(atPath: compiledURL.path) {
            let tmp = try await _Concurrency.Task.detached(priority: .userInitiated) {
                try MLModel.compileModel(at: packageURL)
            }.value
            try FileManager.default.moveItem(at: tmp, to: compiledURL)
            // Delete the .mlpackage after compilation to save ~900 MB
            try? FileManager.default.removeItem(at: packageURL)
        }

        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        mlModel = try await _Concurrency.Task.detached(priority: .userInitiated) {
            try MLModel(contentsOf: compiledURL, configuration: config)
        }.value
    }

    // MARK: - Tokenizer (byte-level BPE, Qwen2.5 / GPT-2 style)

    private func loadTokenizer() throws {
        let tokenizerURL = MODEL_CACHE_DIR.appendingPathComponent("tokenizer/tokenizer.json")
        let data = try Data(contentsOf: tokenizerURL)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let model = json["model"] as? [String: Any] else { return }

        if let vocabDict = model["vocab"] as? [String: Int] {
            vocab = vocabDict
        }

        // Load special tokens (e.g. <|im_start|>, <|im_end|>, <|endoftext|>)
        if let addedTokens = json["added_tokens"] as? [[String: Any]] {
            for token in addedTokens {
                if let content = token["content"] as? String, let id = token["id"] as? Int {
                    vocab[content] = id
                }
            }
        }

        // Merges can be stored as [["a","b"],...] or ["a b",...] depending on tokenizer version
        if let mergesList = model["merges"] as? [[String]] {
            merges = mergesList.compactMap { parts in
                guard parts.count == 2 else { return nil }
                return (parts[0], parts[1])
            }
        } else if let mergesList = model["merges"] as? [String] {
            merges = mergesList.compactMap { line -> (String, String)? in
                let parts = line.split(separator: " ", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
        }

        // Build GPT-2 byte ↔ unicode maps
        (byteToChar, charToByte) = Self.buildByteMaps()
    }

    /// GPT-2 bytes_to_unicode mapping: each byte (0-255) → a unique printable Unicode character.
    private static func buildByteMaps() -> ([UInt8: Character], [Character: UInt8]) {
        var bs: [Int] = Array(33...126) + Array(161...172) + Array(174...255)
        var cs = bs
        var n = 0
        for b in 0..<256 {
            if !bs.contains(b) { bs.append(b); cs.append(256 + n); n += 1 }
        }
        var b2c: [UInt8: Character] = [:]
        var c2b: [Character: UInt8] = [:]
        for (b, c) in zip(bs, cs) {
            guard let scalar = Unicode.Scalar(c) else { continue }
            let ch = Character(scalar)
            b2c[UInt8(b)] = ch
            c2b[ch] = UInt8(b)
        }
        return (b2c, c2b)
    }

    private func tokenize(_ text: String) -> [Int] {
        // Special tokens must be tokenized as single units, not byte-encoded
        let specialTokens = vocab.keys
            .filter { $0.hasPrefix("<|") && $0.hasSuffix("|>") }
            .sorted { $0.count > $1.count }  // longest first to avoid partial matches

        var result: [Int] = []
        var remaining = text

        while !remaining.isEmpty {
            // Try to match a special token at the current position
            var foundSpecial = false
            for special in specialTokens where remaining.hasPrefix(special) {
                if let id = vocab[special] { result.append(id) }
                remaining = String(remaining.dropFirst(special.count))
                foundSpecial = true
                break
            }
            if foundSpecial { continue }

            // Find the next special token boundary
            var endIdx = remaining.endIndex
            for special in specialTokens {
                if let range = remaining.range(of: special), range.lowerBound < endIdx {
                    endIdx = range.lowerBound
                }
            }

            // BPE-encode the non-special chunk
            let chunk = String(remaining[..<endIdx])
            remaining = String(remaining[endIdx...])
            result += bpeEncode(chunk)
        }

        return result
    }

    private func bpeEncode(_ text: String) -> [Int] {
        guard !text.isEmpty else { return [] }

        // Convert each UTF-8 byte to its GPT-2 Unicode character
        var tokens: [String] = text.utf8.compactMap { byteToChar[$0].map { String($0) } }

        // Apply BPE merges
        for (a, b) in merges {
            var i = 0
            while i < tokens.count - 1 {
                if tokens[i] == a && tokens[i + 1] == b {
                    tokens[i] = a + b
                    tokens.remove(at: i + 1)
                } else {
                    i += 1
                }
            }
        }

        return tokens.compactMap { vocab[$0] }
    }

    private func detokenize(_ ids: [Int]) -> String {
        let reverseVocab = Dictionary(uniqueKeysWithValues: vocab.map { ($1, $0) })
        let joined = ids.compactMap { reverseVocab[$0] }.joined()

        // Convert GPT-2 Unicode characters back to their original bytes, then decode as UTF-8
        var bytes: [UInt8] = []
        for ch in joined {
            if let byte = charToByte[ch] {
                bytes.append(byte)
            } else {
                // Pass through regular Unicode (e.g. characters already in normal form)
                bytes.append(contentsOf: String(ch).utf8)
            }
        }
        return String(bytes: bytes, encoding: .utf8) ?? joined
    }

    // MARK: - Errors

    enum CoreMLError: LocalizedError {
        case modelNotLoaded, inferenceError, downloadError(String)
        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:       return "Core ML model not loaded"
            case .inferenceError:       return "Core ML inference failed"
            case .downloadError(let m): return "Download failed: \(m)"
            }
        }
    }
}

#endif
