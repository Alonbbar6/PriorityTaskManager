import SwiftUI

struct SubtaskListView: View {
    let subtasks: [SubtaskInstance]
    let onToggle: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(subtasks.sorted(by: { $0.order < $1.order })) { subtask in
                Button {
                    onToggle(subtask.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(subtask.isCompleted ? .green : .gray)
                            .font(.title3)

                        Text(subtask.title)
                            .font(.body)
                            .strikethrough(subtask.isCompleted)
                            .foregroundColor(subtask.isCompleted ? .secondary : .primary)

                        Spacer()

                        if let completedAt = subtask.completedAt {
                            Text(completedAt, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())

                if subtask.id != subtasks.sorted(by: { $0.order < $1.order }).last?.id {
                    Divider()
                }
            }
        }
    }
}
