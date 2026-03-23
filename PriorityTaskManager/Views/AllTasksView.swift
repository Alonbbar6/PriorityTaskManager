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
    @State private var searchText = ""
    
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
                
            }
            .searchable(text: $searchText, prompt: "Search tasks")
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // Computed property for filtered tasks
    private var filteredTasks: [Task] {
        let base: [Task]
        switch filterOption {
        case .all:
            base = taskManager.tasks.sorted { $0.createdDate > $1.createdDate }
        case .active:
            base = taskManager.activeTasks()
        case .completed:
            base = taskManager.completedTasks()
        }

        if searchText.isEmpty {
            return base
        }

        let query = searchText.lowercased()
        return base.filter { task in
            task.title.lowercased().contains(query) ||
            task.notes.lowercased().contains(query)
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
    
}

struct AllTasksView_Previews: PreviewProvider {
    static var previews: some View {
        AllTasksView()
            .environmentObject(TaskManager())
    }
}
