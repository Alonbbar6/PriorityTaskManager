import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationWindow = 7 // days to schedule ahead

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Foreground Delivery

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Reschedule All Notifications

    func rescheduleAll(
        groups: [TaskGroup],
        tasks: [Task],
        dismissedEntries: [DismissedEntry],
        effectiveTimeOverridesForDate: @escaping (Date) -> [UUID: (startTime: String, endTime: String)]
    ) {
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()
        var requests: [UNNotificationRequest] = []

        for dayOffset in 0..<notificationWindow {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }
            let dateStr = dateToString(date)
            let dismissedForDate = Set(dismissedEntries.filter { $0.date == dateStr }.map { $0.scheduleId })
            let overrides = effectiveTimeOverridesForDate(date)

            // Schedule notifications for groups
            for group in groups {
                guard group.isActive, group.showInSchedule else { continue }

                for recurrence in group.recurrences {
                    if dismissedForDate.contains(recurrence.id) { continue }
                    if !dateMatchesPattern(date, recurrence) { continue }

                    let effectiveStartTime = overrides[recurrence.id]?.startTime ?? recurrence.startTime
                    let timeParts = effectiveStartTime.split(separator: ":").map { Int($0) ?? 0 }
                    guard timeParts.count >= 2 else { continue }

                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = timeParts[0]
                    dateComponents.minute = timeParts[1]

                    // Skip if this time is already in the past
                    if let fireDate = calendar.date(from: dateComponents), fireDate <= now {
                        continue
                    }

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                    let content = UNMutableNotificationContent()
                    content.title = group.name
                    content.body = "\(recurrence.label ?? "Schedule") starting now"
                    content.sound = .default

                    let identifier = "\(group.id)-\(recurrence.id)-\(dateStr)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    requests.append(request)

                    if requests.count >= 64 { break }
                }
                if requests.count >= 64 { break }
            }
            
            // Schedule notifications for individual tasks
            for task in tasks {
                guard !task.isCompleted,
                      let scheduledDate = task.scheduledDate,
                      calendar.isDate(scheduledDate, inSameDayAs: date),
                      let startTime = task.scheduledStartTime else {
                    continue
                }
                
                let timeParts = startTime.split(separator: ":").map { Int($0) ?? 0 }
                guard timeParts.count >= 2 else { continue }
                
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = timeParts[0]
                dateComponents.minute = timeParts[1]
                
                // Skip if this time is already in the past
                if let fireDate = calendar.date(from: dateComponents), fireDate <= now {
                    continue
                }
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let content = UNMutableNotificationContent()
                content.title = task.title
                content.body = "Scheduled task starting now"
                content.sound = .default
                
                let identifier = "task-\(task.id)-\(dateStr)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                requests.append(request)
                
                if requests.count >= 64 { break }
            }
            
            if requests.count >= 64 { break }
        }

        for request in requests {
            center.add(request)
        }
    }
}
