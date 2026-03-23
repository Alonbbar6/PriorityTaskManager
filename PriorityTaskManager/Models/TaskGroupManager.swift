import Foundation
import SwiftUI

class TaskGroupManager: ObservableObject {
    @Published var groups: [TaskGroup] = []
    @Published var instances: [TaskGroupInstance] = []
    @Published var scheduleSwaps: [ScheduleSwap] = []
    @Published var dismissedEntries: [DismissedEntry] = []

    private let groupsKey = "SavedTaskGroups"
    private let instancesKey = "SavedGroupInstances"
    private let swapsKey = "SavedScheduleSwaps"
    private let dismissedKey = "SavedDismissedEntries"
    private let config = defaultInstanceConfig

    init() {
        loadGroups()
        loadInstances()
        loadSwaps()
        loadDismissed()
        generateAllInstances()
        cleanupOldInstances()
    }

    // MARK: - Persistence

    private func loadGroups() {
        print("📂 Loading task groups...")
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            print("ℹ️ No saved groups found")
            return
        }

        do {
            groups = try JSONDecoder().decode([TaskGroup].self, from: data)
            print("✅ Groups loaded: \(groups.count) groups")
        } catch {
            print("❌ ERROR loading groups: \(error)")
            groups = []
        }
    }

    private func saveGroups() {
        do {
            let encoded = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(encoded, forKey: groupsKey)
            UserDefaults.standard.synchronize()
            print("✅ Groups saved: \(groups.count) groups")
        } catch {
            print("❌ ERROR saving groups: \(error)")
        }
    }

    private func loadInstances() {
        print("📂 Loading group instances...")
        guard let data = UserDefaults.standard.data(forKey: instancesKey) else {
            print("ℹ️ No saved instances found")
            return
        }

        do {
            instances = try JSONDecoder().decode([TaskGroupInstance].self, from: data)
            print("✅ Instances loaded: \(instances.count) instances")
        } catch {
            print("❌ ERROR loading instances: \(error)")
            instances = []
        }
    }

    private func saveInstances() {
        do {
            let encoded = try JSONEncoder().encode(instances)
            UserDefaults.standard.set(encoded, forKey: instancesKey)
            UserDefaults.standard.synchronize()
            print("✅ Instances saved: \(instances.count) instances")
        } catch {
            print("❌ ERROR saving instances: \(error)")
        }
    }

    private func loadSwaps() {
        guard let data = UserDefaults.standard.data(forKey: swapsKey) else { return }

        do {
            scheduleSwaps = try JSONDecoder().decode([ScheduleSwap].self, from: data)
            print("✅ Swaps loaded: \(scheduleSwaps.count) swaps")
        } catch {
            print("❌ ERROR loading swaps: \(error)")
            scheduleSwaps = []
        }
    }

    private func saveSwaps() {
        do {
            let encoded = try JSONEncoder().encode(scheduleSwaps)
            UserDefaults.standard.set(encoded, forKey: swapsKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ ERROR saving swaps: \(error)")
        }
    }

    private func loadDismissed() {
        guard let data = UserDefaults.standard.data(forKey: dismissedKey) else { return }

        do {
            dismissedEntries = try JSONDecoder().decode([DismissedEntry].self, from: data)
            print("✅ Dismissed entries loaded: \(dismissedEntries.count)")
        } catch {
            print("❌ ERROR loading dismissed entries: \(error)")
            dismissedEntries = []
        }
    }

    private func saveDismissed() {
        do {
            let encoded = try JSONEncoder().encode(dismissedEntries)
            UserDefaults.standard.set(encoded, forKey: dismissedKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ ERROR saving dismissed entries: \(error)")
        }
    }

    // MARK: - Clear All Data

    func clearAll() {
        groups = []
        instances = []
        scheduleSwaps = []
        dismissedEntries = []
        saveGroups()
        saveInstances()
        saveSwaps()
        saveDismissed()
    }

    // MARK: - Group CRUD

    func addGroup(_ group: TaskGroup) {
        groups.append(group)
        saveGroups()
        let newInstances = generateInstancesForGroup(group)
        if !newInstances.isEmpty {
            instances.append(contentsOf: newInstances)
            saveInstances()
        }
        rescheduleNotifications()
    }

    func updateGroup(_ group: TaskGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
            regenerateInstancesForGroup(group)
            rescheduleNotifications()
        }
    }

    func deleteGroup(_ groupId: UUID) {
        groups.removeAll { $0.id == groupId }
        instances.removeAll { $0.groupId == groupId }
        saveGroups()
        saveInstances()
        rescheduleNotifications()
    }

    func toggleGroupActive(_ groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].isActive.toggle()
            saveGroups()
            rescheduleNotifications()
        }
    }

    func toggleShowInSchedule(_ groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].showInSchedule.toggle()
            saveGroups()
            rescheduleNotifications()
        }
    }

    func cloneGroup(_ groupId: UUID) -> TaskGroup? {
        guard let original = groups.first(where: { $0.id == groupId }) else { return nil }
        let clone = TaskGroup(
            name: "\(original.name) (Copy)",
            description: original.description,
            color: original.color,
            icon: original.icon,
            priority: original.priority,
            isUrgent: original.isUrgent,
            isImportant: original.isImportant,
            recurrences: [],
            subtaskTemplates: original.subtaskTemplates.map {
                SubtaskTemplate(title: $0.title, order: $0.order)
            }
        )
        groups.append(clone)
        saveGroups()
        return clone
    }

    func getGroupById(_ groupId: UUID) -> TaskGroup? {
        groups.first { $0.id == groupId }
    }

    func getActiveGroups() -> [TaskGroup] {
        groups.filter { $0.isActive }
    }

    // MARK: - Instance Management

    func getInstancesForDate(_ date: Date) -> [TaskGroupInstance] {
        let dateStr = dateToString(date)
        return instances.filter { $0.date == dateStr }
    }

    func getInstanceById(_ instanceId: UUID) -> TaskGroupInstance? {
        instances.first { $0.id == instanceId }
    }

    func toggleSubtaskCompletion(instanceId: UUID, subtaskId: UUID) {
        guard let index = instances.firstIndex(where: { $0.id == instanceId }),
              let subtaskIndex = instances[index].subtasks.firstIndex(where: { $0.id == subtaskId }) else { return }

        instances[index].subtasks[subtaskIndex].isCompleted.toggle()
        instances[index].subtasks[subtaskIndex].completedAt = instances[index].subtasks[subtaskIndex].isCompleted ? Date() : nil
        instances[index].recalculate()
        saveInstances()
    }

    // MARK: - Instance Generation

    private func generateAllInstances() {
        var newInstances: [TaskGroupInstance] = []
        for group in groups where group.isActive {
            let generated = generateInstancesForGroup(group)
            newInstances.append(contentsOf: generated)
        }
        if !newInstances.isEmpty {
            instances.append(contentsOf: newInstances)
            deduplicateInstances()
            saveInstances()
        }
    }

    private func generateInstancesForGroup(_ group: TaskGroup) -> [TaskGroupInstance] {
        guard group.isActive, !group.recurrences.isEmpty else { return [] }

        var newInstances: [TaskGroupInstance] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let existingKeys = Set(
            instances.filter { $0.groupId == group.id }
                .map { "\($0.date)-\($0.recurrenceIndex)" }
        )

        for recurrenceIndex in 0..<group.recurrences.count {
            for dayOffset in 0...config.lookAheadDays {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let dateStr = dateToString(date)
                let key = "\(dateStr)-\(recurrenceIndex)"

                if existingKeys.contains(key) { continue }
                if !dateMatchesPattern(date, group.recurrences[recurrenceIndex]) { continue }

                let recurrence = group.recurrences[recurrenceIndex]
                let subtasks = group.subtaskTemplates
                    .sorted { $0.order < $1.order }
                    .map { SubtaskInstance.from(template: $0) }

                let instance = TaskGroupInstance(
                    groupId: group.id,
                    recurrenceIndex: recurrenceIndex,
                    date: dateStr,
                    startTime: recurrence.startTime,
                    endTime: recurrence.endTime,
                    subtasks: subtasks
                )
                newInstances.append(instance)
            }
        }
        return newInstances
    }

    private func regenerateInstancesForGroup(_ group: TaskGroup) {
        let todayStr = dateToString(Date())

        // Remove future instances, keep past ones for subtask template update
        instances.removeAll { $0.groupId == group.id && $0.date > todayStr }

        // Update past instances with new template titles
        for i in instances.indices {
            guard instances[i].groupId == group.id else { continue }
            let existingMap = Dictionary(instances[i].subtasks.map { ($0.templateId, $0) }, uniquingKeysWith: { _, latest in latest })
            instances[i].subtasks = group.subtaskTemplates.sorted { $0.order < $1.order }.map { template in
                if let existing = existingMap[template.id] {
                    var updated = existing
                    updated.title = template.title
                    updated.order = template.order
                    return updated
                }
                return SubtaskInstance.from(template: template)
            }
            instances[i].recalculate()
        }

        // Generate new future instances
        let newInstances = generateInstancesForGroup(group)
        instances.append(contentsOf: newInstances)
        deduplicateInstances()
        saveInstances()
    }

    private func cleanupOldInstances() {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -config.cleanupDaysOld, to: Date()) else { return }
        let cutoffStr = dateToString(cutoff)
        let before = instances.count
        instances.removeAll { $0.date < cutoffStr }
        if instances.count != before { saveInstances() }
    }

    private func deduplicateInstances() {
        var seen = Set<String>()
        instances = instances.filter { inst in
            let key = "\(inst.groupId)-\(inst.date)-\(inst.recurrenceIndex)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Schedule Swaps

    func swapsForDate(_ date: Date) -> [ScheduleSwap] {
        let dateStr = dateToString(date)
        return scheduleSwaps.filter { $0.date == dateStr }
    }

    func createSwap(_ blockA: ScheduleBlock, _ blockB: ScheduleBlock, date: Date) {
        let dateStr = dateToString(date)
        let swap = ScheduleSwap(
            date: dateStr,
            blockA: SwapBlock(
                scheduleId: blockA.scheduleId,
                groupId: blockA.groupId,
                groupName: blockA.groupName,
                originalStartTime: blockA.startTime,
                originalEndTime: blockA.endTime
            ),
            blockB: SwapBlock(
                scheduleId: blockB.scheduleId,
                groupId: blockB.groupId,
                groupName: blockB.groupName,
                originalStartTime: blockB.startTime,
                originalEndTime: blockB.endTime
            )
        )
        scheduleSwaps.append(swap)
        saveSwaps()
        rescheduleNotifications()
    }

    func undoSwap(_ swapId: UUID) {
        scheduleSwaps.removeAll { $0.id == swapId }
        saveSwaps()
        rescheduleNotifications()
    }

    func resetDaySwaps(for date: Date) {
        let dateStr = dateToString(date)
        scheduleSwaps.removeAll { $0.date == dateStr }
        saveSwaps()
        rescheduleNotifications()
    }

    func alreadySwappedScheduleIds(for date: Date) -> Set<UUID> {
        var ids = Set<UUID>()
        for swap in swapsForDate(date) {
            ids.insert(swap.blockA.scheduleId)
            ids.insert(swap.blockB.scheduleId)
        }
        return ids
    }

    /// Build effective time override map from swaps for a date
    func effectiveTimeOverrides(for date: Date) -> [UUID: (startTime: String, endTime: String)] {
        var map: [UUID: (startTime: String, endTime: String)] = [:]
        for swap in swapsForDate(date) {
            map[swap.blockA.scheduleId] = (startTime: swap.blockB.originalStartTime, endTime: swap.blockB.originalEndTime)
            map[swap.blockB.scheduleId] = (startTime: swap.blockA.originalStartTime, endTime: swap.blockA.originalEndTime)
        }
        return map
    }

    // MARK: - Per-Day Dismissals

    func dismissedForDate(_ date: Date) -> Set<UUID> {
        let dateStr = dateToString(date)
        return Set(dismissedEntries.filter { $0.date == dateStr }.map { $0.scheduleId })
    }

    func dismissForDay(_ scheduleId: UUID, groupId: UUID, date: Date) {
        let dateStr = dateToString(date)
        if dismissedEntries.contains(where: { $0.date == dateStr && $0.scheduleId == scheduleId }) { return }
        dismissedEntries.append(DismissedEntry(date: dateStr, scheduleId: scheduleId, groupId: groupId))
        saveDismissed()
        rescheduleNotifications()
    }

    func restoreForDay(_ scheduleId: UUID, date: Date) {
        let dateStr = dateToString(date)
        dismissedEntries.removeAll { $0.date == dateStr && $0.scheduleId == scheduleId }
        saveDismissed()
        rescheduleNotifications()
    }

    func dismissedItemsForDate(_ date: Date) -> [(entry: DismissedEntry, groupName: String, groupColor: String, groupIcon: String?, scheduleLabel: String)] {
        let dateStr = dateToString(date)
        return dismissedEntries.filter { $0.date == dateStr }.compactMap { entry in
            guard let group = getGroupById(entry.groupId) else { return nil }
            let schedule = group.recurrences.first { $0.id == entry.scheduleId }
            return (entry: entry, groupName: group.name, groupColor: group.color, groupIcon: group.icon, scheduleLabel: schedule?.label ?? "Schedule")
        }
    }

    // MARK: - Notifications

    func rescheduleNotifications(tasks: [Task] = []) {
        NotificationManager.shared.rescheduleAll(
            groups: groups,
            tasks: tasks,
            dismissedEntries: dismissedEntries,
            effectiveTimeOverridesForDate: { [self] date in
                self.effectiveTimeOverrides(for: date)
            }
        )
    }

    // MARK: - Schedule Blocks & Conflicts

    func dayBlocks(for date: Date) -> [ScheduleBlock] {
        let dismissed = dismissedForDate(date)
        let overrides = effectiveTimeOverrides(for: date)
        var blocks: [ScheduleBlock] = []

        for group in groups {
            guard group.isActive, group.showInSchedule, !group.recurrences.isEmpty else { continue }
            for rec in group.recurrences {
                if dismissed.contains(rec.id) { continue }
                if !dateMatchesPattern(date, rec) { continue }
                let effective = overrides[rec.id]
                blocks.append(ScheduleBlock(
                    groupId: group.id,
                    groupName: group.name,
                    groupColor: group.color,
                    groupIcon: group.icon,
                    scheduleId: rec.id,
                    scheduleLabel: rec.label ?? "Schedule",
                    startTime: effective?.startTime ?? rec.startTime,
                    endTime: effective?.endTime ?? rec.endTime
                ))
            }
        }

        return blocks.sorted { timeToMinutes($0.startTime) < timeToMinutes($1.startTime) }
    }

    func conflicts(for date: Date) -> [ScheduleConflict] {
        let blocks = dayBlocks(for: date)
        var found: [ScheduleConflict] = []
        for i in 0..<blocks.count {
            for j in (i+1)..<blocks.count {
                let a = blocks[i]
                let b = blocks[j]
                if a.groupId == b.groupId { continue }
                let aStart = timeToMinutes(a.startTime)
                let aEnd = timeToMinutes(a.endTime)
                let bStart = timeToMinutes(b.startTime)
                let bEnd = timeToMinutes(b.endTime)
                if !(aEnd <= bStart || bEnd <= aStart) {
                    found.append(ScheduleConflict(id: "\(a.scheduleId)-\(b.scheduleId)", blockA: a, blockB: b))
                }
            }
        }
        return found
    }

    /// Detect conflicts between individually-scheduled tasks and group schedule blocks
    func taskConflicts(for date: Date, tasks: [Task]) -> [TaskScheduleConflict] {
        let blocks = dayBlocks(for: date)
        guard !blocks.isEmpty else { return [] }

        let calendar = Calendar.current
        var found: [TaskScheduleConflict] = []

        for task in tasks {
            guard !task.isCompleted,
                  let scheduledDate = task.scheduledDate,
                  calendar.isDate(scheduledDate, inSameDayAs: date),
                  let startTime = task.scheduledStartTime,
                  let endTime = task.scheduledEndTime else { continue }

            let tStart = timeToMinutes(startTime)
            let tEnd = timeToMinutes(endTime)

            for block in blocks {
                let bStart = timeToMinutes(block.startTime)
                let bEnd = timeToMinutes(block.endTime)

                if !(tEnd <= bStart || bEnd <= tStart) {
                    found.append(TaskScheduleConflict(
                        id: "\(task.id)-\(block.scheduleId)",
                        task: task,
                        block: block
                    ))
                }
            }
        }
        return found
    }

    /// Get instances for a date with showInSchedule filtering, dismissal filtering, and time overrides applied
    func visibleInstances(for date: Date) -> [TaskGroupInstance] {
        let dismissed = dismissedForDate(date)
        let overrides = effectiveTimeOverrides(for: date)

        return getInstancesForDate(date).compactMap { instance in
            guard let group = getGroupById(instance.groupId),
                  group.showInSchedule else { return nil }

            if instance.recurrenceIndex < group.recurrences.count {
                let scheduleId = group.recurrences[instance.recurrenceIndex].id
                if dismissed.contains(scheduleId) { return nil }

                if let override = overrides[scheduleId] {
                    var modified = instance
                    modified.startTime = override.startTime
                    modified.endTime = override.endTime
                    return modified
                }
            }
            return instance
        }
    }
}
