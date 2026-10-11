import Foundation
import Combine
import EventKit
import SwiftUI

/// Item representation for an Apple Calendar event displayed in Liquid Glass widgets
public struct GlassCalendarEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var location: String
    public var isAllDay: Bool
    public var calendarColorHex: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        location: String = "",
        isAllDay: Bool = false,
        calendarColorHex: String = "#FF3B30"
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isAllDay = isAllDay
        self.calendarColorHex = calendarColorHex
    }

    public var timeDescription: String {
        if isAllDay { return "All-day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    public var startFormatted: String {
        if isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: startDate)
    }

    public var relativeDescription: String {
        let now = Date()
        if startDate > now {
            let mins = Int(startDate.timeIntervalSince(now) / 60)
            if mins < 60 {
                return "in \(mins)m"
            } else {
                let hrs = mins / 60
                return "in \(hrs)h \(mins % 60)m"
            }
        } else if endDate > now {
            return "Now"
        } else {
            return "Ended"
        }
    }
}

/// Service managing synchronization with Apple Calendar via EventKit
@MainActor
public final class CalendarService: ObservableObject {
    public static let shared = CalendarService()

    @Published public var events: [GlassCalendarEvent] = []
    @Published public var isLoading: Bool = false

    private let eventStore = EKEventStore()

    public init() {
        loadDefaultEvents()
        Task {
            await fetchCalendarEvents()
        }
    }

    public var nextUpcomingEvent: GlassCalendarEvent? {
        events.first { $0.endDate > Date() } ?? events.first
    }

    public var todayEvents: [GlassCalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDateInToday($0.startDate) || $0.isAllDay }
    }

    private func loadDefaultEvents() {
        let calendar = Calendar.current
        let now = Date()

        let start1 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(3600)
        let end1 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(7200)

        let start2 = calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now) ?? now.addingTimeInterval(14400)
        let end2 = calendar.date(bySettingHour: 14, minute: 15, second: 0, of: now) ?? now.addingTimeInterval(17100)

        let start3 = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(21600)
        let end3 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(25200)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let start4 = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: tomorrow) ?? tomorrow

        events = [
            GlassCalendarEvent(
                title: "Executive Product Keynote",
                startDate: start1,
                endDate: end1,
                location: "Apple Park • Steve Jobs Theater",
                isAllDay: false,
                calendarColorHex: "#FF3B30"
            ),
            GlassCalendarEvent(
                title: "Liquid Glass Design Sync",
                startDate: start2,
                endDate: end2,
                location: "Cupertino Lab 4",
                isAllDay: false,
                calendarColorHex: "#FF9500"
            ),
            GlassCalendarEvent(
                title: "Engineering Architecture Review",
                startDate: start3,
                endDate: end3,
                location: "Virtual Meeting Room",
                isAllDay: false,
                calendarColorHex: "#0A84FF"
            ),
            GlassCalendarEvent(
                title: "Product Release Kickoff",
                startDate: start4,
                endDate: start4.addingTimeInterval(3600),
                location: "Infinite Loop",
                isAllDay: false,
                calendarColorHex: "#BF5AF2"
            )
        ]
    }

    /// Queries EventKit for live calendar events
    public func fetchCalendarEvents() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized || status == .fullAccess else { return }

        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 7, to: startOfDay) ?? Date().addingTimeInterval(86400 * 7)

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        if !ekEvents.isEmpty {
            let mapped: [GlassCalendarEvent] = ekEvents.prefix(12).map { ek in
                let hex: String
                if let cgColor = ek.calendar.cgColor {
                    let comps = cgColor.components ?? [1, 0, 0, 1]
                    let r = Int(comps[0] * 255)
                    let g = Int(comps[min(1, comps.count - 1)] * 255)
                    let b = Int(comps[min(2, comps.count - 1)] * 255)
                    hex = String(format: "#%02X%02X%02X", r, g, b)
                } else {
                    hex = "#FF3B30"
                }

                return GlassCalendarEvent(
                    id: ek.eventIdentifier,
                    title: ek.title ?? "Untitled Event",
                    startDate: ek.startDate,
                    endDate: ek.endDate,
                    location: ek.location ?? "",
                    isAllDay: ek.isAllDay,
                    calendarColorHex: hex
                )
            }
            self.events = mapped.sorted { $0.startDate < $1.startDate }
        }
    }

    /// Adds a quick simulated / local calendar event
    public func addEvent(title: String, startDate: Date, endDate: Date, location: String = "") {
        let newEvent = GlassCalendarEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            calendarColorHex: "#FF3B30"
        )
        events.append(newEvent)
        events.sort { $0.startDate < $1.startDate }
    }
}
