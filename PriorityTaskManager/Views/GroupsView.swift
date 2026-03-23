import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var taskManager: TaskManager

    /// Wraps the group to edit (or nil for add) with a unique id per presentation,
    /// ensuring .sheet(item:) always creates fresh content.
    private struct GroupSheet: Identifiable {
        let id = UUID()
        let group: TaskGroup?
    }

    @State private var activeSheet: GroupSheet?

    var body: some View {
        NavigationView {
            Group {
                if groupManager.groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Task Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = GroupSheet(group: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                AddGroupView(editGroup: sheet.group)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.4))

            Text("No Task Groups Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first task group to organize recurring tasks like daily work routines, weekly workouts, or scheduled meetings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                activeSheet = GroupSheet(group: nil)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Group")
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    private var groupsList: some View {
        List {
            // Stats row
            HStack(spacing: 16) {
                Label("\(groupManager.groups.count) total", systemImage: "rectangle.3.group")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(groupManager.groups.filter { $0.isActive }.count) active", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)

            ForEach(groupManager.groups) { group in
                GroupCardRow(
                    group: group,
                    taskCount: taskManager.tasksForGroup(group.id).count,
                    onEdit: {
                        activeSheet = GroupSheet(group: group)
                    },
                    onToggleActive: {
                        groupManager.toggleGroupActive(group.id)
                    },
                    onToggleSchedule: {
                        groupManager.toggleShowInSchedule(group.id)
                    },
                    onClone: {
                        if let cloned = groupManager.cloneGroup(group.id) {
                            activeSheet = GroupSheet(group: cloned)
                        }
                    }
                )
            }
            .deleteDisabled(true)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Group Card Row

struct GroupCardRow: View {
    let group: TaskGroup
    let taskCount: Int
    var onEdit: () -> Void
    var onToggleActive: () -> Void
    var onToggleSchedule: () -> Void
    var onClone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 12) {
                if let icon = group.icon {
                    Text(icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: group.color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.name)
                            .font(.headline)
                            .lineLimit(1)
                        if !group.isActive {
                            Text("Inactive")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    if !group.description.isEmpty {
                        Text(group.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                PriorityBadgeView(priority: group.priority, displayText: group.priority.rawValue)
            }

            // Schedule summary
            if !group.recurrences.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(group.recurrences) { rec in
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(formatDaysOfWeek(rec.daysOfWeek)) \(formatTimeRange(rec.startTime, rec.endTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Info row
            HStack(spacing: 12) {
                if taskCount > 0 {
                    Label("\(taskCount) tasks", systemImage: "checklist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Label(group.showInSchedule ? "In Schedule" : "Hidden", systemImage: group.showInSchedule ? "calendar" : "calendar.badge.minus")
                    .font(.caption)
                    .foregroundColor(group.showInSchedule ? .blue : .secondary)
            }

            // Action buttons
            HStack(spacing: 0) {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 16)

                Button { onToggleActive() } label: {
                    Label(group.isActive ? "Deactivate" : "Activate", systemImage: group.isActive ? "pause.circle" : "play.circle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 16)

                Button { onToggleSchedule() } label: {
                    Label(group.showInSchedule ? "Hide" : "Show", systemImage: group.showInSchedule ? "eye.slash" : "eye")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 16)

                Menu {
                    Button { onClone() } label: {
                        Label("Clone", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .opacity(group.isActive ? 1 : 0.6)
    }
}
