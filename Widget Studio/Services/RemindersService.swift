import Foundation
import Combine
import EventKit
import SwiftUI

/// Item representation for a reminder displayed in Liquid Glass widgets
public struct GlassReminderItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var isCompleted: Bool
    public var priority: Int
    public var dueDateDescription: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        priority: Int = 0,
        dueDateDescription: String = "Today"
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDateDescription = dueDateDescription
    }
}

/// Service managing synchronization with Apple Reminders via EventKit
@MainActor
public final class RemindersService: ObservableObject {
    public static let shared = RemindersService()

    @Published public var reminders: [GlassReminderItem] = []
    @Published public var isLoading: Bool = false

    private let eventStore = EKEventStore()

    public init() {
        loadDefaultReminders()
        Task {
            await fetchSystemReminders()
        }
    }

    private func loadDefaultReminders() {
        reminders = [
            GlassReminderItem(title: "Buy groceries", isCompleted: false, priority: 1, dueDateDescription: "9:00 AM"),
            GlassReminderItem(title: "Pay electricity bill", isCompleted: false, priority: 2, dueDateDescription: "12:30 PM"),
            GlassReminderItem(title: "Call Mom", isCompleted: false, priority: 1, dueDateDescription: "3:00 PM"),
            GlassReminderItem(title: "Take out recycling", isCompleted: true, priority: 0, dueDateDescription: "9:00 PM")
        ]
    }

    /// Queries EventKit for active reminders
    public func fetchSystemReminders() async {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .authorized || status == .fullAccess else { return }

        isLoading = true
        defer { isLoading = false }

        let predicate = eventStore.predicateForReminders(in: nil)

        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
                Task { @MainActor in
                    if let ekReminders = ekReminders, !ekReminders.isEmpty {
                        let mapped: [GlassReminderItem] = ekReminders.prefix(8).map { ek in
                            let due = ek.dueDateComponents?.date.map {
                                DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short)
                            } ?? "Today"
                            return GlassReminderItem(
                                id: ek.calendarItemIdentifier,
                                title: ek.title ?? "Untitled Reminder",
                                isCompleted: ek.isCompleted,
                                priority: ek.priority,
                                dueDateDescription: due
                            )
                        }
                        self?.reminders = mapped
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// Toggles completion status of a reminder
    public func toggleReminder(id: String) {
        if let idx = reminders.firstIndex(where: { $0.id == id }) {
            reminders[idx].isCompleted.toggle()
        }
    }

    /// Adds a new quick reminder
    public func addReminder(title: String, dueDateDesc: String = "Today") {
        let newReminder = GlassReminderItem(title: title, isCompleted: false, priority: 1, dueDateDescription: dueDateDesc)
        reminders.insert(newReminder, at: 0)

        // Attempt write into Apple Reminders if authorized
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status == .authorized || status == .fullAccess {
            let ek = EKReminder(eventStore: eventStore)
            ek.title = title
            ek.calendar = eventStore.defaultCalendarForNewReminders()
            try? eventStore.save(ek, commit: true)
        }
    }
}
