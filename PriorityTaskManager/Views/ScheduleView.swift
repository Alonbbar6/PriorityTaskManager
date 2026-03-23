import SwiftUI
import Combine

enum ScheduleViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct ScheduleView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var taskManager: TaskManager

    @State private var viewMode: ScheduleViewMode = .day
    @State private var selectedDate = Date()
    @State private var showConflictPanel = false
    @State private var showTaskConflictPanel = false
    @State private var showSwapModal = false
    @State private var showAddTask = false
    @State private var showEditTask = false
    @State private var selectedTask: Task? = nil
    @State private var selectedBlock: ScheduleBlock? = nil
    @State private var showBlockDetail = false

    /// Timer-driven current time so TimelineView always gets a fresh value
    @State private var currentTime = Date()
    private let clockTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var dayBlocks: [ScheduleBlock] {
        groupManager.dayBlocks(for: selectedDate)
    }

    private var conflicts: [ScheduleConflict] {
        groupManager.conflicts(for: selectedDate)
    }

    private var taskConflicts: [TaskScheduleConflict] {
        groupManager.taskConflicts(for: selectedDate, tasks: taskManager.tasks)
    }

    private var swapsForDay: [ScheduleSwap] {
        groupManager.swapsForDate(selectedDate)
    }

    private var hasSwapsForDay: Bool {
        !swapsForDay.isEmpty
    }

    private var alreadySwapped: Set<UUID> {
        groupManager.alreadySwappedScheduleIds(for: selectedDate)
    }

    private var dismissedToday: [(entry: DismissedEntry, groupName: String, groupColor: String, groupIcon: String?, scheduleLabel: String)] {
        groupManager.dismissedItemsForDate(selectedDate)
    }

    private var instances: [TaskGroupInstance] {
        groupManager.visibleInstances(for: selectedDate)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Date navigation
                dateNavigator

                // Conflict banners
                if !conflicts.isEmpty {
                    conflictBanner
                }
                if !taskConflicts.isEmpty {
                    taskConflictBanner
                }

                // Active swaps banner
                if hasSwapsForDay {
                    swapsBanner
                }

                // Dismissed items banner
                if !dismissedToday.isEmpty {
                    dismissedBanner
                }

                // Main content
                switch viewMode {
                case .day:
                    dayView
                case .week:
                    weekView
                case .month:
                    monthView
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedDate = Date()
                    } label: {
                        Text("Today")
                            .font(.subheadline)
                    }
                }
            }
            .overlay(
                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
            .sheet(isPresented: $showSwapModal) {
                SwapGroupsView(
                    date: selectedDate,
                    dayBlocks: dayBlocks,
                    alreadySwappedIds: alreadySwapped
                )
            }
            .sheet(isPresented: $showConflictPanel) {
                conflictSheet
            }
            .sheet(isPresented: $showTaskConflictPanel) {
                taskConflictSheet
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showEditTask) {
                if let task = selectedTask {
                    EditTaskView(task: task)
                }
            }
            .sheet(isPresented: $showBlockDetail) {
                if let block = selectedBlock {
                    blockDetailSheet(block)
                }
            }
            .onAppear {
                currentTime = Date()
            }
            .onReceive(clockTimer) { newTime in
                currentTime = newTime
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Date Navigator

    private var dateNavigator: some View {
        HStack {
            Button {
                navigate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(dateTitle)
                    .font(.headline)
                Text(dateSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                navigate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMM d"
        case .week:
            let weekStart = startOfWeek(selectedDate)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return "\(f.string(from: weekStart)) - \(f.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private var dateSubtitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) {
            return "Today"
        } else if cal.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if cal.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedDate)
    }

    private func navigate(by amount: Int) {
        let cal = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = cal.date(byAdding: .day, value: amount, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .weekOfYear, value: amount, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = cal.date(byAdding: .month, value: amount, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Banners

    private var conflictBanner: some View {
        Button {
            showConflictPanel = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("\(conflicts.count) schedule conflict\(conflicts.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                Spacer()
                Text("View")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private var taskConflictBanner: some View {
        Button {
            showTaskConflictPanel = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.purple)
                Text("\(taskConflicts.count) task overlap\(taskConflicts.count == 1 ? "" : "s") with groups")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                Spacer()
                Text("Resolve")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private var swapsBanner: some View {
        VStack(spacing: 6) {
            ForEach(swapsForDay) { swap in
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(swap.blockA.groupName) swapped with \(swap.blockB.groupName)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        groupManager.undoSwap(swap.id)
                    } label: {
                        Text("Undo")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
            }
            if swapsForDay.count > 1 {
                Button {
                    groupManager.resetDaySwaps(for: selectedDate)
                } label: {
                    Text("Reset all swaps")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(10)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var dismissedBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISMISSED TODAY")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            ForEach(dismissedToday, id: \.entry.scheduleId) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: item.groupColor))
                        .frame(width: 8, height: 8)
                    Text("\(item.groupName) - \(item.scheduleLabel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        groupManager.restoreForDay(item.entry.scheduleId, date: selectedDate)
                    } label: {
                        Text("Restore")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Day View

    private var dayView: some View {
        let scheduledTasks = taskManager.scheduledTasksForDate(selectedDate)
        let timelineItems = buildTimelineItems(blocks: dayBlocks, tasks: scheduledTasks)

        return VStack(spacing: 0) {
            if timelineItems.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("Nothing Scheduled")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Create a task group with a schedule, or add an individually scheduled task to see it here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DayTimelineView(date: selectedDate, items: timelineItems, currentTime: currentTime)
            }

            if dayBlocks.count >= 2 {
                Button {
                    showSwapModal = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Swap groups for today")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private func buildTimelineItems(blocks: [ScheduleBlock], tasks: [Task]) -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        for block in blocks {
            let blockTasks = taskManager.tasksForGroupAndSchedule(block.groupId, scheduleId: block.scheduleId)
                .filter { !$0.isCompleted }
                .map { $0.title }

            if let (startH, startM) = parseTime(block.startTime),
               let (endH, endM) = parseTime(block.endTime) {
                items.append(TimelineItem(
                    type: .groupBlock,
                    startHour: startH,
                    startMinute: startM,
                    endHour: endH,
                    endMinute: endM,
                    title: block.groupName,
                    subtitle: block.scheduleLabel,
                    color: Color(hex: block.groupColor),
                    icon: block.groupIcon,
                    isCompleted: false,
                    assignedTasks: blockTasks,
                    onTap: {
                        selectedBlock = block
                        showBlockDetail = true
                    }
                ))
            }
        }
        
        for task in tasks {
            // Skip tasks assigned to a group schedule — they're already represented by the group block
            if task.groupId != nil && !task.scheduleIds.isEmpty {
                continue
            }

            guard let startTime = task.scheduledStartTime,
                  let endTime = task.scheduledEndTime,
                  let (startH, startM) = parseTime(startTime),
                  let (endH, endM) = parseTime(endTime) else {
                continue
            }
            
            let priorityColor: Color = {
                switch task.priority {
                case .a: return .red
                case .b: return .orange
                case .c: return .yellow
                case .d: return .blue
                case .e: return .gray
                }
            }()
            
            items.append(TimelineItem(
                type: .task,
                startHour: startH,
                startMinute: startM,
                endHour: endH,
                endMinute: endM,
                title: task.title,
                subtitle: "Priority \(task.priority.rawValue)",
                color: priorityColor,
                icon: nil,
                isCompleted: task.isCompleted,
                assignedTasks: [],
                onTap: {
                    selectedTask = task
                    showEditTask = true
                }
            ))
        }
        
        return items.sorted { $0.startTimeInMinutes < $1.startTimeInMinutes }
    }
    
    private func parseTime(_ timeStr: String) -> (hour: Int, minute: Int)? {
        let components = timeStr.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }

    private func scheduleBlockCard(_ block: ScheduleBlock) -> some View {
        HStack(spacing: 12) {
            // Time column
            VStack(spacing: 2) {
                Text(formatTime(block.startTime))
                    .font(.caption)
                    .fontWeight(.semibold)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .frame(maxHeight: 20)
                Text(formatTime(block.endTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 55)

            // Block content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let icon = block.groupIcon {
                        Text(icon)
                            .font(.callout)
                    }
                    Text(block.groupName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                Text(block.scheduleLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(hex: block.groupColor).opacity(0.1))
            .overlay(
                Rectangle()
                    .fill(Color(hex: block.groupColor))
                    .frame(width: 4),
                alignment: .leading
            )
            .cornerRadius(8)

            // Dismiss button
            Button {
                groupManager.dismissForDay(block.scheduleId, groupId: block.groupId, date: selectedDate)
            } label: {
                Image(systemName: "eye.slash")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Week View

    private var weekView: some View {
        let weekStart = startOfWeek(selectedDate)
        let weekDates = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }

        return ScrollView {
            VStack(spacing: 0) {
                // Day headers
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        let isToday = Calendar.current.isDateInToday(date)
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                        Button {
                            selectedDate = date
                            viewMode = .day
                        } label: {
                            VStack(spacing: 4) {
                                Text(dayShortName(date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.callout)
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundColor(isToday ? .white : isSelected ? .blue : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(isToday ? Color.blue : Color.clear)
                                    .clipShape(Circle())
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // Week schedule blocks
                ForEach(weekDates, id: \.self) { date in
                    let blocks = groupManager.dayBlocks(for: date)
                    if !blocks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(dayFullName(date))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)

                            ForEach(blocks, id: \.scheduleId) { block in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: block.groupColor))
                                        .frame(width: 8, height: 8)
                                    Text(block.groupName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(formatTimeRange(block.startTime, block.endTime))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(hex: block.groupColor).opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if weekDates.allSatisfy({ groupManager.dayBlocks(for: $0).isEmpty }) {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 36))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("No scheduled groups this week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? selectedDate
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = cal.component(.weekday, from: monthStart) - 1
        let totalCells = firstWeekday + daysInMonth
        let weeks = (totalCells + 6) / 7

        return ScrollView {
            VStack(spacing: 0) {
                // Day of week headers
                HStack(spacing: 0) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, d in
                        Text(d)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)

                // Calendar grid
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { weekday in
                            let cellIndex = week * 7 + weekday
                            let dayNumber = cellIndex - firstWeekday + 1

                            if dayNumber >= 1 && dayNumber <= daysInMonth {
                                let date = cal.date(from: DateComponents(year: cal.component(.year, from: monthStart), month: cal.component(.month, from: monthStart), day: dayNumber)) ?? monthStart
                                let blocks = groupManager.dayBlocks(for: date)
                                let isToday = cal.isDateInToday(date)
                                let isSelected = cal.isDate(date, inSameDayAs: selectedDate)

                                Button {
                                    selectedDate = date
                                    viewMode = .day
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(dayNumber)")
                                            .font(.caption)
                                            .fontWeight(isToday ? .bold : .regular)
                                            .foregroundColor(isToday ? .white : isSelected ? .blue : .primary)
                                            .frame(width: 28, height: 28)
                                            .background(isToday ? Color.blue : Color.clear)
                                            .clipShape(Circle())

                                        // Dots for scheduled groups
                                        HStack(spacing: 2) {
                                            ForEach(blocks.prefix(3), id: \.scheduleId) { block in
                                                Circle()
                                                    .fill(Color(hex: block.groupColor))
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Conflict Sheet

    private var conflictSheet: some View {
        NavigationView {
            List {
                ForEach(conflicts, id: \.id) { conflict in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: conflict.blockA.groupColor))
                                .frame(width: 10, height: 10)
                            Text(conflict.blockA.groupName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(formatTimeRange(conflict.blockA.startTime, conflict.blockA.endTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("overlaps with")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.leading, 18)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: conflict.blockB.groupColor))
                                .frame(width: 10, height: 10)
                            Text(conflict.blockB.groupName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(formatTimeRange(conflict.blockB.startTime, conflict.blockB.endTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Swap button for this conflict
                        Button {
                            groupManager.createSwap(conflict.blockA, conflict.blockB, date: selectedDate)
                            showConflictPanel = false
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Swap groups for today")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Schedule Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showConflictPanel = false
                    }
                }
            }
        }
    }

    // MARK: - Task Conflict Resolution Sheet

    private var taskConflictSheet: some View {
        NavigationView {
            List {
                ForEach(taskConflicts) { conflict in
                    VStack(alignment: .leading, spacing: 10) {
                        // Task info
                        HStack(spacing: 8) {
                            Image(systemName: "checklist")
                                .font(.caption)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conflict.task.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let start = conflict.task.scheduledStartTime,
                                   let end = conflict.task.scheduledEndTime {
                                    Text(formatTimeRange(start, end))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // Overlap indicator
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text("overlaps with")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .padding(.leading, 18)

                        // Group block info
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: conflict.block.groupColor))
                                .frame(width: 10, height: 10)
                            Text(conflict.block.groupName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(formatTimeRange(conflict.block.startTime, conflict.block.endTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Resolution buttons
                        VStack(spacing: 8) {
                            // Option 1: Hide from timeline
                            Button {
                                var updated = conflict.task
                                updated.scheduledDate = nil
                                updated.scheduledStartTime = nil
                                updated.scheduledEndTime = nil
                                taskManager.updateTask(updated)
                                showTaskConflictPanel = false
                            } label: {
                                HStack {
                                    Image(systemName: "eye.slash")
                                    Text("Remove from Timeline")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }

                            // Option 2: Reschedule task
                            Button {
                                selectedTask = conflict.task
                                showTaskConflictPanel = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showEditTask = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                    Text("Reschedule Task")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }

                            // Option 3: Move into group
                            Button {
                                var updated = conflict.task
                                updated.groupId = conflict.block.groupId
                                if !updated.scheduleIds.contains(conflict.block.scheduleId) {
                                    updated.scheduleIds.append(conflict.block.scheduleId)
                                }
                                updated.scheduledDate = nil
                                updated.scheduledStartTime = nil
                                updated.scheduledEndTime = nil
                                taskManager.updateTask(updated)
                                showTaskConflictPanel = false
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.3.group")
                                    Text("Move into \(conflict.block.groupName)")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(hex: conflict.block.groupColor).opacity(0.15))
                                .foregroundColor(Color(hex: conflict.block.groupColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Task Overlaps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTaskConflictPanel = false
                    }
                }
            }
        }
    }

    // MARK: - Block Detail Sheet

    private func blockDetailSheet(_ block: ScheduleBlock) -> some View {
        let tasks = taskManager.tasksForGroupAndSchedule(block.groupId, scheduleId: block.scheduleId)
        let currentGroup = groupManager.getGroupById(block.groupId)
        let sameGroupOtherSchedules = currentGroup?.recurrences.filter { $0.id != block.scheduleId } ?? []
        let otherGroups = groupManager.groups.filter { $0.isActive && $0.id != block.groupId }

        return NavigationView {
            List {
                // Block info
                Section {
                    HStack(spacing: 10) {
                        if let icon = block.groupIcon {
                            Text(icon)
                                .font(.title2)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.groupName)
                                .font(.headline)
                            Text("\(block.scheduleLabel) \u{2022} \(formatTimeRange(block.startTime, block.endTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Assigned tasks
                if tasks.isEmpty {
                    Section(header: Text("Assigned Tasks")) {
                        Text("No tasks assigned to this schedule")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section(header: Text("Assigned Tasks")) {
                        ForEach(tasks) { task in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                    Text(task.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .strikethrough(task.isCompleted)
                                    Spacer()
                                    Text("Priority \(task.priority.rawValue)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                // Move to another schedule/group
                                Menu {
                                    // Same group, different schedule
                                    if !sameGroupOtherSchedules.isEmpty {
                                        Section {
                                            ForEach(sameGroupOtherSchedules) { schedule in
                                                Button {
                                                    moveTask(task, toGroupId: block.groupId, scheduleId: schedule.id)
                                                } label: {
                                                    Text("\(schedule.label ?? "Schedule") (\(formatTimeRange(schedule.startTime, schedule.endTime)))")
                                                }
                                            }
                                        } header: {
                                            Text("\(block.groupIcon ?? "") \(block.groupName)")
                                        }
                                    }

                                    // Other groups
                                    ForEach(otherGroups) { group in
                                        if !group.recurrences.isEmpty {
                                            Section {
                                                ForEach(group.recurrences) { schedule in
                                                    Button {
                                                        moveTask(task, toGroupId: group.id, scheduleId: schedule.id)
                                                    } label: {
                                                        Text("\(schedule.label ?? "Schedule") (\(formatTimeRange(schedule.startTime, schedule.endTime)))")
                                                    }
                                                }
                                            } header: {
                                                Text("\(group.icon ?? "") \(group.name)")
                                            }
                                        }
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        unassignTask(task)
                                    } label: {
                                        Label("Remove from Group", systemImage: "xmark.circle")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.right.arrow.left")
                                            .font(.caption2)
                                        Text("Move to...")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showBlockDetail = false
                    }
                }
            }
        }
    }

    private func moveTask(_ task: Task, toGroupId: UUID, scheduleId: UUID) {
        var updated = task
        updated.groupId = toGroupId
        updated.scheduleIds = [scheduleId]
        updated.scheduledDate = nil
        updated.scheduledStartTime = nil
        updated.scheduledEndTime = nil
        taskManager.updateTask(updated)
    }

    private func unassignTask(_ task: Task) {
        var updated = task
        updated.groupId = nil
        updated.scheduleIds = []
        taskManager.updateTask(updated)
    }

    // MARK: - Helpers

    private func startOfWeek(_ date: Date) -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        return cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: date)) ?? cal.startOfDay(for: date)
    }

    private func dayShortName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayFullName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
