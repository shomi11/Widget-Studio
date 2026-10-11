import SwiftUI
import Combine
import HealthKit
import EventKit
import UserNotifications

/// The authorization status for an Apple ecosystem category.
public enum CategoryAuthorizationStatus: String, Sendable {
    case authorized = "Authorized"
    case denied = "Not Authorized"
    case notDetermined = "Not Determined"
    case notRequired = "Always Available"

    public var isUsable: Bool {
        self == .authorized || self == .notRequired
    }

    public var badgeColor: Color {
        switch self {
        case .authorized, .notRequired:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
}

/// Central manager orchestrating Apple framework permissions across the 6 categories:
/// Health (HealthKit), Clock (System), Reminders (EventKit), Calendar (EventKit), Notes (Storage/Notes), and Alarms (UserNotifications).
@MainActor
public final class CategoryPermissionManager: ObservableObject {
    public static let shared = CategoryPermissionManager()

    @Published public var healthStatus: CategoryAuthorizationStatus = .notDetermined
    @Published public var remindersStatus: CategoryAuthorizationStatus = .notDetermined
    @Published public var calendarStatus: CategoryAuthorizationStatus = .notDetermined
    @Published public var alarmsStatus: CategoryAuthorizationStatus = .notDetermined
    @Published public var notesStatus: CategoryAuthorizationStatus = .authorized
    @Published public var clockStatus: CategoryAuthorizationStatus = .notRequired

    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshStatuses()

        // Auto-refresh when returning from iOS Settings or other apps
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshStatuses()
                }
            }
            .store(in: &cancellables)
    }

    /// Queries current system authorization for all 6 categories
    public func refreshStatuses() {
        // 1. Health (Apple HealthKit)
        if !HKHealthStore.isHealthDataAvailable() {
            healthStatus = .denied
        } else if UserDefaults.standard.bool(forKey: "AppleHealth_Authorized") {
            healthStatus = .authorized
        } else if let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            let status = healthStore.authorizationStatus(for: waterType)
            if status == .sharingAuthorized {
                healthStatus = .authorized
            } else {
                healthStatus = .notDetermined
            }
        } else {
            healthStatus = .notDetermined
        }

        // 2. Clock (Foundation System Time)
        clockStatus = .notRequired

        // 3. Reminders (EventKit)
        let remStatus = EKEventStore.authorizationStatus(for: .reminder)
        switch remStatus {
        case .authorized, .fullAccess:
            remindersStatus = .authorized
            UserDefaults.standard.set(true, forKey: "AppleReminders_Authorized")
        case .denied, .restricted:
            remindersStatus = .denied
            UserDefaults.standard.set(false, forKey: "AppleReminders_Authorized")
        case .notDetermined, .writeOnly:
            if UserDefaults.standard.bool(forKey: "AppleReminders_Authorized") {
                remindersStatus = .authorized
            } else {
                remindersStatus = .notDetermined
            }
        @unknown default:
            remindersStatus = .notDetermined
        }

        // 4. Calendar (EventKit)
        let calStatus = EKEventStore.authorizationStatus(for: .event)
        switch calStatus {
        case .authorized, .fullAccess:
            calendarStatus = .authorized
            UserDefaults.standard.set(true, forKey: "AppleCalendar_Authorized")
        case .denied, .restricted:
            calendarStatus = .denied
            UserDefaults.standard.set(false, forKey: "AppleCalendar_Authorized")
        case .notDetermined, .writeOnly:
            if UserDefaults.standard.bool(forKey: "AppleCalendar_Authorized") {
                calendarStatus = .authorized
            } else {
                calendarStatus = .notDetermined
            }
        @unknown default:
            calendarStatus = .notDetermined
        }

        // 5. Notes (App Storage)
        notesStatus = .authorized

        // 6. Alarms (UserNotifications)
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self?.alarmsStatus = .authorized
                    UserDefaults.standard.set(true, forKey: "AppleAlarms_Authorized")
                case .denied:
                    self?.alarmsStatus = .denied
                    UserDefaults.standard.set(false, forKey: "AppleAlarms_Authorized")
                case .notDetermined:
                    if UserDefaults.standard.bool(forKey: "AppleAlarms_Authorized") {
                        self?.alarmsStatus = .authorized
                    } else {
                        self?.alarmsStatus = .notDetermined
                    }
                @unknown default:
                    self?.alarmsStatus = .notDetermined
                }
            }
        }

        objectWillChange.send()
    }

    /// Returns the current authorization status for a specific category
    public func status(for category: WidgetCategory) -> CategoryAuthorizationStatus {
        switch category {
        case .health: return healthStatus
        case .clock: return clockStatus
        case .reminders: return remindersStatus
        case .calendar: return calendarStatus
        case .notes: return notesStatus
        case .alarms: return alarmsStatus
        }
    }

    /// Checks whether permission is already granted for the category
    public func isAuthorized(for category: WidgetCategory) -> Bool {
        status(for: category).isUsable
    }

    /// Requests system permission for the selected category from Apple frameworks
    @discardableResult
    public func requestPermission(for category: WidgetCategory) async -> Bool {
        let result: Bool
        switch category {
        case .health:
            result = await requestHealthKitPermission()
        case .clock:
            clockStatus = .notRequired
            result = true
        case .reminders:
            result = await requestRemindersPermission()
        case .calendar:
            result = await requestCalendarPermission()
        case .notes:
            UserDefaults.standard.set(true, forKey: "AppleNotes_Permission_Granted")
            notesStatus = .authorized
            result = true
        case .alarms:
            result = await requestAlarmsPermission()
        }

        // Immediately trigger live refresh across services
        refreshStatuses()
        objectWillChange.send()
        return result
    }

    // MARK: - HealthKit Comprehensive Request
    private func requestHealthKitPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = .denied
            return false
        }

        var readTypes: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .heartRate,
            .restingHeartRate,
            .respiratoryRate,
            .oxygenSaturation,
            .dietaryWater,
            .dietaryCaffeine
        ]

        for id in quantityIds {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                readTypes.insert(type)
            }
        }

        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }

        var shareTypes: Set<HKSampleType> = []
        if let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            shareTypes.insert(waterType)
        }
        if let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) {
            shareTypes.insert(caffeineType)
        }

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            healthStatus = .authorized
            UserDefaults.standard.set(true, forKey: "AppleHealth_Authorized")
            Task {
                await HealthKitService.shared.fetchAllMetrics()
            }
            return true
        } catch {
            healthStatus = .denied
            return false
        }
    }

    // MARK: - Reminders (EventKit) Request
    private func requestRemindersPermission() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            remindersStatus = granted ? .authorized : .denied
            UserDefaults.standard.set(granted, forKey: "AppleReminders_Authorized")
            if granted {
                Task {
                    await RemindersService.shared.fetchSystemReminders()
                }
            }
            return granted
        } catch {
            remindersStatus = .denied
            return false
        }
    }

    // MARK: - Calendar (EventKit) Request
    private func requestCalendarPermission() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            calendarStatus = granted ? .authorized : .denied
            UserDefaults.standard.set(granted, forKey: "AppleCalendar_Authorized")
            if granted {
                Task {
                    await CalendarService.shared.fetchCalendarEvents()
                }
            }
            return granted
        } catch {
            calendarStatus = .denied
            return false
        }
    }

    // MARK: - Alarms (UserNotifications) Request
    private func requestAlarmsPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            alarmsStatus = granted ? .authorized : .denied
            UserDefaults.standard.set(granted, forKey: "AppleAlarms_Authorized")
            return granted
        } catch {
            alarmsStatus = .denied
            return false
        }
    }
}
