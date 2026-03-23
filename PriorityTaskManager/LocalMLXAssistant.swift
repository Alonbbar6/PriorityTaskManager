//
//  LocalMLXAssistant.swift
//  PriorityTaskManager
//
//  On macOS (Apple Silicon): runs the fine-tuned Phi-4-mini model locally via MLX.
//  On iOS: not available — TaskAIAssistant automatically falls back to Claude API.
//
//  SETUP (macOS only):
//  1. File → Add Package Dependencies
//     URL: https://github.com/ml-explore/mlx-swift-examples
//     Add targets: MLXLLM, MLXLMCommon — set to PriorityTaskManager
//

import Foundation

#if os(macOS)
import MLXLLM
import MLXLMCommon

private let MLX_MODEL_REPO = "AlonBBar/phi4mini-task-assistant-mlx"

@MainActor
final class LocalMLXAssistant: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0

    private var container: ModelContainer?

    func ensureLoaded() async throws {
        guard container == nil else { return }
        isDownloading = true
        defer { isDownloading = false }

        let config = ModelConfiguration(id: MLX_MODEL_REPO)
        container = try await LLMModelFactory.shared.loadContainer(
            configuration: config
        ) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.downloadProgress = progress.fractionCompleted
            }
        }
        isModelLoaded = true
    }

    func run(userInput: String, systemPrompt: String) async throws -> String {
        if container == nil { try await ensureLoaded() }
        guard let container else { throw LocalMLXError.modelNotLoaded }

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user",   "content": userInput]
        ]

        let result = try await container.perform { context in
            let lmInput = try await context.processor.prepare(
                input: .init(messages: messages)
            )
            return try MLXLMCommon.generate(
                input: lmInput,
                parameters: GenerateParameters(temperature: 0.1, maxTokens: 512),
                context: context
            ) { _ in .more }
        }
        return result.output
    }

    enum LocalMLXError: LocalizedError {
        case modelNotLoaded
        var errorDescription: String? { "Local AI model could not be loaded." }
    }
}

#else

// MARK: - iOS stub (always throws → TaskAIAssistant falls back to Claude API)

@MainActor
final class LocalMLXAssistant: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0

    func ensureLoaded() async throws {
        // Local MLX model not supported on iOS
    }

    func run(userInput: String, systemPrompt: String) async throws -> String {
        throw LocalMLXError.notSupported
    }

    enum LocalMLXError: LocalizedError {
        case notSupported
        var errorDescription: String? { "Local model not available on iOS — using cloud AI." }
    }
}

#endif
