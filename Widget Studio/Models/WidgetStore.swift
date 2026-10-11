import SwiftUI
import Combine
import WidgetKit

/// Persistent state of currently active widget slots across sizes and categories
public struct ActiveWidgetsState: Codable, Sendable {
    public var lastActivatedId: UUID?
    public var smallId: UUID?
    public var mediumId: UUID?
    public var largeId: UUID?
    public var extraLargeId: UUID?
    public var categoryIds: [String: UUID]

    public init(
        lastActivatedId: UUID? = nil,
        smallId: UUID? = nil,
        mediumId: UUID? = nil,
        largeId: UUID? = nil,
        extraLargeId: UUID? = nil,
        categoryIds: [String: UUID] = [:]
    ) {
        self.lastActivatedId = lastActivatedId
        self.smallId = smallId
        self.mediumId = mediumId
        self.largeId = largeId
        self.extraLargeId = extraLargeId
        self.categoryIds = categoryIds
    }
}

/// Central persistence store for configured widgets.
/// Saves and loads configurations from dual-layer App Group storage:
/// 1) App Group Shared File Container (FileManager.containerURL)
/// 2) App Group UserDefaults suite (group.com.milosmalovic.WidgetsStudioWidget)
/// 3) Local UserDefaults fallback
@MainActor
public final class WidgetStore: ObservableObject {
    public static let shared = WidgetStore()

    public static let appGroupSuiteName = "group.com.milosmalovic.WidgetsStudioWidget"
    private static let storageKey = "LiquidGlass_SavedWidgets_v4"
    private static let activeStateKey = "LiquidGlass_ActiveState_v4"
    private static let lastActivatedKey = "LiquidGlass_LastActivated_ID"
    private static let activeSmallKey = "LiquidGlass_ActiveSmall_ID"
    private static let activeMediumKey = "LiquidGlass_ActiveMedium_ID"
    private static let activeLargeKey = "LiquidGlass_ActiveLarge_ID"
    private static let activeExtraLargeKey = "LiquidGlass_ActiveExtraLarge_ID"

