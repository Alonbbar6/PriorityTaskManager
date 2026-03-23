import Foundation
import SwiftUI

// MARK: - Day of Week

enum DayOfWeek: String, CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    var singleLetter: String {
        switch self {
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        case .sunday: return "S"
        }
    }

    /// Map Calendar weekday (1=Sunday) to DayOfWeek
    static func from(calendarWeekday: Int) -> DayOfWeek {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }

    static let weekdays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekend: [DayOfWeek] = [.saturday, .sunday]
    static let ordered: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
}

// MARK: - Recurrence Pattern

struct RecurrencePattern: Identifiable, Codable {
    let id: UUID
    var label: String?
    var daysOfWeek: [DayOfWeek]
    var startTime: String          // "HH:mm"
    var endTime: String            // "HH:mm"
    var startDate: Date
    var endDate: Date?             // nil = indefinite

    init(
        id: UUID = UUID(),
        label: String? = nil,
        daysOfWeek: [DayOfWeek] = [],
        startTime: String = "09:00",
        endTime: String = "17:00",
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = id
        self.label = label
        self.daysOfWeek = daysOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Subtask Template

struct SubtaskTemplate: Identifiable, Codable {
    let id: UUID
    var title: String
    var order: Int

    init(id: UUID = UUID(), title: String, order: Int = 0) {
        self.id = id
        self.title = title
        self.order = order
    }
}

// MARK: - Task Group

struct TaskGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var color: String              // hex color e.g. "#EF4444"
    var icon: String?              // emoji
    var priority: Priority
    var isUrgent: Bool
    var isImportant: Bool
    var recurrences: [RecurrencePattern]
    var subtaskTemplates: [SubtaskTemplate]
    var createdDate: Date
    var isActive: Bool
    var showInSchedule: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        color: String = "#3B82F6",
        icon: String? = nil,
        priority: Priority = .c,
        isUrgent: Bool = false,
        isImportant: Bool = false,
        recurrences: [RecurrencePattern] = [],
        subtaskTemplates: [SubtaskTemplate] = [],
        createdDate: Date = Date(),
        isActive: Bool = true,
        showInSchedule: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.icon = icon
        self.priority = priority
        self.isUrgent = isUrgent
        self.isImportant = isImportant
        self.recurrences = recurrences
        self.subtaskTemplates = subtaskTemplates
        self.createdDate = createdDate
        self.isActive = isActive
        self.showInSchedule = showInSchedule
    }
}

// MARK: - Group Colors

let groupColors: [String] = [
    "#EF4444", // Red
    "#F59E0B", // Amber
    "#10B981", // Green
    "#3B82F6", // Blue
    "#8B5CF6", // Purple
    "#EC4899", // Pink
    "#06B6D4", // Cyan
    "#F97316", // Orange
]

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Recurrence Helpers

func dateMatchesPattern(_ date: Date, _ pattern: RecurrencePattern) -> Bool {
    let calendar = Calendar.current
    let dateStr = dateToString(date)
    let startDateStr = dateToString(pattern.startDate)

    if dateStr < startDateStr { return false }

    if let endDate = pattern.endDate {
        let endDateStr = dateToString(endDate)
        if dateStr > endDateStr { return false }
    }

    let weekday = calendar.component(.weekday, from: date)
    let dayOfWeek = DayOfWeek.from(calendarWeekday: weekday)
    return pattern.daysOfWeek.contains(dayOfWeek)
}

func dateToString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func formatTimeRange(_ startTime: String, _ endTime: String) -> String {
    return "\(formatTime(startTime)) - \(formatTime(endTime))"
}

func formatTime(_ time: String) -> String {
    let parts = time.split(separator: ":").map { Int($0) ?? 0 }
    guard parts.count >= 2 else { return time }
    let hours = parts[0]
    let minutes = parts[1]
    let period = hours >= 12 ? "PM" : "AM"
    let displayHours = hours % 12 == 0 ? 12 : hours % 12
    return "\(displayHours):\(String(format: "%02d", minutes)) \(period)"
}

func formatDaysOfWeek(_ days: [DayOfWeek]) -> String {
    if days.isEmpty { return "" }

    let weekdays = DayOfWeek.weekdays
    let weekend = DayOfWeek.weekend

    if days.count == 5 && weekdays.allSatisfy({ days.contains($0) }) {
        return "Mon-Fri"
    }
    if days.count == 2 && weekend.allSatisfy({ days.contains($0) }) {
        return "Sat-Sun"
    }
    if days.count == 7 {
        return "Every Day"
    }

    let sorted = days.sorted { (DayOfWeek.ordered.firstIndex(of: $0) ?? 0) < (DayOfWeek.ordered.firstIndex(of: $1) ?? 0) }
    return sorted.map { $0.shortName }.joined(separator: ", ")
}

func timeToMinutes(_ time: String) -> Int {
    let parts = time.split(separator: ":").map { Int($0) ?? 0 }
    guard parts.count >= 2 else { return 0 }
    return parts[0] * 60 + parts[1]
}
