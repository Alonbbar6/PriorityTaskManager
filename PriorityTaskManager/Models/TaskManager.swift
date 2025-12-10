//
//  TaskManager.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  TaskManager class handles all CRUD operations and data persistence
//

import Foundation

class TaskManager: ObservableObject {
    // Published property to notify views of changes
    @Published var tasks: [Task] = []
    
    // UserDefaults key for persistence
    private let tasksKey = "SavedTasks"
    
    // Initializer loads tasks from UserDefaults
    init() {
        loadTasks()
    }
    
    // MARK: - CRUD Operations
    
    // Create: Add a new task
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    // Read: Get tasks by priority
    func tasksByPriority(_ priority: Priority) -> [Task] {
        return tasks.filter { $0.priority == priority && !$0.isCompleted }
            .sorted { task1, task2 in
                // Sort by sub-priority if both have it
                if let sub1 = task1.subPriority, let sub2 = task2.subPriority {
                    return sub1 < sub2
                }
                return task1.createdDate < task2.createdDate
            }
    }
    
    // Read: Get tasks by Covey quadrant
    func tasksByQuadrant(_ quadrant: CoveyQuadrant) -> [Task] {
        return tasks.filter { $0.coveyQuadrant == quadrant && !$0.isCompleted }
            .sorted { $0.createdDate < $1.createdDate }
    }
    
    // Read: Get active (not completed) tasks
    func activeTasks() -> [Task] {
        return tasks.filter { !$0.isCompleted }
            .sorted { $0.createdDate < $1.createdDate }
    }
    
    // Read: Get completed tasks
    func completedTasks() -> [Task] {
        return tasks.filter { $0.isCompleted }
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    // Update: Modify an existing task
    func updateTask(_ task: Task) {
        // Use guard to safely find the index
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        tasks[index] = task
        saveTasks()
    }
    
    // Delete: Remove a task
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    // Toggle completion status
    func toggleCompletion(for task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }
    
    // MARK: - Persistence
    
    // Save tasks to UserDefaults
    private func saveTasks() {
        // Use guard to handle encoding errors
        guard let encoded = try? JSONEncoder().encode(tasks) else {
            print("Failed to encode tasks")
            return
        }
        UserDefaults.standard.set(encoded, forKey: tasksKey)
    }
    
    // Load tasks from UserDefaults
    private func loadTasks() {
        // Use guard to safely unwrap and decode
        guard let data = UserDefaults.standard.data(forKey: tasksKey),
              let decoded = try? JSONDecoder().decode([Task].self, from: data) else {
            // If no saved tasks, create sample tasks
            createSampleTasks()
            return
        }
        tasks = decoded
    }
    
    // MARK: - Sample Data
    
    // Create sample tasks for demonstration
    private func createSampleTasks() {
        let sampleTasks = [
            Task(
                title: "Complete project proposal",
                notes: "Deadline for board meeting tomorrow",
                priority: .a,
                isUrgent: true,
                isImportant: true,
                subPriority: 1
            ),
            Task(
                title: "Review quarterly reports",
                notes: "Need to finish before Friday",
                priority: .a,
                isUrgent: true,
                isImportant: true,
                subPriority: 2
            ),
            Task(
                title: "Plan next quarter strategy",
                notes: "Important for long-term success",
                priority: .b,
                isUrgent: false,
                isImportant: true
            ),
            Task(
                title: "Return client phone call",
                notes: "Non-critical but should respond",
                priority: .b,
                isUrgent: true,
                isImportant: false
            ),
            Task(
                title: "Coffee with colleague",
                notes: "Nice to catch up",
                priority: .c,
                isUrgent: false,
                isImportant: false
            ),
            Task(
                title: "Organize team meeting notes",
                notes: "Can be delegated to assistant",
                priority: .d,
                isUrgent: false,
                isImportant: false
            )
        ]
        
        tasks = sampleTasks
        saveTasks()
    }
    
    // MARK: - Utility Methods
    
    // Get count of tasks by priority
    func taskCount(for priority: Priority) -> Int {
        return tasksByPriority(priority).count
    }
    
    // Get count of tasks by quadrant
    func taskCount(for quadrant: CoveyQuadrant) -> Int {
        return tasksByQuadrant(quadrant).count
    }
}
