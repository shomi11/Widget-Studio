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

    /// Events that haven't ended yet, soonest first.
    public var upcomingEvents: [GlassCalendarEvent] {
        let now = Date()
        return events.filter { $0.endDate > now }
    }

    public var todayEvents: [GlassCalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDateInToday($0.startDate) || $0.isAllDay }
    }

    private func loadDefaultEvents() {
        let calendar = Calendar.current
        let now = Date()

        // Sample events are anchored to the current time so previews always have something coming up.
        let startOfHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let nextHour = startOfHour.addingTimeInterval(3600)

        let start1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(-7200)
        let end1 = start1.addingTimeInterval(1800)

        let start2 = nextHour
        let end2 = start2.addingTimeInterval(2700)

        let start3 = nextHour.addingTimeInterval(7200)
        let end3 = start3.addingTimeInterval(3600)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let start4 = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: tomorrow) ?? tomorrow

        events = [
            GlassCalendarEvent(
                title: "Team standup",
                startDate: start1,
                endDate: end1,
                location: "Room 2B",
                isAllDay: false,
                calendarColorHex: "#FF3B30"
            ),
            GlassCalendarEvent(
                title: "Lunch with Sam",
                startDate: start2,
                endDate: end2,
                location: "Corner Café",
                isAllDay: false,
                calendarColorHex: "#FF9500"
            ),
            GlassCalendarEvent(
                title: "Dentist",
                startDate: start3,
                endDate: end3,
                location: "",
                isAllDay: false,
                calendarColorHex: "#0A84FF"
            ),
            GlassCalendarEvent(
                title: "Yoga class",
                startDate: start4,
                endDate: start4.addingTimeInterval(3600),
                location: "",
                isAllDay: false,
                calendarColorHex: "#BF5AF2"
            )
        ].sorted { $0.startDate < $1.startDate }
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
