//
//  ABCDEListView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  View displaying tasks organized by ABCDE priority method
//

import SwiftUI

struct ABCDEListView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            List {
                // Information section about ABCDE method
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ABCDE Priority Method")
                            .font(.headline)
                        Text("Organize tasks by priority level from A (must do) to E (eliminate).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Loop through each priority level
                ForEach(Priority.allCases, id: \.self) { priority in
                    let priorityTasks = taskManager.tasksByPriority(priority)
                    
                    // Only show section if there are tasks
                    if !priorityTasks.isEmpty {
                        Section(header: PrioritySectionHeader(priority: priority)) {
                            ForEach(priorityTasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    TaskRowView(task: task)
                                }
                            }
                        }
                    }
                }
                
                // Show message if no tasks
                if taskManager.activeTasks().isEmpty {
                    Section {
                        Text("No active tasks. Tap + to add a new task.")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("ABCDE Priorities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// Custom section header for priority levels
struct PrioritySectionHeader: View {
    let priority: Priority
    
    var body: some View {
        HStack {
            Text(priority.rawValue)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(priorityColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Priority \(priority.rawValue)")
                    .font(.headline)
                Text(priority.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .a:
            return .red
        case .b:
            return .orange
        case .c:
            return .yellow
        case .d:
            return .blue
        case .e:
            return .gray
        }
    }
}

struct ABCDEListView_Previews: PreviewProvider {
    static var previews: some View {
        ABCDEListView()
            .environmentObject(TaskManager())
    }
}
