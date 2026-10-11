import Foundation
import AppIntents
import WidgetKit

// MARK: - 1. APP ENTITY FOR WIDGET SELECTION

/// App Entity representing a custom Liquid Glass widget in WidgetKit configuration pickers
public struct LiquidWidgetEntity: AppEntity, Identifiable, Sendable {
    public static var defaultQuery = LiquidWidgetQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Liquid Glass Widget"

    public var id: String

    @Property(title: "Widget Name")
    public var name: String

    @Property(title: "Category")
    public var categoryName: String

    @Property(title: "Size")
    public var sizeDescription: String

    @Property(title: "Glass Material")
    public var glassStyleName: String

    public init() {
        self.id = ""
        self.name = "Liquid Glass Widget"
        self.categoryName = "Health"
        self.sizeDescription = "Medium"
        self.glassStyleName = "Black Glass"
    }

    public init(id: String, name: String, categoryName: String, sizeDescription: String, glassStyleName: String) {
        self.id = id
        self.name = name
        self.categoryName = categoryName
        self.sizeDescription = sizeDescription
        self.glassStyleName = glassStyleName
    }

    public init(from config: WidgetConfig) {
        self.id = config.id.uuidString
        self.name = config.name
        self.categoryName = config.category.rawValue
        self.sizeDescription = config.size.rawValue
        self.glassStyleName = config.glassStyle.rawValue
    }

    public var displayRepresentation: DisplayRepresentation {
        let iconName: String
        switch categoryName {
        case "Health": iconName = "heart.fill"
        case "Clock": iconName = "clock.fill"
        case "Reminders": iconName = "checklist"
        case "Calendar": iconName = "calendar"
        case "Notes": iconName = "note.text"
        case "Alarms": iconName = "alarm.fill"
        default: iconName = "square.stack.3d.up.fill"
        }

        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(categoryName) • \(sizeDescription) • \(glassStyleName)",
            image: .init(systemName: iconName)
        )
    }
}

// MARK: - 2. ENTITY QUERY

/// Entity Query serving widgets configured by the user to WidgetKit
public struct LiquidWidgetQuery: EntityQuery, EntityStringQuery, Sendable {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [LiquidWidgetEntity] {
        let allConfigs = WidgetStore.loadWidgetsFromSharedStorage()
        let idSet = Set(identifiers)
        return allConfigs
            .filter { idSet.contains($0.id.uuidString) }
            .map { LiquidWidgetEntity(from: $0) }
    }

    public func suggestedEntities() async throws -> [LiquidWidgetEntity] {
        let allConfigs = WidgetStore.loadWidgetsFromSharedStorage()
        return allConfigs.map { LiquidWidgetEntity(from: $0) }
    }

    public func defaultResult() async -> LiquidWidgetEntity? {
        let allConfigs = WidgetStore.loadWidgetsFromSharedStorage()
        if let first = allConfigs.first {
            return LiquidWidgetEntity(from: first)
        }
        return nil
    }

    public func entities(matching string: String) async throws -> [LiquidWidgetEntity] {
        let allConfigs = WidgetStore.loadWidgetsFromSharedStorage()
        let lower = string.lowercased()
        return allConfigs
            .filter { $0.name.lowercased().contains(lower) || $0.category.rawValue.lowercased().contains(lower) }
            .map { LiquidWidgetEntity(from: $0) }
    }
}

// MARK: - 3. WIDGET CONFIGURATION INTENT

/// Apple's newest WidgetConfigurationIntent allowing users to select any created widget on Home Screen
public struct SelectLiquidWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Select Liquid Widget"
    public static var description = IntentDescription("Select which customized Liquid Glass widget to display on this Home Screen slot.")

    @Parameter(title: "Widget", description: "Choose a specific customized widget, or leave as Default to follow the active in-app choice.")
    public var selectedWidget: LiquidWidgetEntity?

    public init() {}

    public init(selectedWidget: LiquidWidgetEntity?) {
        self.selectedWidget = selectedWidget
    }
}

// MARK: - 4. INTERACTIVE APP INTENTS FOR HOME SCREEN CONTROLS

/// App Intent enabling zero-launch counter increment directly from the Home Screen widget
public struct IncrementWidgetCounterIntent: AppIntent {
    public static var title: LocalizedStringResource = "Increment Widget Counter"
    public static var description = IntentDescription("Increments an interactive counter on the Liquid Glass widget without launching the app.")

