import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 1. TIMELINE ENTRY

/// Timeline Entry holding the timestamp and the resolved Widget configuration
public struct LiquidGlassWidgetEntry: TimelineEntry {
    public let date: Date
    public let config: WidgetConfig

    public init(date: Date = Date(), config: WidgetConfig) {
        self.date = date
        self.config = config
    }
}

// MARK: - 2. MODERN APP INTENT TIMELINE PROVIDER

/// Apple's newest AppIntentTimelineProvider utilizing SelectLiquidWidgetIntent
public struct LiquidGlassAppIntentTimelineProvider: AppIntentTimelineProvider {
    public typealias Entry = LiquidGlassWidgetEntry
    public typealias Intent = SelectLiquidWidgetIntent

    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let config = WidgetStore.loadActiveWidget(for: context.family)
        return LiquidGlassWidgetEntry(date: Date(), config: config)
    }

    public func snapshot(for configuration: SelectLiquidWidgetIntent, in context: Context) async -> LiquidGlassWidgetEntry {
        let config = resolveWidget(for: configuration, family: context.family)
        return LiquidGlassWidgetEntry(date: Date(), config: config)
    }

    public func timeline(for configuration: SelectLiquidWidgetIntent, in context: Context) async -> Timeline<LiquidGlassWidgetEntry> {
        let config = resolveWidget(for: configuration, family: context.family)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: config)

        // Refresh periodically every 15 minutes or immediately upon user AppIntent execution
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    public func recommendations() -> [AppIntentRecommendation<SelectLiquidWidgetIntent>] {
        let widgets = WidgetStore.loadWidgetsFromSharedStorage()
        return widgets.prefix(4).map { widget in
            let entity = LiquidWidgetEntity(from: widget)
            let intent = SelectLiquidWidgetIntent(selectedWidget: entity)
            return AppIntentRecommendation(intent: intent, description: widget.name)
        }
    }

    private func resolveWidget(for configuration: SelectLiquidWidgetIntent, family: WidgetFamily) -> WidgetConfig {
        if let selectedEntity = configuration.selectedWidget,
           !selectedEntity.id.isEmpty,
           let uuid = UUID(uuidString: selectedEntity.id),
           let matched = WidgetStore.loadWidget(id: uuid) {
            return matched
        }

        // Seamless fallback to user's in-app active selection for this family
        return WidgetStore.loadActiveWidget(for: family)
    }
}

// MARK: - 3. LOCK SCREEN & ACCESSORY COMPLICATIONS VIEW

/// Specialized rendering for iOS Lock Screen & Apple Watch complications
public struct LiquidAccessoryComplicationView: View {
    public let config: WidgetConfig
    public let family: WidgetFamily

    public init(config: WidgetConfig, family: WidgetFamily) {
        self.config = config
        self.family = family
    }

    public var body: some View {
        switch family {
        case .accessoryCircular:
            circularAccessory
        case .accessoryRectangular:
            rectangularAccessory
        case .accessoryInline:
            inlineAccessory
        default:
            EmptyView()
        }
    }

    // Circular Lock Screen Complication
    private var circularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()

