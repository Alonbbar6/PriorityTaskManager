//
//  TaskDetailView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  View for viewing and editing task details
//

import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    let task: Task
    
    // Editing state
    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var editedPriority: Priority = .c
    @State private var editedIsUrgent: Bool = false
    @State private var editedIsImportant: Bool = false
    @State private var editedHasDueDate: Bool = false
    @State private var editedDueDate: Date = Date()
    @State private var editedSubPriority: String = ""
    
    // Alert state
    @State private var showingDeleteAlert: Bool = false
    @State private var showingValidationAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        Form {
            if isEditing {
                // Edit mode
                editingView
            } else {
                // View mode
                viewingView
            }
        }
        .navigationTitle(isEditing ? "Edit Task" : "Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Task"),
                message: Text("Are you sure you want to delete this task?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteTask()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Viewing View
    
    private var viewingView: some View {
        Group {
            // Basic information
            Section(header: Text("Task Information")) {
                HStack {
                    Text("Title")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.title)
                }
                
                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(task.notes)
                    }
                }
                
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.isCompleted ? "Completed" : "Active")
                        .foregroundColor(task.isCompleted ? .green : .blue)
                }
            }
            
            // Priority information
            Section(header: Text("Priority")) {
                HStack {
                    Text("ABCDE Priority")
                        .foregroundColor(.secondary)
                    Spacer()
                    PriorityBadgeView(priority: task.priority, displayText: task.displayPriority)
                }
                
                Text(task.priority.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Covey Matrix
            Section(header: Text("Covey Matrix")) {
                HStack {
                    Text("Urgent")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.isUrgent ? "Yes" : "No")
                }
                
                HStack {
                    Text("Important")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.isImportant ? "Yes" : "No")
                }
                
                HStack {
                    Text("Quadrant")
                        .foregroundColor(.secondary)
                    Spacer()
                    QuadrantBadgeView(quadrant: task.coveyQuadrant)
                }
            }
            
            // Due date
            if let dueDate = task.dueDate {
                Section(header: Text("Due Date")) {
                    HStack {
                        Text("Due")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(dueDate))
                            .foregroundColor(isOverdue(dueDate) ? .red : .primary)
                    }
                }
            }
            
            // Actions
            Section {
                Button(action: {
                    taskManager.toggleCompletion(for: task)
                }) {
                    HStack {
                        Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                        Text(task.isCompleted ? "Mark as Active" : "Mark as Completed")
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Task")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
        Group {
            Section(header: Text("Task Information")) {
                TextField("Title (Required)", text: $editedTitle)
                
                TextEditor(text: $editedNotes)
                    .frame(height: 100)
            }
            
            Section(header: Text("ABCDE Priority")) {
                Picker("Priority Level", selection: $editedPriority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if editedPriority == .a {
                    TextField("Sub-priority (e.g., 1, 2, 3)", text: $editedSubPriority)
                        .keyboardType(.numberPad)
                }
            }
            
            Section(header: Text("Covey Matrix Classification")) {
                Toggle("Urgent", isOn: $editedIsUrgent)
                Toggle("Important", isOn: $editedIsImportant)
            }
            
            Section(header: Text("Due Date")) {
                Toggle("Set Due Date", isOn: $editedHasDueDate)
                
                if editedHasDueDate {
                    DatePicker("Due Date", selection: $editedDueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func startEditing() {
        editedTitle = task.title
        editedNotes = task.notes
        editedPriority = task.priority
        editedIsUrgent = task.isUrgent
        editedIsImportant = task.isImportant
        editedHasDueDate = task.dueDate != nil
        editedDueDate = task.dueDate ?? Date()
        editedSubPriority = task.subPriority != nil ? String(task.subPriority!) : ""
        isEditing = true
    }
    
    private func saveChanges() {
        // Validate title
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Task title is required."
            showingValidationAlert = true
            return
        }
        
        // Parse sub-priority
        var subPriorityInt: Int? = nil
        if editedPriority == .a && !editedSubPriority.isEmpty {
            subPriorityInt = Int(editedSubPriority)
        }
        
        // Create updated task
        var updatedTask = task
        updatedTask.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.priority = editedPriority
        updatedTask.isUrgent = editedIsUrgent
        updatedTask.isImportant = editedIsImportant
        updatedTask.dueDate = editedHasDueDate ? editedDueDate : nil
        updatedTask.subPriority = subPriorityInt
        
        // Update in manager
        taskManager.updateTask(updatedTask)
        
        isEditing = false
    }
    
    private func deleteTask() {
        taskManager.deleteTask(task)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(
                task: Task(
                    title: "Sample Task",
                    notes: "This is a sample task with notes",
                    priority: .a,
                    isUrgent: true,
                    isImportant: true,
                    subPriority: 1
                )
            )
            .environmentObject(TaskManager())
        }
    }
}
