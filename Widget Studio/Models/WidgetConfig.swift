import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Predefined sizes matching standard WidgetKit form factors.
public enum WidgetSize: String, CaseIterable, Identifiable, Codable, Sendable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    public var id: String { rawValue }

    public var previewWidth: CGFloat {
        switch self {
        case .small: return 158
        case .medium: return 338
        case .large: return 338
        case .extraLarge: return 358
        }
    }

    public var previewHeight: CGFloat {
        switch self {
        case .small: return 158
        case .medium: return 158
        case .large: return 338
        case .extraLarge: return 520
        }
    }

    public var aspectRatio: CGFloat {
        switch self {
        case .small: return 1.0
        case .medium: return 338.0 / 158.0
        case .large: return 1.0
        case .extraLarge: return 358.0 / 520.0
        }
    }

    public var shortLabel: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    public var dimensionLabel: String {
        switch self {
        case .small: return "158×158"
        case .medium: return "338×158"
        case .large: return "338×338"
        case .extraLarge: return "Whole Screen"
        }
    }
}

/// The 6 core Apple ecosystem categories supported by Liquid Glass widgets
public enum WidgetCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case health = "Health"
    case clock = "Clock"
    case reminders = "Reminders"
    case calendar = "Calendar"
    case notes = "Notes"
    case alarms = "Alarms"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .clock: return "clock.fill"
        case .reminders: return "checklist"
        case .calendar: return "calendar"
        case .notes: return "note.text"
        case .alarms: return "alarm.fill"
        }
    }

    public var appleApp: String {
        switch self {
        case .health: return "Apple Health"
        case .clock: return "Apple Clock"
        case .reminders: return "Apple Reminders"
        case .calendar: return "Apple Calendar"
        case .notes: return "Apple Notes"
        case .alarms: return "Clock & Alarms"
        }
    }

    public var frameworkName: String {
        switch self {
        case .health: return "HealthKit"
        case .clock: return "Foundation & Time"
        case .reminders: return "EventKit"
        case .calendar: return "EventKit"
        case .notes: return "AppIntents & Notes"
        case .alarms: return "UserNotifications"
        }
    }

    public var defaultTintHex: String {
        switch self {
        case .health: return "#FF375F"   // Radiant Coral / Red
        case .clock: return "#0A84FF"    // Electric Blue
        case .reminders: return "#FF9F0A"// Sunset Orange
        case .calendar: return "#FF3B30" // Apple Calendar Crimson
        case .notes: return "#FFD60A"    // Golden Yellow
        case .alarms: return "#BF5AF2"   // Neon Purple
        }
    }

    public var permissionRationale: String {
        switch self {
        case .health:
            return "Read live step count, active calories, heart rate, resting vitals, blood oxygen (SpO2), respiratory rate, sleep analysis, sleep score, water intake, and caffeine directly from Apple HealthKit."
        case .clock:
            return "Synchronize atomic system time, live seconds, and world clock timezones."
        case .reminders:
            return "Access and complete scheduled checklists and tasks synced with Apple Reminders via EventKit."
        case .calendar:
            return "Read upcoming events, scheduled meetings, and day agendas directly from Apple Calendar via EventKit."
        case .notes:
            return "Pin fast glass memos, rich scratchpads, and launch directly into Apple Notes."
        case .alarms:
            return "Schedule wake-up alarms and smart alerts with custom chimes using Apple UserNotifications."
        }
    }

    public var widgetTypes: [WidgetType] {
        WidgetType.allCases.filter { $0.category == self }
    }
}

/// The functional data provider category for the widget
public enum WidgetType: String, CaseIterable, Identifiable, Codable, Sendable {
    // Health Category (Apple HealthKit)
    case stepActivity = "Activity Rings"
    case healthHeartRate = "Heart & Vitals"
    case healthSteps = "Daily Steps"
    case healthSleep = "Sleep & Sleep Score"
    case healthHydration = "Hydration & Caffeine"
    case healthBloodOxygen = "Blood Oxygen (SpO2)"
    case healthVitalsHub = "Vitals Telemetry Hub"

    // Clock Category (System Time & World Clock)
    case digitalClock = "Digital Chrono"
    case clockWorld = "World Clock Matrix"
    case clockAnalog = "Liquid Analog Dial"

    // Reminders Category (Apple Reminders / EventKit)
    case remindersList = "Priority Reminders"
    case remindersToday = "Today's Checklist"

