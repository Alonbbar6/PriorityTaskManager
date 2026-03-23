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
    private let appVersionKey = "AppVersion"

    // Initializer loads tasks from UserDefaults
    init() {
        checkAppVersion()
        loadTasks()
    }

    // Check if app was updated and handle migration if needed
    private func checkAppVersion() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let savedVersion = UserDefaults.standard.string(forKey: appVersionKey)

        if savedVersion == nil {
            print("🆕 First launch of app (or first launch with version tracking)")
        } else if savedVersion != currentVersion {
            print("📱 App updated from \(savedVersion ?? "unknown") to \(currentVersion)")
            print("   User data will be preserved across update")
        } else {
            print("✅ App version unchanged: \(currentVersion)")
        }

        // Save current version
        UserDefaults.standard.set(currentVersion, forKey: appVersionKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Clear All Data

    func clearAll() {
        tasks = []
        saveTasks()
    }

    // MARK: - CRUD Operations
    
    // Create: Add a new task
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        notifyScheduleChange()
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
        notifyScheduleChange()
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
        notifyScheduleChange()
    }
    
    // MARK: - Persistence
    
    // Save tasks to UserDefaults
    private func saveTasks() {
        do {
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: tasksKey)

            // Synchronize to ensure data is written immediately
            UserDefaults.standard.synchronize()

            print("✅ Tasks saved successfully (\(tasks.count) tasks)")
        } catch {
            print("❌ ERROR: Failed to encode tasks: \(error)")
            print("   This is a critical error - data will not be persisted!")
        }
    }

    // Load tasks from UserDefaults
    private func loadTasks() {
        print("📂 Loading tasks from UserDefaults...")

        guard let data = UserDefaults.standard.data(forKey: tasksKey) else {
            print("ℹ️ No saved tasks found - first launch or data cleared")
            tasks = []
            return
        }

        print("📦 Found saved data (\(data.count) bytes)")

        do {
            let decoded = try JSONDecoder().decode([Task].self, from: data)
            tasks = decoded
            print("✅ Tasks loaded successfully (\(tasks.count) tasks)")
        } catch {
            print("❌ ERROR: Failed to decode tasks: \(error)")
            print("   Saved data may be corrupted or from an incompatible version")
            print("   Starting with empty task list to prevent crash")
            tasks = []
        }
    }
    
    // MARK: - Group Queries

    func tasksForGroup(_ groupId: UUID) -> [Task] {
        tasks.filter { $0.groupId == groupId }
            .sorted { $0.createdDate < $1.createdDate }
    }

    func tasksForGroupAndSchedule(_ groupId: UUID, scheduleId: UUID) -> [Task] {
        tasks.filter { $0.groupId == groupId && $0.scheduleIds.contains(scheduleId) }
            .sorted { $0.createdDate < $1.createdDate }
    }

    func scheduledTasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledDate = task.scheduledDate else { return false }
            return calendar.isDate(scheduledDate, inSameDayAs: date)
        }
        .sorted { task1, task2 in
            guard let time1 = task1.scheduledStartTime,
                  let time2 = task2.scheduledStartTime else {
                return task1.createdDate < task2.createdDate
            }
            return time1 < time2
        }
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
    
    // MARK: - Notifications
    
    private func notifyScheduleChange() {
        NotificationCenter.default.post(name: .taskScheduleChanged, object: tasks)
    }
}

extension Notification.Name {
    static let taskScheduleChanged = Notification.Name("taskScheduleChanged")
}
