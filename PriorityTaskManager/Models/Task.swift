//
//  Task.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Task data model representing a single task with priority and urgency/importance
//

import Foundation

// Task struct conforming to Identifiable for SwiftUI lists and Codable for persistence
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var notes: String
    var priority: Priority
    var isUrgent: Bool
    var isImportant: Bool
    var dueDate: Date?
    var isCompleted: Bool
    var createdDate: Date
    var subPriority: Int? // For A-1, A-2, etc.
    
    // Initializer with default values
    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        priority: Priority = .c,
        isUrgent: Bool = false,
        isImportant: Bool = false,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        createdDate: Date = Date(),
        subPriority: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.isUrgent = isUrgent
        self.isImportant = isImportant
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.subPriority = subPriority
    }
    
    // Computed property to get Covey quadrant
    var coveyQuadrant: CoveyQuadrant {
        switch (isUrgent, isImportant) {
        case (true, true):
            return .one
        case (false, true):
            return .two
        case (true, false):
            return .three
        case (false, false):
            return .four
        }
    }
    
    // Computed property for display priority with sub-priority
    var displayPriority: String {
        if let sub = subPriority {
            return "\(priority.rawValue)-\(sub)"
        }
        return priority.rawValue
    }
}

// Enum for ABCDE priority levels
enum Priority: String, CaseIterable, Codable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    
    // Description for each priority level
    var description: String {
        switch self {
        case .a:
            return "Must Do - Serious consequences if not done"
        case .b:
            return "Should Do - Mild consequences"
        case .c:
            return "Nice to Do - No consequences"
        case .d:
            return "Delegate - Can be done by someone else"
        case .e:
            return "Eliminate - Should not be done"
        }
    }
    
    // Color for each priority
    var colorName: String {
        switch self {
        case .a:
            return "red"
        case .b:
            return "orange"
        case .c:
            return "yellow"
        case .d:
            return "blue"
        case .e:
            return "gray"
        }
    }
}

// Enum for Covey Matrix quadrants
enum CoveyQuadrant: String, CaseIterable {
    case one = "Q1: Urgent & Important"
    case two = "Q2: Not Urgent & Important"
    case three = "Q3: Urgent & Not Important"
    case four = "Q4: Not Urgent & Not Important"
    
    var shortName: String {
        switch self {
        case .one:
            return "Q1"
        case .two:
            return "Q2"
        case .three:
            return "Q3"
        case .four:
            return "Q4"
        }
    }
    
    var colorName: String {
        switch self {
        case .one:
            return "red"
        case .two:
            return "green"
        case .three:
            return "yellow"
        case .four:
            return "gray"
        }
    }
}
