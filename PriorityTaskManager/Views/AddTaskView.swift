//
//  AddTaskView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  View for adding a new task with validation
//

import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    // Task properties
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPriority: Priority = .c
    @State private var isUrgent: Bool = false
    @State private var isImportant: Bool = false
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var subPriority: String = ""
    
    // Validation
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Basic information section
                Section(header: Text("Task Information")) {
                    TextField("Title (Required)", text: $title)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if notes.isEmpty {
                                    Text("Notes (Optional)")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                // ABCDE Priority section
                Section(header: Text("ABCDE Priority")) {
                    Picker("Priority Level", selection: $selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Description of selected priority
                    Text(selectedPriority.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Sub-priority for A tasks
                    if selectedPriority == .a {
                        TextField("Sub-priority (e.g., 1, 2, 3)", text: $subPriority)
                            .keyboardType(.numberPad)
                    }
                }
                
                // Covey Matrix section
                Section(header: Text("Covey Matrix Classification")) {
                    Toggle("Urgent", isOn: $isUrgent)
                    Toggle("Important", isOn: $isImportant)
                    
                    // Show which quadrant this will be in
                    HStack {
                        Text("Quadrant:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currentQuadrant.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Due date section
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Computed property for current quadrant
    private var currentQuadrant: CoveyQuadrant {
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
    
    // Save task with validation
    private func saveTask() {
        // Validate title is not empty
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Task title is required. Please enter a title."
            showingAlert = true
            return
        }
        
        // Validate due date is not in the past
        if hasDueDate && dueDate < Date() {
            alertMessage = "Due date cannot be in the past. Please select a future date."
            showingAlert = true
            return
        }
        
        // Parse sub-priority
        var subPriorityInt: Int? = nil
        if selectedPriority == .a && !subPriority.isEmpty {
            subPriorityInt = Int(subPriority)
        }
        
        // Create new task
        let newTask = Task(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: selectedPriority,
            isUrgent: isUrgent,
            isImportant: isImportant,
            dueDate: hasDueDate ? dueDate : nil,
            isCompleted: false,
            subPriority: subPriorityInt
        )
        
        // Add task to manager
        taskManager.addTask(newTask)
        
        // Dismiss view
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(TaskManager())
    }
}
