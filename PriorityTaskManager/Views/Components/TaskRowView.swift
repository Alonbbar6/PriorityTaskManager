//
//  TaskRowView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Reusable component for displaying a single task row
//

import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var taskManager: TaskManager
    let task: Task
    var showQuadrant: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: {
                taskManager.toggleCompletion(for: task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    // Priority badge
                    PriorityBadgeView(priority: task.priority, displayText: task.displayPriority)
                    
                    // Quadrant badge (optional)
                    if showQuadrant {
                        QuadrantBadgeView(quadrant: task.coveyQuadrant)
                    }
                    
                    // Due date (if exists)
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to check if overdue
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TaskRowView(
                task: Task(
                    title: "Sample Task",
                    notes: "This is a sample task",
                    priority: .a,
                    isUrgent: true,
                    isImportant: true
                )
            )
            .environmentObject(TaskManager())
        }
    }
}
