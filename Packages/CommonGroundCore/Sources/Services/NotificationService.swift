import Foundation
import UserNotifications
import SwiftData

@MainActor
public enum NotificationService {
    private static let center = UNUserNotificationCenter.current()

    private static var isScreenshotCapture: Bool {
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-ScreenshotTab=") }
            || UserDefaults.standard.bool(forKey: "debug.screenshotMode")
    }

    private static func addRequest(_ request: UNNotificationRequest) {
        guard !isScreenshotCapture else { return }
        center.add(request)
    }

    public static func requestAuthorization() async -> Bool {
        guard !isScreenshotCapture else { return false }
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    public static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    public static func scheduleExchangeReminder(for event: CalendarEvent, childName: String) {
        guard event.category == .exchange else { return }

        let content = UNMutableNotificationContent()
        content.title = "Custody Exchange Today"
        content.body = "\(childName): \(event.title) at \(event.startDate.formatted(date: .omitted, time: .shortened))"
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: event.startDate) ?? event.startDate
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "exchange-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        addRequest(request)
    }

    public static func scheduleMedicationReminder(for medication: Medication, childName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Give \(childName) \(medication.name) (\(medication.dosage))"
        content.sound = .default

        if medication.reminderTimes.isEmpty {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            addRequest(UNNotificationRequest(
                identifier: "medication-\(medication.id.uuidString)-default",
                content: content,
                trigger: trigger
            ))
            return
        }

        for (index, time) in medication.reminderTimes.enumerated() {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
            addRequest(UNNotificationRequest(
                identifier: "medication-\(medication.id.uuidString)-\(index)",
                content: content,
                trigger: trigger
            ))
        }
    }

    public static func syncAll(from context: ModelContext) {
        guard !isScreenshotCapture else { return }
        let events = (try? context.fetch(FetchDescriptor<CalendarEvent>())) ?? []
        let medications = (try? context.fetch(FetchDescriptor<Medication>())) ?? []

        for event in events where event.category == .exchange && event.startDate > Date() {
            scheduleExchangeReminder(for: event, childName: event.child?.firstName ?? "your child")
        }

        for medication in medications where medication.isActive {
            scheduleMedicationReminder(for: medication, childName: medication.child?.firstName ?? "your child")
        }
    }
}
