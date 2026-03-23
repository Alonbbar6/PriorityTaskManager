//
//  TaskAIAssistant.swift
//  PriorityTaskManager
//
//  On-device AI task parsing — Core ML on iOS, MLX on macOS.
//  Fully offline, no API calls.
//

import Foundation
import SwiftUI

// Must match the instruction field used in task_training.jsonl
private let COREML_SYSTEM_PROMPT = """
You are a task prioritization assistant for a productivity app. Given a natural language task description, output ONLY a valid JSON object. No markdown, no code blocks, no explanations — raw JSON only.

Required fields:
{
  "title": "concise task title (clean up the input wording)",
  "notes": "additional context extracted from description, or empty string",
  "priority": "A" | "B" | "C" | "D" | "E",
  "isUrgent": true | false,
  "isImportant": true | false,
  "subPriority": 1-9 or null,
  "dueDate": "relative:today" | "relative:tomorrow" | "relative:in_N_days" | "relative:next_monday" | "relative:next_tuesday" | "relative:next_wednesday" | "relative:next_thursday" | "relative:next_friday" | "relative:next_saturday" | "relative:next_sunday" | null,
  "reasoning": "one sentence explaining the priority choice"
}

Priority guide:
  A = Must Do — serious negative consequences if not completed (deadlines, critical tasks, health, finance)
  B = Should Do — mild consequences if skipped (important but flexible timing)
  C = Nice to Do — no real consequences (optional improvements, nice-to-haves)
  D = Delegate — better handled by someone else entirely
  E = Eliminate — provides no value, should be dropped

isUrgent = true if action needed within 24-48 hours
isImportant = true if significant long-term impact on goals or wellbeing
subPriority = integer 1-9 only for priority A (1 = highest priority A task); null otherwise
dueDate = use relative: format only when a date is explicitly mentioned; null if no date in description
"""

// MARK: - TaskAIAssistant

@MainActor
class TaskAIAssistant: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Local on-device model — MLX on macOS, Core ML on iOS.
    let localModel = LocalMLXAssistant()

#if os(iOS)
    /// Core ML model for on-device inference on iOS (iPhone 15 Pro / 16+).
    let coreMLModel = LocalCoreMLAssistant()