    @Parameter(title: "Widget ID")
    public var widgetId: String

    public init() {
        self.widgetId = ""
    }

    public init(widgetId: String) {
        self.widgetId = widgetId
    }

    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: widgetId) else {
            return .result()
        }

        await MainActor.run {
            WidgetStore.shared.incrementCounter(for: uuid)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent enabling zero-launch state toggling directly from the Home Screen widget
public struct ToggleWidgetStateIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Widget State"
    public static var description = IntentDescription("Toggles an interactive switch or habit completion on the widget surface.")

    @Parameter(title: "Widget ID")
    public var widgetId: String

    public init() {
        self.widgetId = ""
    }

    public init(widgetId: String) {
        self.widgetId = widgetId
    }

    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: widgetId) else {
            return .result()
        }

        await MainActor.run {
            WidgetStore.shared.toggleSwitch(for: uuid)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent allowing instantaneous cycling of the Liquid Glass material directly from the Home Screen
public struct CycleGlassMaterialIntent: AppIntent {
    public static var title: LocalizedStringResource = "Cycle Glass Material"
    public static var description = IntentDescription("Cycles between Ultra Clear, Tinted Glass, and Black Glass styles.")

    @Parameter(title: "Widget ID")
    public var widgetId: String

    public init() {
        self.widgetId = ""
    }

    public init(widgetId: String) {
        self.widgetId = widgetId
    }

    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: widgetId) else {
            return .result()
        }

        await MainActor.run {
            if let idx = WidgetStore.shared.widgets.firstIndex(where: { $0.id == uuid }) {
                var widget = WidgetStore.shared.widgets[idx]
                switch widget.glassStyle {
                case .ultraClear:
                    widget.glassStyle = .tintedGlass
                case .tintedGlass:
                    widget.glassStyle = .blackGlass
                case .blackGlass:
                    widget.glassStyle = .ultraClear
                }
                WidgetStore.shared.update(widget: widget)
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent for logging water intake directly from a widget button (+250mL)
public struct LogHydrationIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Hydration"
    public static var description = IntentDescription("Quickly logs 250mL of water intake directly from the Home Screen.")

    @Parameter(title: "Amount in mL", default: 250)
    public var amountMl: Double

    public init() {
        self.amountMl = 250
    }

    public init(amountMl: Double) {
        self.amountMl = amountMl
    }

    public func perform() async throws -> some IntentResult {
        await MainActor.run {
            HealthKitService.shared.logWaterIntake(amountMl: amountMl)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent for toggling reminder completion directly from a checklist widget
public struct ToggleReminderIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Reminder"
    public static var description = IntentDescription("Toggles a reminder item as completed directly from the Home Screen.")

    @Parameter(title: "Reminder ID")
    public var reminderId: String

    public init() {
        self.reminderId = ""
    }

    public init(reminderId: String) {
        self.reminderId = reminderId
    }

    public func perform() async throws -> some IntentResult {
        await MainActor.run {
            RemindersService.shared.toggleReminder(id: reminderId)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent for toggling alarm enabled state directly from an alarm widget
public struct ToggleAlarmIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Alarm"
    public static var description = IntentDescription("Toggles an alarm on or off directly from the Home Screen.")

    @Parameter(title: "Alarm ID")
    public var alarmId: String

    public init() {
        self.alarmId = ""
    }

    public init(alarmId: String) {
        self.alarmId = alarmId
    }

    public func perform() async throws -> some IntentResult {
        await MainActor.run {
            AlarmsService.shared.toggleAlarm(id: alarmId)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// App Intent for setting a widget as active on the Home Screen
public struct SetActiveHomeWidgetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Set Active Home Widget"
    public static var description = IntentDescription("Selects a custom widget to be the active widget shown on the Home Screen.")

    @Parameter(title: "Widget ID")
    public var widgetId: String

    public init() {
        self.widgetId = ""
    }

    public init(widgetId: String) {
        self.widgetId = widgetId
    }

    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: widgetId) else {
            return .result()
        }

        await MainActor.run {
            if let widget = WidgetStore.shared.widgets.first(where: { $0.id == uuid }) {
                WidgetStore.shared.setActiveHomeWidget(widget)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
