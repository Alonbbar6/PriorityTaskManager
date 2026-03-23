import SwiftUI
import Foundation

struct TimelineItem: Identifiable {
    let id = UUID()
    let type: ItemType
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let title: String
    let subtitle: String
    let color: Color
    let icon: String?
    let isCompleted: Bool
    let assignedTasks: [String]
    let onTap: () -> Void

    enum ItemType {
        case groupBlock
        case task
    }

    var startTimeInMinutes: Int {
        startHour * 60 + startMinute
    }

    var endTimeInMinutes: Int {
        endHour * 60 + endMinute
    }

    var durationInMinutes: Int {
        endTimeInMinutes - startTimeInMinutes
    }
}

struct DayTimelineView: View {
    let date: Date
    let items: [TimelineItem]
    /// Current time driven by the parent's timer - ensures fresh values on every render
    let currentTime: Date

    private let hours = Array(0...23)
    private let hourHeight: CGFloat = 80
    private let timeColumnWidth: CGFloat = 50

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }

    private var currentMinute: Int {
        Calendar.current.component(.minute, from: currentTime)
    }

    private var currentTimeOffset: CGFloat? {
        guard isToday else { return nil }
        return CGFloat(currentHour) * hourHeight + CGFloat(currentMinute) / 60.0 * hourHeight
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            hourRow(hour: hour)
                                .id(hour)
                        }
                    }

                    HStack(alignment: .top, spacing: 0) {
                        Color.clear
                            .frame(width: timeColumnWidth, height: CGFloat(hours.count) * hourHeight)

                        ZStack(alignment: .topLeading) {
                            ForEach(items) { item in
                                timelineItemView(item)
                            }

                            if let offset = currentTimeOffset {
                                currentTimeIndicator
                                    .offset(y: offset)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
            .onChange(of: currentHour) { _ in
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }

    private func hourRow(hour: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(formatHour(hour))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 4)

            VStack(spacing: 0) {
                Divider()
                Spacer()
            }
            .frame(height: hourHeight)
        }
    }

    private func timelineItemView(_ item: TimelineItem) -> some View {
        let topOffset = CGFloat(item.startTimeInMinutes) / 60.0 * hourHeight
        let height = max(CGFloat(item.durationInMinutes) / 60.0 * hourHeight, 36)

        return Button(action: item.onTap) {
            HStack(spacing: 6) {
                if let icon = item.icon {
                    Text(icon)
                        .font(.callout)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    if !item.assignedTasks.isEmpty {
                        ForEach(item.assignedTasks, id: \.self) { taskName in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text(taskName)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.primary.opacity(0.7))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: height, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                item.isCompleted
                    ? Color.gray.opacity(0.1)
                    : item.color.opacity(0.15)
            )
            .overlay(
                Rectangle()
                    .fill(item.isCompleted ? Color.gray : item.color)
                    .frame(width: 3),
                alignment: .leading
            )
            .cornerRadius(6)
            .overlay(
                item.isCompleted
                    ? AnyView(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    : AnyView(EmptyView())
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 8)
        .offset(y: topOffset)
    }

    private var currentTimeIndicator: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .offset(x: -4)
    }

    private func formatHour(_ hour: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(displayHour) \(period)"
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        guard isToday else { return }
        let hour = max(currentHour - 1, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                proxy.scrollTo(hour, anchor: .top)
            }
        }
    }
}

struct DayTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        DayTimelineView(
            date: Date(),
            items: [
                TimelineItem(
                    type: .groupBlock,
                    startHour: 9,
                    startMinute: 0,
                    endHour: 10,
                    endMinute: 30,
                    title: "Morning Workout",
                    subtitle: "Weekday Routine",
                    color: .blue,
                    icon: "🏋️",
                    isCompleted: false,
                    assignedTasks: ["Push-ups", "Squats"],
                    onTap: {}
                ),
                TimelineItem(
                    type: .task,
                    startHour: 14,
                    startMinute: 0,
                    endHour: 15,
                    endMinute: 0,
                    title: "Team Meeting",
                    subtitle: "Priority A",
                    color: .red,
                    icon: nil,
                    isCompleted: false,
                    assignedTasks: [],
                    onTap: {}
                )
            ],
            currentTime: Date()
        )
    }
}
