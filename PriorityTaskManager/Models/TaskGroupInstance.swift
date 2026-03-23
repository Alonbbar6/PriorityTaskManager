import Foundation

// MARK: - Subtask Instance

struct SubtaskInstance: Identifiable, Codable {
    let id: UUID
    var templateId: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int

    init(id: UUID = UUID(), templateId: UUID, title: String, isCompleted: Bool = false, completedAt: Date? = nil, order: Int = 0) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.order = order
    }

    static func from(template: SubtaskTemplate) -> SubtaskInstance {
        SubtaskInstance(templateId: template.id, title: template.title, order: template.order)
    }
}

// MARK: - Task Group Instance

struct TaskGroupInstance: Identifiable, Codable {
    let id: UUID
    var groupId: UUID
    var recurrenceIndex: Int
    var date: String               // "yyyy-MM-dd"
    var startTime: String
    var endTime: String
    var subtasks: [SubtaskInstance]
    var isFullyCompleted: Bool
    var completionPercentage: Double
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        groupId: UUID,
        recurrenceIndex: Int,
        date: String,
        startTime: String,
        endTime: String,
        subtasks: [SubtaskInstance] = [],
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.recurrenceIndex = recurrenceIndex
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.subtasks = subtasks
        self.isFullyCompleted = subtasks.isEmpty ? false : subtasks.allSatisfy { $0.isCompleted }
        self.completionPercentage = subtasks.isEmpty ? 0 : Double(subtasks.filter { $0.isCompleted }.count) / Double(subtasks.count) * 100.0
        self.notes = notes
        self.createdAt = createdAt
    }

    mutating func recalculate() {
        let completed = subtasks.filter { $0.isCompleted }.count
        completionPercentage = subtasks.isEmpty ? 0 : Double(completed) / Double(subtasks.count) * 100.0
        isFullyCompleted = !subtasks.isEmpty && subtasks.allSatisfy { $0.isCompleted }
    }
}

// MARK: - Schedule Swap

struct SwapBlock: Codable {
    var scheduleId: UUID
    var groupId: UUID
    var groupName: String
    var originalStartTime: String
    var originalEndTime: String
}

struct ScheduleSwap: Identifiable, Codable {
    let id: UUID
    var date: String
    var blockA: SwapBlock
    var blockB: SwapBlock
    var createdAt: Date

    init(id: UUID = UUID(), date: String, blockA: SwapBlock, blockB: SwapBlock, createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.blockA = blockA
        self.blockB = blockB
        self.createdAt = createdAt
    }
}

// MARK: - Dismissed Entry

struct DismissedEntry: Codable, Equatable {
    var date: String
    var scheduleId: UUID
    var groupId: UUID
}

// MARK: - Schedule Block (computed at display time)

struct ScheduleBlock: Identifiable {
    var id: UUID { scheduleId }
    var groupId: UUID
    var groupName: String
    var groupColor: String
    var groupIcon: String?
    var scheduleId: UUID
    var scheduleLabel: String
    var startTime: String
    var endTime: String
}

// MARK: - Schedule Conflict

struct ScheduleConflict: Identifiable {
    let id: String
    var blockA: ScheduleBlock
    var blockB: ScheduleBlock
}

// MARK: - Task Schedule Conflict (task overlaps with group block)

struct TaskScheduleConflict: Identifiable {
    let id: String
    var task: Task
    var block: ScheduleBlock
}

// MARK: - Instance Generation Config

struct InstanceGenerationConfig {
    var lookAheadDays: Int = 30
    var cleanupDaysOld: Int = 30
}

let defaultInstanceConfig = InstanceGenerationConfig()