            switch config.category {
            case .health:
                VStack(spacing: 1) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(config.counterValue)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            case .clock:
                VStack(spacing: 1) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text(Date.now, format: .dateTime.hour().minute())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
            case .reminders:
                VStack(spacing: 1) {
                    Image(systemName: "checklist")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(config.counterValue) left")
                        .font(.system(size: 9, weight: .bold))
                }
            case .calendar:
                VStack(spacing: 1) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .bold))
                    Text(Date.now.formatted(.dateTime.day()))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
            case .notes:
                VStack(spacing: 1) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                    Text("Memo")
                        .font(.system(size: 9, weight: .bold))
                }
            case .alarms:
                VStack(spacing: 1) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 12))
                    Text("7:00")
                        .font(.system(size: 10, weight: .heavy))
                }
            }
        }
    }

    // Rectangular Lock Screen Complication
    private var rectangularAccessory: some View {
        HStack(spacing: 8) {
            Image(systemName: config.category.icon)
                .font(.system(size: 20, weight: .bold))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text(config.customTitle.isEmpty ? config.name : config.customTitle)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)

                switch config.category {
                case .health:
                    Text("\(config.counterValue) steps • Goal: 10k")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                case .clock:
                    Text("Atomic Sync: Active")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                case .reminders:
                    Text("3 priority tasks due")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                case .calendar:
                    Text("10:00 AM • Design Review")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text("Apple Park • Steve Jobs Theater")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                case .notes:
                    Text(config.customSubtitle.isEmpty ? "Water shapes itself..." : config.customSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(2)
                case .alarms:
                    Text("7:00 AM • Active")
                        .font(.system(size: 14, weight: .bold))
                    Text("Tomorrow Morning")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // Inline Single-Line Lock Screen Complication
    private var inlineAccessory: some View {
        switch config.category {
        case .health:
            Label("\(config.counterValue) steps • 72 bpm", systemImage: "figure.walk")
        case .clock:
            Label(Date.now.formatted(date: .omitted, time: .shortened), systemImage: "clock")
        case .reminders:
            Label("Next: \(config.customTitle.isEmpty ? "Design specs" : config.customTitle)", systemImage: "checklist")
        case .calendar:
            Label("10:00 AM Product Keynote", systemImage: "calendar")
        case .notes:
            Label(config.customTitle.isEmpty ? "Pinned Note" : config.customTitle, systemImage: "note.text")
        case .alarms:
            Label("Alarm 7:00 AM", systemImage: "alarm")
        }
    }
}

// MARK: - 4. ROOT WIDGET ENTRY VIEW

/// Home Screen & Lock Screen container view applying newest iOS 27 WidgetKit modifiers
public struct LiquidWidgetsEntryView: View {
    public let entry: LiquidGlassWidgetEntry
    @Environment(\.widgetFamily) var family

    public init(entry: LiquidGlassWidgetEntry) {
        self.entry = entry
    }

    private var adaptedConfig: WidgetConfig {
        var c = entry.config
        switch family {
        case .systemSmall:
            c.size = .small
        case .systemMedium:
            c.size = .medium
        case .systemLarge:
            c.size = .large
        case .systemExtraLarge:
            c.size = .extraLarge
        default:
            c.size = .medium
        }
        return c
    }

    @ViewBuilder
    public var body: some View {
        if isAccessoryFamily(family) {
            LiquidAccessoryComplicationView(config: entry.config, family: family)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        } else {
            WidgetDisplayView(widget: adaptedConfig, isInteractivePreview: false)
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView(config: adaptedConfig, cornerRadius: 0, isInteractivePreview: false)
                }
        }
    }

    private func isAccessoryFamily(_ f: WidgetFamily) -> Bool {
        f == .accessoryCircular || f == .accessoryRectangular || f == .accessoryInline
    }
}

// MARK: - 5. CONFIGURABLE LIQUID GLASS WIDGET (FLAGSHIP)

/// Primary customizable Liquid Glass Widget driven by in-app selection or Home Screen long-press configuration
public struct ConfigurableLiquidGlassWidget: Widget {
    public static let kind: String = "ConfigurableLiquidGlassWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: SelectLiquidWidgetIntent.self,
            provider: LiquidGlassAppIntentTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Liquid Glass Widget")
        .description("Refractive dynamic glass widget showing your active selection from the app with zero-launch interactive controls.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - 6. DEDICATED HEALTHKIT TELEMETRY WIDGET

/// Dedicated Apple HealthKit vitals widget with live rings and metrics
public struct HealthVitalsLiquidWidget: Widget {
    public static let kind: String = "HealthVitalsLiquidWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: HealthTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Health & Vitals Hub")
        .description("Live HealthKit activity rings, heart rate, SpO2, sleep, and hydration telemetry.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

public struct HealthTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let fallback = WidgetStore.loadActiveWidget(for: .health)
        return LiquidGlassWidgetEntry(date: Date(), config: fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LiquidGlassWidgetEntry) -> Void) {
        let health = WidgetStore.loadActiveWidget(for: .health)
        completion(LiquidGlassWidgetEntry(date: Date(), config: health))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LiquidGlassWidgetEntry>) -> Void) {
        let health = WidgetStore.loadActiveWidget(for: .health)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: health)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - 7. DEDICATED ATOMIC CLOCK & WORLD CHRONO WIDGET

/// Dedicated atomic time, World Clock, and chronograph widget
public struct AtomicClockLiquidWidget: Widget {
    public static let kind: String = "AtomicClockLiquidWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: ClockTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Atomic Chrono & World Clock")
        .description("Synchronized atomic local time and multi-city world clock in refractive glass.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

public struct ClockTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let fallback = WidgetStore.loadActiveWidget(for: .clock)
        return LiquidGlassWidgetEntry(date: Date(), config: fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LiquidGlassWidgetEntry) -> Void) {
        let clock = WidgetStore.loadActiveWidget(for: .clock)
        completion(LiquidGlassWidgetEntry(date: Date(), config: clock))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LiquidGlassWidgetEntry>) -> Void) {
        let clock = WidgetStore.loadActiveWidget(for: .clock)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: clock)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - 8. DEDICATED INTERACTIVE REMINDERS WIDGET

/// Interactive Apple Reminders checklist widget executable directly from Home Screen
public struct InteractiveRemindersLiquidWidget: Widget {
    public static let kind: String = "InteractiveRemindersLiquidWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: RemindersTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Interactive Reminders")
        .description("Check off tasks and view to-do priorities with zero-launch interactive buttons.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

public struct RemindersTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let fallback = WidgetStore.loadActiveWidget(for: .reminders)
        return LiquidGlassWidgetEntry(date: Date(), config: fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LiquidGlassWidgetEntry) -> Void) {
        let rem = WidgetStore.loadActiveWidget(for: .reminders)
        completion(LiquidGlassWidgetEntry(date: Date(), config: rem))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LiquidGlassWidgetEntry>) -> Void) {
        let rem = WidgetStore.loadActiveWidget(for: .reminders)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: rem)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - 9. DEDICATED APPLE CALENDAR WIDGET