    // Calendar Category (Apple Calendar / EventKit)
    case calendarUpcoming = "Upcoming Events"
    case calendarMonth = "Month Calendar"
    case calendarDayView = "Day Timeline"

    // Notes Category (Apple Notes / AppIntents)
    case aestheticQuote = "Glass Sticky Note"
    case notesScratchpad = "Checklist Scratchpad"

    // Alarms Category (UserNotifications)
    case alarmsNext = "Wake-Up Alarm"
    case alarmsHub = "Multi-Alarm Hub"

    // Legacy support
    case quickHub = "Interactive Hub"
    case calendarEvents = "Upcoming Agenda"
    case batteryVitals = "System Vitals"

    public var id: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw == "Today's Agenda" || raw == "Today's Checklist" {
            self = .remindersToday
        } else if let val = WidgetType(rawValue: raw) {
            self = val
        } else {
            self = .stepActivity
        }
    }

    public var category: WidgetCategory {
        switch self {
        case .stepActivity, .healthHeartRate, .healthSteps, .healthSleep, .healthHydration, .healthBloodOxygen, .healthVitalsHub:
            return .health
        case .digitalClock, .clockWorld, .clockAnalog:
            return .clock
        case .remindersList, .remindersToday:
            return .reminders
        case .calendarUpcoming, .calendarMonth, .calendarDayView, .calendarEvents:
            return .calendar
        case .aestheticQuote, .notesScratchpad:
            return .notes
        case .alarmsNext, .alarmsHub:
            return .alarms
        case .quickHub, .batteryVitals:
            return .health
        }
    }

    public var icon: String {
        switch self {
        // Health
        case .stepActivity: return "figure.run.square.stack"
        case .healthHeartRate: return "heart.fill"
        case .healthSteps: return "figure.walk"
        case .healthSleep: return "bed.double.fill"
        case .healthHydration: return "drop.fill"
        case .healthBloodOxygen: return "lungs.fill"
        case .healthVitalsHub: return "waveform.path.ecg.rectangle.fill"

        // Clock
        case .digitalClock: return "clock.fill"
        case .clockWorld: return "globe.americas.fill"
        case .clockAnalog: return "gauge.with.needle.fill"

        // Reminders
        case .remindersList: return "checklist"
        case .remindersToday: return "checklist.checked"

        // Calendar
        case .calendarUpcoming: return "calendar.badge.clock"
        case .calendarMonth: return "calendar"
        case .calendarDayView: return "list.bullet.below.rectangle"

        // Notes
        case .aestheticQuote: return "note.text"
        case .notesScratchpad: return "square.and.pencil"

        // Alarms
        case .alarmsNext: return "alarm.fill"
        case .alarmsHub: return "bell.badge.fill"

        // Legacy
        case .quickHub: return "switch.2"
        case .calendarEvents: return "calendar.badge.clock"
        case .batteryVitals: return "battery.100.bolt"
        }
    }

    public var subtitle: String {
        switch self {
        // Health
        case .stepActivity: return "Daily steps, active calories & distance via HealthKit"
        case .healthHeartRate: return "Real-time pulse, resting heart rate & vitals"
        case .healthSteps: return "Live step progress ring with daily goal"
        case .healthSleep: return "Sleep duration, stages & smart sleep score out of 100"
        case .healthHydration: return "Daily water intake (mL) & caffeine tracker"
        case .healthBloodOxygen: return "Blood oxygen (SpO2) saturation & respiratory rate"
        case .healthVitalsHub: return "Heart rate, SpO2, sleep, hydration & vitals dashboard"

        // Clock
        case .digitalClock: return "Real-time glass clock with seconds pulse"
        case .clockWorld: return "Multi-city global timezone tracker"
        case .clockAnalog: return "Fluid refractive analog clock dial"

        // Reminders
        case .remindersList: return "Interactive checklist synced with Apple Reminders"
        case .remindersToday: return "Today's pending tasks and completion progress"

        // Calendar
        case .calendarUpcoming: return "Next meetings, timeline & event countdown"
        case .calendarMonth: return "Monthly glass calendar matrix with date indicators"
        case .calendarDayView: return "Chronological hourly breakdown of today's schedule"

        // Notes
        case .aestheticQuote: return "Pinned glass memo with Apple Notes quick link"
        case .notesScratchpad: return "Scratchpad with instant bullet points"

        // Alarms
        case .alarmsNext: return "Next scheduled wake-up with toggle switch"
        case .alarmsHub: return "Smart alarms matrix and countdown timer"

        // Legacy
        case .quickHub: return "Interactive Home Screen toggles & counter"
        case .calendarEvents: return "Upcoming calendar events and timeline"
        case .batteryVitals: return "Device battery, storage and thermal status"
        }
    }
}

