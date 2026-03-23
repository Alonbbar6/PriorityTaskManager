import SwiftUI

struct EditTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var taskGroupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode
    
    let task: Task
    
    // Task properties
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPriority: Priority = .c
    @State private var isUrgent: Bool = false
    @State private var isImportant: Bool = false
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var subPriority: String = ""
    @State private var hasSchedule: Bool = false
    @State private var scheduledDate: Date = Date()
    @State private var scheduledStartTime: Date = Date()
    @State private var scheduledEndTime: Date = Date()
    @State private var selectedGroupId: UUID? = nil
    @State private var selectedScheduleIds: Set<UUID> = []
    @State private var selectedInstanceId: UUID? = nil
    @State private var showInstancePicker = false
    
    @State private var hasLoaded = false

    // Validation
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Basic information section
                Section(header: Text("Task Information")) {
                    TextField("Title (Required)", text: $title)
                        .autocorrectionDisabled()

                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .autocorrectionDisabled()
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
                    
                    if selectedPriority == .a {
                        TextField("Sub-priority (e.g., 1, 2, 3)", text: $subPriority)
                            .keyboardType(.numberPad)
                    }
                    
                    Text(selectedPriority.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Covey Matrix section
                Section(header: Text("Covey Matrix Classification")) {
                    Toggle("Urgent", isOn: $isUrgent)
                    Toggle("Important", isOn: $isImportant)
                    
                    Text("Quadrant: \(currentQuadrant.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Due date section
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                // Group assignment section
                Section(header: Text("Group Assignment")) {
                    Picker("Assign to Group", selection: $selectedGroupId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(taskGroupManager.groups.filter { $0.isActive }) { group in
                            Text("\(group.icon ?? "") \(group.name)")
                                .tag(group.id as UUID?)
                        }
                    }
                    
                    if let groupId = selectedGroupId,
                       let group = taskGroupManager.getGroupById(groupId),
                       !group.recurrences.isEmpty {
                        Text("Select Schedules")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(group.recurrences) { schedule in
                            Toggle(isOn: Binding(
                                get: { selectedScheduleIds.contains(schedule.id) },
                                set: { isOn in
                                    if isOn {
                                        selectedScheduleIds.insert(schedule.id)
                                    } else {
                                        selectedScheduleIds.remove(schedule.id)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(schedule.label ?? "Schedule")
                                        .font(.subheadline)
                                    Text(formatTimeRange(schedule.startTime, schedule.endTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Button {
                            showInstancePicker = true
                        } label: {
                            HStack {
                                Text("Assign to Specific Instance")
                                    .font(.subheadline)
                                Spacer()
                                if let instanceId = selectedInstanceId,
                                   let instance = taskGroupManager.instances.first(where: { $0.id == instanceId }) {
                                    Text("\(instance.date) \(instance.startTime)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Schedule section
                Section(header: Text("Individual Schedule")) {
                    Toggle("Schedule on Calendar", isOn: $hasSchedule)

                    if hasSchedule {
                        DatePicker("Date", selection: $scheduledDate, displayedComponents: [.date])

                        // Show existing time slots for the selected date
                        let blocks = taskGroupManager.dayBlocks(for: scheduledDate)
                        if !blocks.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("BOOKED TIME SLOTS")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                ForEach(blocks, id: \.scheduleId) { block in
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: block.groupColor))
                                            .frame(width: 4, height: 28)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(block.groupName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                            Text(formatTimeRange(block.startTime, block.endTime))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        DatePicker("Start Time", selection: $scheduledStartTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $scheduledEndTime, displayedComponents: [.hourAndMinute])
                    }
                }
            }
            .navigationTitle("Edit Task")
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
            .sheet(isPresented: $showInstancePicker) {
                instancePickerView
            }
            .onAppear {
                loadTaskData()
            }
            .onChange(of: selectedGroupId) { _ in
                guard hasLoaded else { return }
                // Clear stale schedule/instance selections when user switches groups
                selectedScheduleIds.removeAll()
                selectedInstanceId = nil
            }
        }
    }
    
    private func loadTaskData() {
        title = task.title
        notes = task.notes
        selectedPriority = task.priority
        isUrgent = task.isUrgent
        isImportant = task.isImportant
        hasDueDate = task.dueDate != nil
        if let due = task.dueDate {
            dueDate = due
        }
        if let sub = task.subPriority {
            subPriority = String(sub)
        }
        selectedGroupId = task.groupId
        selectedScheduleIds = Set(task.scheduleIds)
        
        hasSchedule = task.scheduledDate != nil
        if let schedDate = task.scheduledDate {
            scheduledDate = schedDate
        }
        
        // Parse time strings to Date objects
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let startTimeStr = task.scheduledStartTime,
           let startTime = formatter.date(from: startTimeStr) {
            scheduledStartTime = startTime
        }
        
        if let endTimeStr = task.scheduledEndTime,
           let endTime = formatter.date(from: endTimeStr) {
            scheduledEndTime = endTime
        }

        hasLoaded = true
    }
    
    private func formatTimeRange(_ start: String, _ end: String) -> String {
        return "\(formatTime(start)) - \(formatTime(end))"
    }
    
    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count >= 2 else { return time }
        let hour = parts[0]
        let minute = parts[1]
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
    
    private var instancePickerView: some View {
        NavigationView {
            List {
                if let groupId = selectedGroupId {
                    let instances = taskGroupManager.instances
                        .filter { $0.groupId == groupId }
                        .sorted { $0.date < $1.date }
                    
                    if instances.isEmpty {
                        Text("No instances available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(instances) { instance in
                            Button {
                                selectedInstanceId = instance.id
                                showInstancePicker = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(formatDate(instance.date))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(formatTime(instance.startTime)) - \(formatTime(instance.endTime))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedInstanceId == instance.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Instance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedInstanceId = nil
                        showInstancePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showInstancePicker = false
                    }
                }
            }
        }
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
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
        
        // Format schedule times
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTimeStr = hasSchedule ? formatter.string(from: scheduledStartTime) : nil
        let endTimeStr = hasSchedule ? formatter.string(from: scheduledEndTime) : nil
        
        // Create updated task
        var updatedTask = task
        updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.priority = selectedPriority
        updatedTask.isUrgent = isUrgent
        updatedTask.isImportant = isImportant
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.subPriority = subPriorityInt
        updatedTask.groupId = selectedGroupId
        updatedTask.scheduleIds = Array(selectedScheduleIds)

        // If assigned to a group schedule, clear individual schedule to avoid double-rendering
        if selectedGroupId != nil && !selectedScheduleIds.isEmpty {
            updatedTask.scheduledDate = nil
            updatedTask.scheduledStartTime = nil
            updatedTask.scheduledEndTime = nil
        } else {
            updatedTask.scheduledDate = hasSchedule ? scheduledDate : nil
            updatedTask.scheduledStartTime = startTimeStr
            updatedTask.scheduledEndTime = endTimeStr
        }
        
        // Update task in manager
        taskManager.updateTask(updatedTask)
        
        // Dismiss view
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTask = Task(
            title: "Sample Task",
            notes: "Sample notes",
            priority: .a,
            isUrgent: true,
            isImportant: true,
            dueDate: nil,
            isCompleted: false,
            subPriority: nil
        )
        
        return EditTaskView(task: sampleTask)
            .environmentObject(TaskManager())
            .environmentObject(TaskGroupManager())
    }
}
