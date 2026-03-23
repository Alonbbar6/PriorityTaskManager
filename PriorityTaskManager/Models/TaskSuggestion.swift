//
//  TaskSuggestion.swift
//  PriorityTaskManager
//
//  Holds the structured output from the AI task parser.
//  Fields mirror the Task struct so suggestions can be applied directly to AddTaskView state.
//

import Foundation

struct TaskSuggestion {
    var title: String
    var notes: String
    var priority: Priority
    var isUrgent: Bool
    var isImportant: Bool
    var subPriority: Int?
    var dueDate: Date?
    var reasoning: String
}

// Decodable helper used to parse the raw JSON from the AI model.
// All fields are optional so partial model output still parses successfully.
struct TaskSuggestionRaw: Decodable {
    let title: String
    let notes: String?
    let priority: String?
    let isUrgent: Bool?
    let isImportant: Bool?
    let subPriority: Int?
    let dueDate: String?
    let reasoning: String?
}
