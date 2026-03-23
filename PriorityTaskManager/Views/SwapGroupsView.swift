import SwiftUI

struct SwapGroupsView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    let date: Date
    let dayBlocks: [ScheduleBlock]
    let alreadySwappedIds: Set<UUID>

    @State private var selections: [UUID] = []

    private var selectedBlockA: ScheduleBlock? {
        guard selections.count >= 1 else { return nil }
        return dayBlocks.first { $0.scheduleId == selections[0] }
    }

    private var selectedBlockB: ScheduleBlock? {
        guard selections.count >= 2 else { return nil }
        return dayBlocks.first { $0.scheduleId == selections[1] }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                Text("Select two groups to swap their schedule positions for today.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))

                // Group list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dayBlocks, id: \.scheduleId) { block in
                            let isSelected = selections.contains(block.scheduleId)
                            let isSwapped = alreadySwappedIds.contains(block.scheduleId)
                            let isDisabled = isSwapped || (!isSelected && selections.count >= 2)

                            Button {
                                toggleSelection(block.scheduleId)
                            } label: {
                                HStack(spacing: 12) {
                                    // Icon
                                    if let icon = block.groupIcon {
                                        Text(icon)
                                            .font(.title2)
                                            .frame(width: 44, height: 44)
                                            .background(Color(hex: block.groupColor).opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }

                                    // Info
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(block.groupName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("\(block.scheduleLabel) \u{00B7} \(formatTimeRange(block.startTime, block.endTime))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if isSwapped {
                                            Text("Already swapped today")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    Spacer()

                                    // Selection indicator
                                    ZStack {
                                        Circle()
                                            .stroke(isSelected ? Color.blue : isSwapped ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        if isSelected {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "checkmark")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        } else if isSwapped {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                                )
                                .overlay(
                                    HStack {
                                        Rectangle()
                                            .fill(Color(hex: block.groupColor))
                                            .frame(width: 4)
                                            .cornerRadius(2, corners: [.topLeft, .bottomLeft])
                                        Spacer()
                                    }
                                )
                                .opacity(isDisabled ? 0.5 : 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isDisabled)
                        }
                    }
                    .padding()
                }

                // Preview + Confirm
                if let blockA = selectedBlockA, let blockB = selectedBlockB {
                    VStack(spacing: 12) {
                        // Preview
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PREVIEW")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: blockA.groupColor))
                                    .frame(width: 8, height: 8)
                                Text(blockA.groupName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(formatTimeRange(blockA.startTime, blockA.endTime))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(formatTimeRange(blockB.startTime, blockB.endTime))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: blockB.groupColor))
                                    .frame(width: 8, height: 8)
                                Text(blockB.groupName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(formatTimeRange(blockB.startTime, blockB.endTime))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(formatTimeRange(blockA.startTime, blockA.endTime))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Buttons
                        HStack(spacing: 12) {
                            Button {
                                selections = []
                            } label: {
                                Text("Clear")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }

                            Button {
                                groupManager.createSwap(blockA, blockB, date: date)
                                selections = []
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("Swap Groups")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                }
            }
            .navigationTitle("Swap Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func toggleSelection(_ scheduleId: UUID) {
        if alreadySwappedIds.contains(scheduleId) { return }
        if selections.contains(scheduleId) {
            selections.removeAll { $0 == scheduleId }
        } else if selections.count < 2 {
            selections.append(scheduleId)
        }
    }
}
