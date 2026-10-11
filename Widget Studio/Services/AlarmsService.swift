import Foundation
import Combine
import UserNotifications
import SwiftUI

/// Data model representing a smart alarm in Liquid Glass widgets
public struct GlassAlarmItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var hour: Int
    public var minute: Int
    public var isEnabled: Bool
    public var repeatDays: [String]

    public init(
        id: String = UUID().uuidString,
        label: String,
        hour: Int,
        minute: Int,
        isEnabled: Bool = true,
        repeatDays: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    ) {
        self.id = id
        self.label = label
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }

    public var timeFormatted: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }

    public var time24HourFormatted: String {
        return String(format: "%02d:%02d", hour, minute)
    }
}

/// Service managing smart wake-up alarms and notification scheduling
@MainActor
public final class AlarmsService: ObservableObject {
    public static let shared = AlarmsService()

    @Published public var alarms: [GlassAlarmItem] = []

    public init() {
        loadDefaultAlarms()
    }

    private func loadDefaultAlarms() {
        alarms = [
            GlassAlarmItem(label: "Morning Wakeup & Sunlight", hour: 7, minute: 0, isEnabled: true, repeatDays: ["Everyday"]),
            GlassAlarmItem(label: "Deep Work Sprint", hour: 9, minute: 30, isEnabled: true, repeatDays: ["Mon", "Wed", "Fri"]),
            GlassAlarmItem(label: "Afternoon Wind-down", hour: 17, minute: 45, isEnabled: false, repeatDays: ["Weekdays"]),
            GlassAlarmItem(label: "Bedtime Routine", hour: 22, minute: 15, isEnabled: true, repeatDays: ["Everyday"])
        ]
    }

    /// Returns the nearest enabled alarm
    public var nextAlarm: GlassAlarmItem? {
        alarms.first(where: { $0.isEnabled })
    }

    /// Formatted time string of next scheduled alarm
    public var nextAlarmFormatted: String {
        nextAlarm?.timeFormatted ?? "No Active Alarm"
    }

    /// Toggles alarm active state
    public func toggleAlarm(id: String) {
        if let idx = alarms.firstIndex(where: { $0.id == id }) {
            alarms[idx].isEnabled.toggle()
            if alarms[idx].isEnabled {
                scheduleNotification(for: alarms[idx])
            } else {
                cancelNotification(for: alarms[idx])
            }
        }
    }

    /// Schedules a system local notification using UserNotifications
    public func scheduleNotification(for alarm: GlassAlarmItem) {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Wake-up alarm for \(alarm.timeFormatted)"
        content.sound = .defaultRingtone

        var dateComponents = DateComponents()
        dateComponents.hour = alarm.hour
        dateComponents.minute = alarm.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "alarm_\(alarm.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels scheduled notification for an alarm
    public func cancelNotification(for alarm: GlassAlarmItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm_\(alarm.id)"])
    }
}
