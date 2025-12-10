//
//  AllTasksView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  View displaying all tasks with filtering options
//

import SwiftUI

struct AllTasksView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var filterOption: FilterOption = .active
    
    // Enum for filter options
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $filterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Task list
                List {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task, showQuadrant: true)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
                
                // Empty state message
                if filteredTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text(emptyStateMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("All Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
    
    // Computed property for filtered tasks
    private var filteredTasks: [Task] {
        switch filterOption {
        case .all:
            return taskManager.tasks.sorted { $0.createdDate > $1.createdDate }
        case .active:
            return taskManager.activeTasks()
        case .completed:
            return taskManager.completedTasks()
        }
    }
    
    // Empty state message based on filter
    private var emptyStateMessage: String {
        switch filterOption {
        case .all:
            return "No tasks yet.\nTap + to create your first task."
        case .active:
            return "No active tasks.\nGreat job staying on top of things!"
        case .completed:
            return "No completed tasks yet.\nComplete tasks to see them here."
        }
    }
    
    // Delete tasks function
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = filteredTasks[index]
            taskManager.deleteTask(task)
        }
    }
}

struct AllTasksView_Previews: PreviewProvider {
    static var previews: some View {
        AllTasksView()
            .environmentObject(TaskManager())
    }
}