/// Custom typography styles compatible with iOS 27 design system
public enum WidgetFontFamily: String, CaseIterable, Identifiable, Codable, Sendable {
    case sfRounded = "SF Pro Rounded"
    case sfPro = "SF Pro"
    case sfMono = "SF Mono"
    case newYork = "New York Serif"

    public var id: String { rawValue }

    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .sfRounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .sfPro:
            return .system(size: size, weight: weight, design: .default)
        case .sfMono:
            return .system(size: size, weight: weight, design: .monospaced)
        case .newYork:
            return .system(size: size, weight: weight, design: .serif)
        }
    }
}

// MARK: - Customizable Background Modes & Models

/// Background rendering style for the widget
public enum WidgetBackgroundMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case liquidGlass = "Liquid Glass"
    case solidColor = "Solid Color"
    case linearGradient = "Linear Gradient"
    case radialGradient = "Radial Gradient"
    case meshGradient = "Mesh Gradient"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .liquidGlass: return "sparkles"
        case .solidColor: return "circle.fill"
        case .linearGradient: return "slider.horizontal.below.rectangle"
        case .radialGradient: return "smallcircle.filled.circle"
        case .meshGradient: return "circle.hexagongrid.fill"
        }
    }
}

/// Linear gradient direction
public enum WidgetGradientDirection: String, CaseIterable, Identifiable, Codable, Sendable {
    case topToBottom = "Top to Bottom"
    case diagonal = "Diagonal"
    case leadingToTrailing = "Left to Right"
    case bottomLeadingToTopTrailing = "Angle Up"

    public var id: String { rawValue }

    public var startPoint: UnitPoint {
        switch self {
        case .topToBottom: return .top
        case .diagonal: return .topLeading
        case .leadingToTrailing: return .leading
        case .bottomLeadingToTopTrailing: return .bottomLeading
        }
    }

    public var endPoint: UnitPoint {
        switch self {
        case .topToBottom: return .bottom
        case .diagonal: return .bottomTrailing
        case .leadingToTrailing: return .trailing
        case .bottomLeadingToTopTrailing: return .topTrailing
        }
    }
}

/// Curated gradient preset
public struct WidgetGradientPreset: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let startHex: String
    public let endHex: String

    public static let all: [WidgetGradientPreset] = [
        WidgetGradientPreset(id: "sunset", name: "Sunset Horizon", startHex: "#FF512F", endHex: "#DD2476"),
        WidgetGradientPreset(id: "aurora", name: "Aurora Neon", startHex: "#00C9FF", endHex: "#92FE9D"),
        WidgetGradientPreset(id: "violet", name: "Cosmic Violet", startHex: "#8A2387", endHex: "#E94057"),
        WidgetGradientPreset(id: "midnight", name: "Midnight Cyber", startHex: "#0F2027", endHex: "#2C5364"),
        WidgetGradientPreset(id: "oceanic", name: "Ocean Abyss", startHex: "#1A2980", endHex: "#26D0CE"),
        WidgetGradientPreset(id: "solar", name: "Solar Glow", startHex: "#F37335", endHex: "#FDC830"),
        WidgetGradientPreset(id: "emerald", name: "Emerald Dream", startHex: "#11998E", endHex: "#38EF7D"),
        WidgetGradientPreset(id: "blossom", name: "Neon Blossom", startHex: "#FF0844", endHex: "#FFB199"),
        WidgetGradientPreset(id: "titanium", name: "Dark Titanium", startHex: "#232526", endHex: "#414345"),
        WidgetGradientPreset(id: "royal", name: "Royal Indigo", startHex: "#4A00E0", endHex: "#8E2DE2")
    ]
}