/// Dedicated Apple Calendar upcoming events and agenda widget
public struct CalendarEventsLiquidWidget: Widget {
    public static let kind: String = "CalendarEventsLiquidWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: CalendarTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Apple Calendar Agenda")
        .description("Track upcoming meetings, daily schedule, and month matrix in refractive glass.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

public struct CalendarTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let fallback = WidgetStore.loadActiveWidget(for: .calendar)
        return LiquidGlassWidgetEntry(date: Date(), config: fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LiquidGlassWidgetEntry) -> Void) {
        let cal = WidgetStore.loadActiveWidget(for: .calendar)
        completion(LiquidGlassWidgetEntry(date: Date(), config: cal))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LiquidGlassWidgetEntry>) -> Void) {
        let cal = WidgetStore.loadActiveWidget(for: .calendar)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: cal)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - 10. DEDICATED SMART ALARMS WIDGET

/// Smart Alarm Hub widget displaying next wake-up alarm with toggle
public struct AlarmsControlLiquidWidget: Widget {
    public static let kind: String = "AlarmsControlLiquidWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: AlarmsTimelineProvider()
        ) { entry in
            LiquidWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Smart Alarms Hub")
        .description("Track upcoming wake alarms and bedtime countdowns directly on the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

public struct AlarmsTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LiquidGlassWidgetEntry {
        let fallback = WidgetStore.loadActiveWidget(for: .alarms)
        return LiquidGlassWidgetEntry(date: Date(), config: fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LiquidGlassWidgetEntry) -> Void) {
        let alarm = WidgetStore.loadActiveWidget(for: .alarms)
        completion(LiquidGlassWidgetEntry(date: Date(), config: alarm))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LiquidGlassWidgetEntry>) -> Void) {
        let alarm = WidgetStore.loadActiveWidget(for: .alarms)
        let entry = LiquidGlassWidgetEntry(date: Date(), config: alarm)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}
