import SwiftUI

struct GroupInstanceCardView: View {
    let instance: TaskGroupInstance
    let group: TaskGroup
    var groupTasks: [Task] = []
    var onToggleSubtask: ((UUID) -> Void)?
    var onEditTask: ((Task) -> Void)?

    @State private var isExpanded = false

    private var completedCount: Int {
        instance.subtasks.filter { $0.isCompleted }.count
    }

    private var totalCount: Int {
        instance.subtasks.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        // Icon
                        if let icon = group.icon {
                            Text(icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: group.color).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Name and time
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(formatTimeRange(instance.startTime, instance.endTime))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Progress circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: instance.completionPercentage / 100)
                                .stroke(Color(hex: group.color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(instance.completionPercentage))%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)

                        // Expand chevron
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }

                    // Progress bar
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(Color(hex: group.color))
                                    .frame(width: geo.size.width * CGFloat(instance.completionPercentage / 100), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(completedCount)/\(totalCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    // Subtasks
                    if !instance.subtasks.isEmpty {
                        SubtaskListView(subtasks: instance.subtasks) { subtaskId in
                            onToggleSubtask?(subtaskId)
                        }
                    }

                    // Assigned tasks
                    if !groupTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ASSIGNED TASKS")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            ForEach(groupTasks) { task in
                                Button {
                                    onEditTask?(task)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isCompleted ? .green : .gray)
                                            .font(.subheadline)

                                        Text(task.title)
                                            .font(.subheadline)
                                            .strikethrough(task.isCompleted)
                                            .foregroundColor(task.isCompleted ? .secondary : .primary)

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Empty state
                    if instance.subtasks.isEmpty && groupTasks.isEmpty {
                        Text("No subtasks in this group")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }

                    // Fully completed badge
                    if instance.isFullyCompleted && !instance.subtasks.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("All tasks completed!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .overlay(
            // Left color bar
            HStack {
                Rectangle()
                    .fill(Color(hex: group.color))
                    .frame(width: 4)
                    .cornerRadius(2, corners: [.topLeft, .bottomLeft])
                Spacer()
            }
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// Helper for per-corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