/// Curated mesh gradient presets
public enum WidgetMeshPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case cyberpunk = "Cyberpunk"
    case sunset = "Sunset Mirage"
    case aurora = "Nordic Aurora"
    case prism = "Liquid Prism"
    case obsidian = "Obsidian Smoke"
    case titanium = "Desert Titanium"
    case custom = "Custom Mesh"

    public var id: String { rawValue }

    public var defaultColorsHex: [String] {
        switch self {
        case .cyberpunk:
            return [
                "#FF007F", "#7928CA", "#0070F3",
                "#00DFD8", "#7928CA", "#FF007F",
                "#0070F3", "#00DFD8", "#1A1A2E"
            ]
        case .sunset:
            return [
                "#FF4E50", "#F9D423", "#FF6B6B",
                "#7928CA", "#FF8E53", "#FE6B8B",
                "#2B0938", "#C33764", "#1D2671"
            ]
        case .aurora:
            return [
                "#0575E6", "#00F260", "#0575E6",
                "#00F260", "#11998E", "#38EF7D",
                "#0F2027", "#203A43", "#2C5364"
            ]
        case .prism:
            return [
                "#FF375F", "#FF9F0A", "#FFD60A",
                "#30D158", "#64D2FF", "#0A84FF",
                "#BF5AF2", "#5E5CE6", "#FF375F"
            ]
        case .obsidian:
            return [
                "#0D0D11", "#1E1E28", "#121217",
                "#2C2C3E", "#15151E", "#32324A",
                "#0A0A0E", "#181822", "#0F0F14"
            ]
        case .titanium:
            return [
                "#3A3935", "#6B655B", "#998E7D",
                "#4E4A43", "#8C8275", "#B8AA96",
                "#282725", "#544F47", "#736A5E"
            ]
        case .custom:
            return [
                "#FF375F", "#BF5AF2", "#0A84FF",
                "#FF9F0A", "#30D158", "#64D2FF",
                "#1C1C1E", "#2C2C2E", "#0B0C10"
            ]
        }
    }
}