#endif

    /// True when the local model has been downloaded and is ready.
    var isLocalModelReady: Bool {
#if os(iOS)
        return coreMLModel.isModelLoaded
#else
        return localModel.isModelLoaded
#endif
    }

    /// Download progress for the local model (0.0 → 1.0).
    var localModelProgress: Double {
#if os(iOS)
        return coreMLModel.downloadProgress
#else
        return localModel.downloadProgress
#endif
    }

    /// True if the model is already saved on this device.
    var isModelDownloaded: Bool {
#if os(iOS)
        return coreMLModel.isModelDownloaded
#else
        return localModel.isModelLoaded
#endif
    }

    /// True while the model files are being downloaded.
    var isDownloadingModel: Bool {
#if os(iOS)
        return coreMLModel.isDownloading
#else
        return localModel.isDownloading
#endif
    }

    /// Parse a free-form task description and return a TaskSuggestion.
    /// Uses on-device model (Core ML on iOS, MLX on macOS) — no internet needed.
    func parseFreeformTask(_ input: String) async -> TaskSuggestion? {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let raw = await callLocalModel(input: input) else { return nil }
        return buildSuggestion(from: raw)
    }

    // MARK: - Private

    private func callLocalModel(input: String) async -> TaskSuggestionRaw? {
#if os(iOS)
        do {
            let output = try await coreMLModel.run(
                userInput: input.trimmingCharacters(in: .whitespacesAndNewlines),
                systemPrompt: COREML_SYSTEM_PROMPT
            )
            return parseModelJSON(output)
        } catch {
            // Show the actual error so we can debug it
            errorMessage = "Core ML: \(error.localizedDescription)"
            return nil
        }
#else
        do {
            let output = try await localModel.run(
                userInput: input.trimmingCharacters(in: .whitespacesAndNewlines),
                systemPrompt: COREML_SYSTEM_PROMPT
            )
            return parseModelJSON(output)
        } catch {
            return nil
        }
#endif
    }

    private func parseModelJSON(_ jsonString: String) -> TaskSuggestionRaw? {
        // Strip markdown code fences if model wraps output despite instructions
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: #"^```(?:json)?\n?"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\n?```$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = cleaned.data(using: .utf8) else {
            errorMessage = "Could not parse AI response"
            return nil
        }

        do {
            return try JSONDecoder().decode(TaskSuggestionRaw.self, from: data)
        } catch {
            errorMessage = "Could not parse AI response"
            return nil
        }
    }

    private func buildSuggestion(from raw: TaskSuggestionRaw) -> TaskSuggestion {
        // If model omits priority, infer it from urgency/importance
        let priorityValue: Priority
        if let p = raw.priority, let parsed = Priority(rawValue: p.uppercased()) {
            priorityValue = parsed
        } else {
            let urgent    = raw.isUrgent ?? false
            let important = raw.isImportant ?? false
            switch (urgent, important) {
            case (true, true):   priorityValue = .a
            case (false, true):  priorityValue = .b
            case (true, false):  priorityValue = .b
            case (false, false): priorityValue = .c
            }
        }
        let priority = priorityValue

        // Strip any extra text after the valid relative: token (e.g. "relative:today at 3pm" → "relative:today")
        let cleanedDueDate = raw.dueDate.map { token -> String in
            let validPrefixes = ["relative:today", "relative:tomorrow", "relative:next_",
                                 "relative:in_"]
            for prefix in validPrefixes where token.hasPrefix(prefix) {
                // Extract only the valid token portion (no spaces or extra text)
                let parts = token.components(separatedBy: " ")
                return parts[0]
            }
            return token
        }
        let dueDate = cleanedDueDate.flatMap { resolveRelativeDate($0) }

        return TaskSuggestion(
            title: raw.title,
            notes: raw.notes ?? "",
            priority: priority,
            isUrgent: raw.isUrgent ?? false,
            isImportant: raw.isImportant ?? false,
            subPriority: priority == .a ? raw.subPriority : nil,
            dueDate: dueDate,
            reasoning: raw.reasoning ?? ""
        )
    }

    /// Convert a "relative:..." token to an absolute Date on the user's device.
    private func resolveRelativeDate(_ token: String) -> Date? {
        guard token.hasPrefix("relative:") else { return nil }

        let relative = String(token.dropFirst("relative:".count)).lowercased()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch relative {
        case "today":
            return calendar.date(byAdding: .hour, value: 12, to: today)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to:
                calendar.date(byAdding: .hour, value: 12, to: today)!)
        default:
            // relative:in_N_days
            if let match = relative.range(of: #"^in_(\d+)_days?$"#, options: .regularExpression) {
                let _ = match
                let digits = relative.components(separatedBy: "_").compactMap { Int($0) }.first
                if let n = digits {
                    return calendar.date(byAdding: .day, value: n, to:
                        calendar.date(byAdding: .hour, value: 12, to: today)!)
                }
            }

            // relative:next_monday ... relative:next_sunday
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            if relative.hasPrefix("next_") {
                let dayName = String(relative.dropFirst("next_".count))
                if let targetWeekday = dayNames.firstIndex(of: dayName) {
                    let currentWeekday = calendar.component(.weekday, from: today) - 1 // 0=Sunday
                    var daysUntil = (targetWeekday - currentWeekday + 7) % 7
                    if daysUntil == 0 { daysUntil = 7 } // at least 1 day ahead
                    return calendar.date(byAdding: .day, value: daysUntil, to:
                        calendar.date(byAdding: .hour, value: 12, to: today)!)
                }
            }

            return nil
        }
    }
}