    nonisolated public static var sharedContainerDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupSuiteName)
    }

    nonisolated public static var sharedContainerFileURL: URL? {
        sharedContainerDirectory?.appendingPathComponent("widgets_store_v4.json")
    }

    nonisolated public static var sharedActiveInfoFileURL: URL? {
        sharedContainerDirectory?.appendingPathComponent("widgets_active_v4.json")
    }

    private let userDefaults: UserDefaults

    @Published public var widgets: [WidgetConfig] = []
    @Published public var activeSmallWidgetId: UUID?
    @Published public var activeMediumWidgetId: UUID?
    @Published public var activeLargeWidgetId: UUID?
    @Published public var activeExtraLargeWidgetId: UUID?
    @Published public var lastActivatedWidgetId: UUID?
    @Published public var categoryActiveIds: [String: UUID] = [:]

    public init(userDefaults: UserDefaults? = nil) {
        let defaults = userDefaults ?? (UserDefaults(suiteName: Self.appGroupSuiteName) ?? .standard)
        self.userDefaults = defaults
        loadWidgets()
        loadActiveSelections()
    }

    public func loadWidgets() {
        let loaded = Self.loadWidgetsFromSharedStorage()
        var updated = loaded
        // Ensure EVERY category has presets so no category is ever in an empty state
        for category in WidgetCategory.allCases {
            if !updated.contains(where: { $0.category == category }) {
                let missingPresets = Self.defaultPresets.filter { $0.category == category }
                updated.append(contentsOf: missingPresets)
            }
        }
        self.widgets = updated
        saveWidgets()
    }

    public func resetToDefaults() {
        self.widgets = Self.defaultPresets
        if let first = widgets.first {
            setActiveHomeWidget(first)
        } else {
            saveWidgets()
        }
    }

    public func loadActiveSelections() {
        let state = Self.loadActiveState()
        self.lastActivatedWidgetId = state.lastActivatedId
        self.activeSmallWidgetId = state.smallId ?? widgets.first(where: { $0.size == .small })?.id
        self.activeMediumWidgetId = state.mediumId ?? widgets.first(where: { $0.size == .medium })?.id
        self.activeLargeWidgetId = state.largeId ?? widgets.first(where: { $0.size == .large })?.id
        self.activeExtraLargeWidgetId = state.extraLargeId ?? widgets.first(where: { $0.size == .extraLarge })?.id
        self.categoryActiveIds = state.categoryIds
    }

    public func saveWidgets() {
        guard let encoded = try? JSONEncoder().encode(widgets) else { return }

        // 1. Write to App Group suite
        userDefaults.set(encoded, forKey: Self.storageKey)

        // 2. Write to Standard defaults fallback
        UserDefaults.standard.set(encoded, forKey: Self.storageKey)

        // 3. Write directly to shared container directory file
        if let fileURL = Self.sharedContainerFileURL {
            try? encoded.write(to: fileURL, options: .atomic)
        }

        userDefaults.synchronize()
        UserDefaults.standard.synchronize()

        // 4. Save active states concurrently
        saveActiveState()

        // 5. Notify WidgetKit to reload Home Screen and Lock Screen
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveActiveState() {
        let state = ActiveWidgetsState(
            lastActivatedId: lastActivatedWidgetId,
            smallId: activeSmallWidgetId,
            mediumId: activeMediumWidgetId,
            largeId: activeLargeWidgetId,
            extraLargeId: activeExtraLargeWidgetId,
            categoryIds: categoryActiveIds
        )

        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: Self.activeStateKey)
            UserDefaults.standard.set(encoded, forKey: Self.activeStateKey)
            if let fileURL = Self.sharedActiveInfoFileURL {
                try? encoded.write(to: fileURL, options: .atomic)
            }
        }

        if let last = lastActivatedWidgetId?.uuidString {
            userDefaults.set(last, forKey: Self.lastActivatedKey)
            UserDefaults.standard.set(last, forKey: Self.lastActivatedKey)
        }
        if let small = activeSmallWidgetId?.uuidString {
            userDefaults.set(small, forKey: Self.activeSmallKey)
            UserDefaults.standard.set(small, forKey: Self.activeSmallKey)
        }
        if let med = activeMediumWidgetId?.uuidString {
            userDefaults.set(med, forKey: Self.activeMediumKey)
            UserDefaults.standard.set(med, forKey: Self.activeMediumKey)
        }
        if let lrg = activeLargeWidgetId?.uuidString {
            userDefaults.set(lrg, forKey: Self.activeLargeKey)
            UserDefaults.standard.set(lrg, forKey: Self.activeLargeKey)
        }
        if let xl = activeExtraLargeWidgetId?.uuidString {
            userDefaults.set(xl, forKey: Self.activeExtraLargeKey)
            UserDefaults.standard.set(xl, forKey: Self.activeExtraLargeKey)
        }

        userDefaults.synchronize()
        UserDefaults.standard.synchronize()
    }

    /// Set a widget as active for its specific size slot and category on the Home Screen.
    /// Keeps size slots completely isolated so a calendar or health widget never overwrites
    /// a reminder widget in another size or slot!
    public func setActiveHomeWidget(_ widget: WidgetConfig) {
        lastActivatedWidgetId = widget.id
        switch widget.size {
        case .small:
            activeSmallWidgetId = widget.id
        case .medium:
            activeMediumWidgetId = widget.id
        case .large:
            activeLargeWidgetId = widget.id
        case .extraLarge:
            activeExtraLargeWidgetId = widget.id
        }
        categoryActiveIds[widget.category.rawValue] = widget.id

        saveWidgets()
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func isActiveHomeWidget(_ widget: WidgetConfig) -> Bool {
        switch widget.size {
        case .small:
            return activeSmallWidgetId == widget.id
        case .medium:
            return activeMediumWidgetId == widget.id
        case .large:
            return activeLargeWidgetId == widget.id
        case .extraLarge:
            return activeExtraLargeWidgetId == widget.id
        }
    }

    public func activeWidget(for size: WidgetSize) -> WidgetConfig {
        let targetId: UUID?
        switch size {
        case .small: targetId = activeSmallWidgetId
        case .medium: targetId = activeMediumWidgetId
        case .large: targetId = activeLargeWidgetId
        case .extraLarge: targetId = activeExtraLargeWidgetId
        }

        if let id = targetId, let match = widgets.first(where: { $0.id == id }) {
            return match
        }
        return widgets.first(where: { $0.size == size }) ?? Self.defaultPresets.first(where: { $0.size == size }) ?? Self.defaultPresets[0]
    }

    public func widgets(for category: WidgetCategory) -> [WidgetConfig] {
        widgets.filter { $0.category == category }
    }

    public func add(widget: WidgetConfig) {
        widgets.insert(widget, at: 0)
        saveWidgets()
    }

    public func update(widget: WidgetConfig) {
        if let idx = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[idx] = widget
            saveWidgets()
        }
    }

    public func duplicate(widget: WidgetConfig) {
        var copy = widget
        copy.id = UUID()
        copy.name = "\(widget.name) (Copy)"
        add(widget: copy)
    }

    public func delete(id: UUID) {
        widgets.removeAll { $0.id == id }
        if lastActivatedWidgetId == id { lastActivatedWidgetId = widgets.first?.id }
        if activeSmallWidgetId == id { activeSmallWidgetId = widgets.first(where: { $0.size == .small })?.id }
        if activeMediumWidgetId == id { activeMediumWidgetId = widgets.first(where: { $0.size == .medium })?.id }
        if activeLargeWidgetId == id { activeLargeWidgetId = widgets.first(where: { $0.size == .large })?.id }
        if activeExtraLargeWidgetId == id { activeExtraLargeWidgetId = widgets.first(where: { $0.size == .extraLarge })?.id }
        saveWidgets()
    }

    public func incrementCounter(for id: UUID) {
        if let idx = widgets.firstIndex(where: { $0.id == id }) {
            widgets[idx].counterValue += 1
            saveWidgets()
        }
    }

    public func toggleSwitch(for id: UUID) {
        if let idx = widgets.firstIndex(where: { $0.id == id }) {
            widgets[idx].isToggled.toggle()
            saveWidgets()
        }
    }

    // MARK: - Nonisolated Static Access for Timeline Providers & App Entities

    nonisolated public static func loadWidgetsFromSharedStorage() -> [WidgetConfig] {
        // 1. Try reading directly from shared container file
        if let fileURL = sharedContainerFileURL,
           let fileData = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([WidgetConfig].self, from: fileData),
           !decoded.isEmpty {
            return decoded
        }

        // 2. Try App Group UserDefaults suite
        let defaults = UserDefaults(suiteName: appGroupSuiteName) ?? .standard
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WidgetConfig].self, from: data),
           !decoded.isEmpty {
            return decoded
        }

        // 3. Try standard defaults
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WidgetConfig].self, from: data),
           !decoded.isEmpty {
            return decoded
        }

        return defaultPresets
    }

    nonisolated public static func loadActiveState() -> ActiveWidgetsState {
        // 1. Shared container file
        if let fileURL = sharedActiveInfoFileURL,
           let fileData = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(ActiveWidgetsState.self, from: fileData) {
            return decoded
        }

        // 2. App Group UserDefaults
        let defaults = UserDefaults(suiteName: appGroupSuiteName) ?? .standard
        if let data = defaults.data(forKey: activeStateKey),
           let decoded = try? JSONDecoder().decode(ActiveWidgetsState.self, from: data) {
            return decoded
        }

        // 3. Fallback string keys
        let lastId = (defaults.string(forKey: lastActivatedKey) ?? UserDefaults.standard.string(forKey: lastActivatedKey)).flatMap(UUID.init(uuidString:))
        let smallId = (defaults.string(forKey: activeSmallKey) ?? UserDefaults.standard.string(forKey: activeSmallKey)).flatMap(UUID.init(uuidString:))
        let medId = (defaults.string(forKey: activeMediumKey) ?? UserDefaults.standard.string(forKey: activeMediumKey)).flatMap(UUID.init(uuidString:))
        let lrgId = (defaults.string(forKey: activeLargeKey) ?? UserDefaults.standard.string(forKey: activeLargeKey)).flatMap(UUID.init(uuidString:))
        let xlId = (defaults.string(forKey: activeExtraLargeKey) ?? UserDefaults.standard.string(forKey: activeExtraLargeKey)).flatMap(UUID.init(uuidString:))

        return ActiveWidgetsState(lastActivatedId: lastId, smallId: smallId, mediumId: medId, largeId: lrgId, extraLargeId: xlId)
    }

    nonisolated public static func loadWidget(id: UUID) -> WidgetConfig? {
        let list = loadWidgetsFromSharedStorage()
        return list.first(where: { $0.id == id })
    }

    nonisolated public static func loadActiveWidget(for family: WidgetFamily) -> WidgetConfig {
        let size: WidgetSize
        switch family {
        case .systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular:
            size = .small
        case .systemMedium:
            size = .medium
        case .systemLarge:
            size = .large
        case .systemExtraLarge:
            size = .extraLarge
        @unknown default:
            size = .medium
        }
        return loadActiveWidget(for: size)
    }

    nonisolated public static func loadActiveWidget(for size: WidgetSize) -> WidgetConfig {
        let all = loadWidgetsFromSharedStorage()
        let state = loadActiveState()

        // 1. Size-specific slot
        let targetId: UUID?
        switch size {
        case .small: targetId = state.smallId
        case .medium: targetId = state.mediumId
        case .large: targetId = state.largeId
        case .extraLarge: targetId = state.extraLargeId
        }

        if let targetId = targetId, let match = all.first(where: { $0.id == targetId && $0.size == size }) {
            return match
        }

        // 2. Fallback to last activated IF it matches the requested size
        if let lastId = state.lastActivatedId, let match = all.first(where: { $0.id == lastId && $0.size == size }) {
            return match
        }

        return all.first(where: { $0.size == size }) ?? defaultPresets.first(where: { $0.size == size }) ?? defaultPresets[0]
    }

    nonisolated public static func loadActiveWidget(for category: WidgetCategory) -> WidgetConfig {
        let all = loadWidgetsFromSharedStorage()
        let state = loadActiveState()

        if let catId = state.categoryIds[category.rawValue],
           let match = all.first(where: { $0.id == catId && $0.category == category }) {
            return match
        }

        return all.first(where: { $0.category == category }) ?? defaultPresets.first(where: { $0.category == category }) ?? defaultPresets[0]
    }

    // MARK: - Curated Default Presets for 6 Apple Ecosystem Categories
    nonisolated public static var defaultPresets: [WidgetConfig] {
        [
            // 1. Health Category (Apple HealthKit)
            WidgetConfig(
                name: "Obsidian Health Rings",
                size: .medium,
                type: .stepActivity,
                glassStyle: .blackGlass,
                tintHex: "#FF375F",
                blurRadius: 28.0,
                specularIntensity: 0.95,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "HEALTHKIT VITALS",
                customSubtitle: "Goal: 10,000 steps",
                counterValue: 8420,
                isToggled: true
            ),
            WidgetConfig(
                name: "Deep Sleep Sentinel",
                size: .medium,
                type: .healthSleep,
                glassStyle: .tintedGlass,
                tintHex: "#5E5CE6",
                blurRadius: 24.0,
                specularIntensity: 0.90,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "SLEEP & RECOVERY",
                customSubtitle: "Target: 8.0 hrs",
                counterValue: 89,
                isToggled: true
            ),
            WidgetConfig(
                name: "SpO2 Vitals Cockpit",
                size: .small,
                type: .healthBloodOxygen,
                glassStyle: .ultraClear,
                tintHex: "#32ADE6",
                blurRadius: 22.0,
                specularIntensity: 0.88,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "BLOOD OXYGEN",
                customSubtitle: "SpO2 Saturation",
                counterValue: 98,
                isToggled: true
            ),
            WidgetConfig(
                name: "Hydration Flow",
                size: .medium,
                type: .healthHydration,
                glassStyle: .tintedGlass,
                tintHex: "#00C7BE",
                blurRadius: 24.0,
                specularIntensity: 0.90,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "HYDRATION GOAL",
                customSubtitle: "2,500 mL / Day",
                counterValue: 1850,
                isToggled: true
            ),
            WidgetConfig(
                name: "Pure Pulse Vitals",
                size: .small,
                type: .healthHeartRate,
                glassStyle: .ultraClear,
                tintHex: "#FF375F",
                blurRadius: 18.0,
                specularIntensity: 0.85,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "PULSE VITALS",
                customSubtitle: "Resting: 68 BPM",
                counterValue: 72,
                isToggled: true
            ),
            WidgetConfig(
                name: "Telemetry Health Matrix",
                size: .large,
                type: .healthVitalsHub,
                glassStyle: .blackGlass,
                tintHex: "#FF375F",
                blurRadius: 30.0,
                specularIntensity: 0.96,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "TELEMETRY VITALS",
                customSubtitle: "Apple HealthKit live bio-sensors",
                counterValue: 8420,
                isToggled: true
            ),

            // 2. Clock Category (System Time)
            WidgetConfig(
                name: "Atomic Chrono Sentinel",
                size: .medium,
                type: .digitalClock,
                glassStyle: .ultraClear,
                tintHex: "#0A84FF",
                blurRadius: 20.0,
                specularIntensity: 0.92,
                showEdgeShine: true,
                fontFamily: .sfMono,
                customTitle: "LOCAL • TIME",
                customSubtitle: "Live atomic sync",
                counterValue: 0,
                isToggled: true
            ),
            WidgetConfig(
                name: "World Clock Matrix",
                size: .large,
                type: .clockWorld,
                glassStyle: .tintedGlass,
                tintHex: "#0A84FF",
                blurRadius: 24.0,
                specularIntensity: 0.88,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "GLOBAL TIMEZONES",
                customSubtitle: "TYO • LON • NYC • SFO",
                counterValue: 4,
                isToggled: true
            ),
            WidgetConfig(
                name: "Liquid Analog Dial",
                size: .small,
                type: .clockAnalog,
                glassStyle: .ultraClear,
                tintHex: "#0A84FF",
                blurRadius: 22.0,
                specularIntensity: 0.85,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "ANALOG DIAL",
                customSubtitle: "Precision sweep",
                counterValue: 0,
                isToggled: true
            ),

            // 3. Reminders Category (Apple Reminders)
            WidgetConfig(
                name: "Priority Reminders",
                size: .medium,
                type: .remindersList,
                glassStyle: .tintedGlass,
                tintHex: "#FF9F0A",
                blurRadius: 22.0,
                specularIntensity: 0.85,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "APPLE REMINDERS",
                customSubtitle: "Due today: 3 tasks",
                counterValue: 3,
                isToggled: false,
                backgroundMode: .solidColor,
                solidColorHex: "#1C1C1E"
            ),
            WidgetConfig(
                name: "Today's Checklist",
                size: .small,
                type: .remindersToday,
                glassStyle: .blackGlass,
                tintHex: "#FF9F0A",
                blurRadius: 24.0,
                specularIntensity: 0.88,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "TODAY'S TO-DOS",
                customSubtitle: "3 pending tasks",
                counterValue: 3,
                isToggled: true
            ),
            WidgetConfig(
                name: "Task Checklist Hero",
                size: .large,
                type: .remindersList,
                glassStyle: .blackGlass,
                tintHex: "#FF9F0A",
                blurRadius: 28.0,
                specularIntensity: 0.92,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "APPLE REMINDERS",
                customSubtitle: "Priority to-do list & tasks",
                counterValue: 4,
                isToggled: false
            ),

            // 4. Calendar Category (Apple Calendar / EventKit)
            WidgetConfig(
                name: "Upcoming Agenda",
                size: .medium,
                type: .calendarUpcoming,
                glassStyle: .blackGlass,
                tintHex: "#FF3B30",
                blurRadius: 26.0,
                specularIntensity: 0.92,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "APPLE CALENDAR",
                customSubtitle: "Product Launch & Sync",
                counterValue: 4,
                isToggled: true
            ),
            WidgetConfig(
                name: "Month Glass Matrix",
                size: .large,
                type: .calendarMonth,
                glassStyle: .tintedGlass,
                tintHex: "#FF3B30",
                blurRadius: 28.0,
                specularIntensity: 0.90,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "MONTH SCHEDULE",
                customSubtitle: "Full calendar agenda",
                counterValue: 4,
                isToggled: true
            ),
            WidgetConfig(
                name: "Next Meeting Hero",
                size: .small,
                type: .calendarUpcoming,
                glassStyle: .ultraClear,
                tintHex: "#FF3B30",
                blurRadius: 22.0,
                specularIntensity: 0.88,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "NEXT EVENT",
                customSubtitle: "Studio Keynote",
                counterValue: 1,
                isToggled: true
            ),

            // 5. Notes Category (Apple Notes)
            WidgetConfig(
                name: "Glass Sticky Memo",
                size: .medium,
                type: .aestheticQuote,
                glassStyle: .ultraClear,
                tintHex: "#FFD60A",
                blurRadius: 20.0,
                specularIntensity: 0.85,
                showEdgeShine: true,
                fontFamily: .newYork,
                customTitle: "QUICK MEMO",
                customSubtitle: "Water shapes itself to the vessel, yet cuts through stone.",
                counterValue: 1,
                isToggled: true
            ),
            WidgetConfig(
                name: "Checklist Scratchpad",
                size: .small,
                type: .notesScratchpad,
                glassStyle: .tintedGlass,
                tintHex: "#FFD60A",
                blurRadius: 22.0,
                specularIntensity: 0.85,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "SCRATCHPAD",
                customSubtitle: "Quick bullets",
                counterValue: 3,
                isToggled: true
            ),

            // 6. Alarms Category (UserNotifications)
            WidgetConfig(
                name: "Sunrise Wake Alarm",
                size: .small,
                type: .alarmsNext,
                glassStyle: .tintedGlass,
                tintHex: "#BF5AF2",
                blurRadius: 24.0,
                specularIntensity: 0.90,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "WAKE-UP ALARM",
                customSubtitle: "7:00 AM Active",
                counterValue: 7,
                isToggled: true
            ),
            WidgetConfig(
                name: "Smart Alarm Hub",
                size: .medium,
                type: .alarmsHub,
                glassStyle: .blackGlass,
                tintHex: "#BF5AF2",
                blurRadius: 28.0,
                specularIntensity: 0.92,
                showEdgeShine: true,
                fontFamily: .sfMono,
                customTitle: "ALARM CONTROLLER",
                customSubtitle: "Next: 7:00 AM (Sunlight)",
                counterValue: 2,
                isToggled: true
            ),

            // 7. Extra Large Form Factor Presets (Whole Screen)
            WidgetConfig(
                name: "Panoramic Vitals Telemetry",
                size: .extraLarge,
                type: .healthVitalsHub,
                glassStyle: .blackGlass,
                tintHex: "#FF375F",
                blurRadius: 32.0,
                specularIntensity: 0.98,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "VITALS TELEMETRY CONSOLE",
                customSubtitle: "Live Apple HealthKit panoramic bio-sensors",
                counterValue: 8420,
                isToggled: true
            ),
            WidgetConfig(
                name: "Executive Month Matrix",
                size: .extraLarge,
                type: .calendarMonth,
                glassStyle: .tintedGlass,
                tintHex: "#FF3B30",
                blurRadius: 30.0,
                specularIntensity: 0.94,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "OCTOBER 2026 CALENDAR",
                customSubtitle: "Executive agenda & multi-day schedule",
                counterValue: 4,
                isToggled: true
            ),
            WidgetConfig(
                name: "World Matrix Console",
                size: .extraLarge,
                type: .clockWorld,
                glassStyle: .ultraClear,
                tintHex: "#0A84FF",
                blurRadius: 28.0,
                specularIntensity: 0.92,
                showEdgeShine: true,
                fontFamily: .sfMono,
                customTitle: "GLOBAL TIME TELEMETRY",
                customSubtitle: "Worldwide atomic chrono sync",
                counterValue: 4,
                isToggled: true
            ),
            WidgetConfig(
                name: "Master Action Board",
                size: .extraLarge,
                type: .remindersList,
                glassStyle: .tintedGlass,
                tintHex: "#FF9F0A",
                blurRadius: 26.0,
                specularIntensity: 0.90,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "TASK MANAGEMENT HUB",
                customSubtitle: "Synced with Apple Reminders",
                counterValue: 4,
                isToggled: false
            ),
            WidgetConfig(
                name: "Dual Canvas Scratchpad",
                size: .extraLarge,
                type: .notesScratchpad,
                glassStyle: .ultraClear,
                tintHex: "#FFD60A",
                blurRadius: 24.0,
                specularIntensity: 0.88,
                showEdgeShine: true,
                fontFamily: .sfRounded,
                customTitle: "NOTES & IDEAS CONSOLE",
                customSubtitle: "Pinned glass canvas and quick scratchpad",
                counterValue: 5,
                isToggled: true
            ),
            WidgetConfig(
                name: "Smart Alarm Command Hub",
                size: .extraLarge,
                type: .alarmsHub,
                glassStyle: .blackGlass,
                tintHex: "#BF5AF2",
                blurRadius: 30.0,
                specularIntensity: 0.95,
                showEdgeShine: true,
                fontFamily: .sfMono,
                customTitle: "ALARM COMMAND CENTER",
                customSubtitle: "Multi-schedule notification chimes",
                counterValue: 4,
                isToggled: true
            )
        ]
    }
}