/// Complete configuration for a customized Liquid Glass widget
public struct WidgetConfig: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var size: WidgetSize
    public var type: WidgetType
    public var glassStyle: GlassMaterialStyle
    public var tintHex: String
    public var blurRadius: CGFloat
    public var specularIntensity: CGFloat
    public var showEdgeShine: Bool
    public var fontFamily: WidgetFontFamily
    public var customTitle: String
    public var customSubtitle: String
    public var counterValue: Int
    public var isToggled: Bool

    // Customizable Background Options
    public var backgroundMode: WidgetBackgroundMode
    public var solidColorHex: String
    public var gradientStartHex: String
    public var gradientEndHex: String
    public var gradientDirection: WidgetGradientDirection
    public var meshPreset: WidgetMeshPreset
    public var meshColorsHex: [String]
    public var glassOverlayEnabled: Bool
    public var backgroundOpacity: Double

    public var category: WidgetCategory {
        type.category
    }

    public init(
        id: UUID = UUID(),
        name: String = "My Glass Widget",
        size: WidgetSize = .medium,
        type: WidgetType = .stepActivity,
        glassStyle: GlassMaterialStyle = .ultraClear,
        tintHex: String = "#FF375F",
        blurRadius: CGFloat = 20.0,
        specularIntensity: CGFloat = 0.85,
        showEdgeShine: Bool = true,
        fontFamily: WidgetFontFamily = .sfRounded,
        customTitle: String = "",
        customSubtitle: String = "",
        counterValue: Int = 0,
        isToggled: Bool = true,
        backgroundMode: WidgetBackgroundMode = .liquidGlass,
        solidColorHex: String = "#1C1C1E",
        gradientStartHex: String = "#FF512F",
        gradientEndHex: String = "#DD2476",
        gradientDirection: WidgetGradientDirection = .diagonal,
        meshPreset: WidgetMeshPreset = .cyberpunk,
        meshColorsHex: [String] = WidgetMeshPreset.cyberpunk.defaultColorsHex,
        glassOverlayEnabled: Bool = true,
        backgroundOpacity: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.type = type
        self.glassStyle = glassStyle
        self.tintHex = tintHex
        self.blurRadius = blurRadius
        self.specularIntensity = specularIntensity
        self.showEdgeShine = showEdgeShine
        self.fontFamily = fontFamily
        self.customTitle = customTitle
        self.customSubtitle = customSubtitle
        self.counterValue = counterValue
        self.isToggled = isToggled
        self.backgroundMode = backgroundMode
        self.solidColorHex = solidColorHex
        self.gradientStartHex = gradientStartHex
        self.gradientEndHex = gradientEndHex
        self.gradientDirection = gradientDirection
        self.meshPreset = meshPreset
        self.meshColorsHex = meshColorsHex
        self.glassOverlayEnabled = glassOverlayEnabled
        self.backgroundOpacity = backgroundOpacity
    }

    public var tintColor: Color {
        Color(hex: tintHex)
    }

    // MARK: - Codable Backward Compatibility
    enum CodingKeys: String, CodingKey {
        case id, name, size, type, glassStyle, tintHex, blurRadius
        case specularIntensity, showEdgeShine, fontFamily, customTitle
        case customSubtitle, counterValue, isToggled
        case backgroundMode, solidColorHex, gradientStartHex, gradientEndHex
        case gradientDirection, meshPreset, meshColorsHex, glassOverlayEnabled
        case backgroundOpacity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "My Glass Widget"
        size = try container.decodeIfPresent(WidgetSize.self, forKey: .size) ?? .medium
        type = try container.decodeIfPresent(WidgetType.self, forKey: .type) ?? .stepActivity
        glassStyle = try container.decodeIfPresent(GlassMaterialStyle.self, forKey: .glassStyle) ?? .ultraClear
        tintHex = try container.decodeIfPresent(String.self, forKey: .tintHex) ?? "#FF375F"
        blurRadius = try container.decodeIfPresent(CGFloat.self, forKey: .blurRadius) ?? 20.0
        specularIntensity = try container.decodeIfPresent(CGFloat.self, forKey: .specularIntensity) ?? 0.85
        showEdgeShine = try container.decodeIfPresent(Bool.self, forKey: .showEdgeShine) ?? true
        fontFamily = try container.decodeIfPresent(WidgetFontFamily.self, forKey: .fontFamily) ?? .sfRounded
        customTitle = try container.decodeIfPresent(String.self, forKey: .customTitle) ?? ""
        customSubtitle = try container.decodeIfPresent(String.self, forKey: .customSubtitle) ?? ""
        counterValue = try container.decodeIfPresent(Int.self, forKey: .counterValue) ?? 0
        isToggled = try container.decodeIfPresent(Bool.self, forKey: .isToggled) ?? true
        backgroundMode = try container.decodeIfPresent(WidgetBackgroundMode.self, forKey: .backgroundMode) ?? .liquidGlass
        solidColorHex = try container.decodeIfPresent(String.self, forKey: .solidColorHex) ?? "#1C1C1E"
        gradientStartHex = try container.decodeIfPresent(String.self, forKey: .gradientStartHex) ?? "#FF512F"
        gradientEndHex = try container.decodeIfPresent(String.self, forKey: .gradientEndHex) ?? "#DD2476"
        gradientDirection = try container.decodeIfPresent(WidgetGradientDirection.self, forKey: .gradientDirection) ?? .diagonal
        meshPreset = try container.decodeIfPresent(WidgetMeshPreset.self, forKey: .meshPreset) ?? .cyberpunk
        meshColorsHex = try container.decodeIfPresent([String].self, forKey: .meshColorsHex) ?? WidgetMeshPreset.cyberpunk.defaultColorsHex
        glassOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .glassOverlayEnabled) ?? true
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? 1.0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        try container.encode(type, forKey: .type)
        try container.encode(glassStyle, forKey: .glassStyle)
        try container.encode(tintHex, forKey: .tintHex)
        try container.encode(blurRadius, forKey: .blurRadius)
        try container.encode(specularIntensity, forKey: .specularIntensity)
        try container.encode(showEdgeShine, forKey: .showEdgeShine)
        try container.encode(fontFamily, forKey: .fontFamily)
        try container.encode(customTitle, forKey: .customTitle)
        try container.encode(customSubtitle, forKey: .customSubtitle)
        try container.encode(counterValue, forKey: .counterValue)
        try container.encode(isToggled, forKey: .isToggled)
        try container.encode(backgroundMode, forKey: .backgroundMode)
        try container.encode(solidColorHex, forKey: .solidColorHex)
        try container.encode(gradientStartHex, forKey: .gradientStartHex)
        try container.encode(gradientEndHex, forKey: .gradientEndHex)
        try container.encode(gradientDirection, forKey: .gradientDirection)
        try container.encode(meshPreset, forKey: .meshPreset)
        try container.encode(meshColorsHex, forKey: .meshColorsHex)
        try container.encode(glassOverlayEnabled, forKey: .glassOverlayEnabled)
        try container.encode(backgroundOpacity, forKey: .backgroundOpacity)
    }
}

// MARK: - Hex Color Extension Helper
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 10, 132, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public func toHex() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(
                format: "#%02lX%02lX%02lX",
                lroundf(Float(r * 255)),
                lroundf(Float(g * 255)),
                lroundf(Float(b * 255))
            )
        }
        #endif
        return "#0A84FF"
    }
}
