import SwiftUI

struct AddGroupView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var editGroup: TaskGroup?

    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedPriority: Priority = .c
    @State private var isUrgent: Bool = false
    @State private var isImportant: Bool = false
    @State private var selectedColor: String = groupColors[0]
    @State private var selectedIcon: String = "🏢"
    @State private var recurrences: [RecurrencePattern] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var scheduleToDelete: UUID? = nil

    private let emojiIcons = ["🏢", "🏃", "📚", "🍽️", "🏋️", "🧘", "💼", "🎯", "✍️", "🎨"]

    private var isEditing: Bool { editGroup != nil }

    var body: some View {
        NavigationView {
            Form {
                // Basic Info
                Section(header: Text("Group Information")) {
                    TextField("Group Name (Required)", text: $name)
                        .autocorrectionDisabled()

                    ZStack(alignment: .topLeading) {
                        if descriptionText.isEmpty {
                            Text("Description (Optional)")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $descriptionText)
                            .frame(minHeight: 60)
                            .autocorrectionDisabled()
                    }
                }

                // Appearance
                Section(header: Text("Appearance")) {
                    // Icon
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(emojiIcons, id: \.self) { emoji in
                                    Button {
                                        selectedIcon = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.title)
                                            .frame(width: 48, height: 48)
                                            .background(selectedIcon == emoji ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedIcon == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            ForEach(groupColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                                .padding(2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                // Priority
                Section(header: Text("ABCDE Priority")) {
                    Picker("Priority Level", selection: $selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Text(selectedPriority.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Covey Matrix
                Section(header: Text("Covey Matrix Classification")) {
                    Toggle("Urgent", isOn: $isUrgent)
                    Toggle("Important", isOn: $isImportant)
                }

                // Schedules
                Section {
                    ForEach(recurrences) { pattern in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(pattern.label ?? "Schedule")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button {
                                    scheduleToDelete = pattern.id
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            RecurrencePatternEditor(pattern: stableBinding(for: pattern.id))
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                        let newPattern = RecurrencePattern(
                            label: "Schedule \(recurrences.count + 1)",
                            daysOfWeek: [],
                            startTime: "09:00",
                            endTime: "17:00",
                            startDate: Date(),
                            endDate: threeMonthsFromNow
                        )
                        recurrences.append(newPattern)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Schedule")
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Schedules")
                } footer: {
                    Text("Add at least one schedule to define when this group is active.")
                        .font(.caption)
                }
            }
            .navigationTitle(isEditing ? "Edit Group" : "New Task Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGroup()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Delete Schedule?", isPresented: Binding(
                get: { scheduleToDelete != nil },
                set: { if !$0 { scheduleToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    scheduleToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let id = scheduleToDelete {
                        withAnimation {
                            recurrences.removeAll { $0.id == id }
                        }
                    }
                    scheduleToDelete = nil
                }
            } message: {
                Text("Are you sure you want to remove this schedule from the group?")
            }
            .onAppear {
                if let group = editGroup {
                    name = group.name
                    descriptionText = group.description
                    selectedPriority = group.priority
                    isUrgent = group.isUrgent
                    isImportant = group.isImportant
                    selectedColor = group.color
                    selectedIcon = group.icon ?? "🏢"
                    recurrences = group.recurrences
                }
            }
        }
    }

    /// Creates a stable binding that looks up the recurrence by ID each time,
    /// avoiding stale-index crashes when the array is mutated.
    private func stableBinding(for id: UUID) -> Binding<RecurrencePattern> {
        Binding(
            get: {
                recurrences.first { $0.id == id } ?? RecurrencePattern(
                    label: "Schedule",
                    daysOfWeek: [],
                    startTime: "09:00",
                    endTime: "17:00"
                )
            },
            set: { newValue in
                if let index = recurrences.firstIndex(where: { $0.id == id }) {
                    recurrences[index] = newValue
                }
            }
        )
    }

    private func saveGroup() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Group name is required."
            showingAlert = true
            return
        }

        guard !recurrences.isEmpty else {
            alertMessage = "Please add at least one schedule."
            showingAlert = true
            return
        }

        // Validate each recurrence has days selected
        for (i, rec) in recurrences.enumerated() {
            if rec.daysOfWeek.isEmpty {
                alertMessage = "Schedule \(i + 1) needs at least one day selected."
                showingAlert = true
                return
            }
        }

        if let existing = editGroup {
            var updated = existing
            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.priority = selectedPriority
            updated.isUrgent = isUrgent
            updated.isImportant = isImportant
            updated.color = selectedColor
            updated.icon = selectedIcon
            updated.recurrences = recurrences
            groupManager.updateGroup(updated)
        } else {
            let newGroup = TaskGroup(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                color: selectedColor,
                icon: selectedIcon,
                priority: selectedPriority,
                isUrgent: isUrgent,
                isImportant: isImportant,
                recurrences: recurrences,
                subtaskTemplates: []
            )
            groupManager.addGroup(newGroup)
        }

        presentationMode.wrappedValue.dismiss()
    }
}
