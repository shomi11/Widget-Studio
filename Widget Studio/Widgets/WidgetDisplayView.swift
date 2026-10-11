import SwiftUI
import AppIntents

/// Renders the complete Liquid Glass widget view for Small, Medium, and Large form factors
/// across the 6 categories: Health, Clock, Reminders, Calendar, Notes, and Alarms.
public struct WidgetDisplayView: View {
    public let widget: WidgetConfig
    public var isInteractivePreview: Bool = false
    public var onCounterTap: (() -> Void)? = nil
    public var onToggleTap: (() -> Void)? = nil

    @ObservedObject private var healthService = HealthKitService.shared
    @ObservedObject private var remindersService = RemindersService.shared
    @ObservedObject private var calendarService = CalendarService.shared
    @ObservedObject private var alarmsService = AlarmsService.shared
    @ObservedObject private var clockService = ClockService.shared
    @ObservedObject private var notesService = NotesService.shared

    public init(
        widget: WidgetConfig,
        isInteractivePreview: Bool = false,
        onCounterTap: (() -> Void)? = nil,
        onToggleTap: (() -> Void)? = nil
    ) {
        self.widget = widget
        self.isInteractivePreview = isInteractivePreview
        self.onCounterTap = onCounterTap
        self.onToggleTap = onToggleTap
    }

    public var body: some View {
        ZStack {
            widgetContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetSurface(config: widget, cornerRadius: cornerRadiusForSize)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Formatted values (locale-aware, consistent across every layout)

    private var stepsText: String { healthService.todaySteps.formatted() }
    private var stepGoalText: String { 10_000.formatted() }
    private var caloriesText: String { "\(healthService.activeCalories.formatted()) kcal" }
    private var heartRateText: String { "\(healthService.currentHeartRate.formatted()) bpm" }
    private var restingRateText: String { "\(healthService.restingHeartRate.formatted()) bpm" }
    private var oxygenText: String { (healthService.bloodOxygen / 100).formatted(.percent.precision(.fractionLength(1))) }
    private var oxygenValueText: String { healthService.bloodOxygen.formatted(.number.precision(.fractionLength(1))) }
    private var breathsText: String { "\(healthService.respiratoryRate.formatted(.number.precision(.fractionLength(0)))) breaths/min" }
    private var sleepValueText: String { healthService.sleepHours.formatted(.number.precision(.fractionLength(1))) }
    private var sleepText: String { "\(sleepValueText) h" }
    private var waterValueText: String { Int(healthService.waterIntakeMl).formatted() }
    private var waterText: String { "\(waterValueText) mL" }
    private var waterGoalText: String { "\(2_500.formatted()) mL" }
    private var caffeineText: String { "\(Int(healthService.caffeineMg).formatted()) mg" }

    private var sleepStagesText: String {
        let hours = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))
        return "Deep \(1.8.formatted(hours)) h · REM \(2.2.formatted(hours)) h · Core \(3.8.formatted(hours)) h"
    }

    private var cornerRadiusForSize: CGFloat {
        switch widget.size {
        case .small: return 24.0
        case .medium: return 26.0
        case .large: return 28.0
        case .extraLarge: return 30.0
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch widget.type {
        // Health Category (Apple HealthKit)
        case .stepActivity:
            healthActivityView
        case .healthHeartRate:
            healthHeartRateView
        case .healthSteps:
            healthStepsView
        case .healthSleep:
            healthSleepView
        case .healthHydration:
            healthHydrationView
        case .healthBloodOxygen:
            healthBloodOxygenView
        case .healthVitalsHub:
            healthVitalsHubView

        // Clock Category
        case .digitalClock:
            clockDigitalView
        case .clockWorld:
            clockWorldView
        case .clockAnalog:
            clockAnalogView

        // Reminders Category
        case .remindersList:
            remindersListView
        case .remindersToday:
            remindersTodayView

        // Calendar Category (Apple Calendar / EventKit)
        case .calendarUpcoming:
            calendarUpcomingView
        case .calendarMonth:
            calendarMonthView
        case .calendarDayView:
            calendarDayView

        // Notes Category
        case .aestheticQuote:
            notesQuickMemoView
        case .notesScratchpad:
            notesScratchpadView

        // Alarms Category
        case .alarmsNext:
            alarmsNextView
        case .alarmsHub:
            alarmsHubView

        // Legacy Types
        case .quickHub:
            legacyQuickHubView
        case .calendarEvents:
            calendarUpcomingView
        case .batteryVitals:
            legacyVitalsView
        }
    }

    // MARK: - 1. HEALTH CATEGORY VIEWS

    private var healthActivityView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Activity" : widget.customTitle, icon: "flame.fill", badge: "")

            Spacer(minLength: 0)

            if widget.size == .small {
                // Adaptive Small layout: 50pt ring + stacked stats with no overlapping
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(healthService.todaySteps) / 10000.0, 1.0))
                            .stroke(
                                LinearGradient(colors: [widget.tintColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: "figure.walk")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(widget.tintColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stepsText)
                            .font(widget.fontFamily.font(size: 20, weight: .black))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("Steps")
                            .font(widget.fontFamily.font(size: 10, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.72))

                        Text(caloriesText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                }
            } else if widget.size == .extraLarge {
                // Whole-Screen Health Command Center for Extra Large
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        // Concentric Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 9)
                                .frame(width: 84, height: 84)
                            Circle()
                                .trim(from: 0, to: min(CGFloat(healthService.todaySteps) / 10000.0, 1.0))
                                .stroke(
                                    LinearGradient(colors: [widget.tintColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                                )
                                .frame(width: 84, height: 84)
                                .rotationEffect(.degrees(-90))

                            Image(systemName: "figure.walk")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(widget.tintColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stepsText)
                                .font(widget.fontFamily.font(size: 32, weight: .black))
                                .foregroundStyle(Color.white)

                            Text("Steps today of \(stepGoalText)")
                                .font(widget.fontFamily.font(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.72))

                            HStack(spacing: 12) {
                                Label(caloriesText, systemImage: "flame.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.orange)
                                Label(heartRateText, systemImage: "heart.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.pink)
                            }
                        }

                        Spacer()
                    }

                    // 4-Card Vitals Grid filling the whole-screen canvas
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        vitalsHubCard(
                            title: "Blood oxygen",
                            value: oxygenText,
                            subtext: breathsText,
                            icon: "lungs.fill",
                            color: .cyan
                        )

                        vitalsHubCard(
                            title: "Sleep",
                            value: sleepText,
                            subtext: "Score \(healthService.sleepScore.formatted())",
                            icon: "bed.double.fill",
                            color: .purple
                        )

                        vitalsHubCard(
                            title: "Water",
                            value: waterText,
                            subtext: "Goal \(waterGoalText)",
                            icon: "drop.fill",
                            color: .teal
                        )

                        vitalsHubCard(
                            title: "Resting heart rate",
                            value: restingRateText,
                            subtext: "Normal",
                            icon: "waveform.path.ecg",
                            color: .pink
                        )
                    }

                    // Bottom Quick Action
                    HStack(spacing: 10) {
                        if isInteractivePreview {
                            Button {
                                healthService.logWaterIntake(amountMl: 250)
                            } label: {
                                Label("Add \(250.formatted()) mL", systemImage: "drop.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: LogHydrationIntent(amountMl: 250)) {
                                Label("Add \(250.formatted()) mL", systemImage: "drop.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        EmptyView()
                    }
                }
            } else {
                // Medium and Large layout
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 8)
                            .frame(width: 70, height: 70)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(healthService.todaySteps) / 10000.0, 1.0))
                            .stroke(
                                LinearGradient(colors: [widget.tintColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: "figure.walk")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(widget.tintColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stepsText)
                            .font(widget.fontFamily.font(size: 26, weight: .black))
                            .foregroundStyle(Color.white)

                        Text("Steps today")
                            .font(widget.fontFamily.font(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.72))

                        HStack(spacing: 8) {
                            Label(caloriesText, systemImage: "flame.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.orange)
                            Label(heartRateText, systemImage: "heart.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private var healthHeartRateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Heart rate" : widget.customTitle, icon: "heart.fill", badge: "")

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(healthService.currentHeartRate.formatted())
                    .font(widget.fontFamily.font(size: widget.size == .small ? 38 : 46, weight: .heavy))
                    .foregroundStyle(.primary)
                Text("bpm")
                    .font(widget.fontFamily.font(size: 14, weight: .bold))
                    .foregroundStyle(widget.tintColor)
            }

            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(widget.tintColor)
                Text("Resting \(restingRateText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
    }

    private var healthStepsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Steps" : widget.customTitle, icon: "figure.walk", badge: min(Double(healthService.todaySteps) / 10_000.0, 1.0).formatted(.percent.precision(.fractionLength(0))))

            Spacer()

            Text(stepsText)
                .font(widget.fontFamily.font(size: 36, weight: .black))
                .foregroundStyle(.primary)

            ProgressView(value: min(Double(healthService.todaySteps) / 10000.0, 1.0))
                .tint(widget.tintColor)

            Text("Goal \(stepGoalText) steps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(16)
    }

    private var healthSleepView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Sleep" : widget.customTitle,
                icon: "bed.double.fill",
                badge: ""
            )

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(sleepValueText)
                    .font(widget.fontFamily.font(size: widget.size == .small ? 34 : 44, weight: .heavy))
                    .foregroundStyle(.primary)
                Text("h")
                    .font(widget.fontFamily.font(size: 14, weight: .bold))
                    .foregroundStyle(widget.tintColor)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(healthService.sleepScore.formatted())
                        .font(widget.fontFamily.font(size: 18, weight: .heavy))
                        .foregroundStyle(widget.tintColor)
                    Text("Score")
                        .font(widget.fontFamily.font(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.purple)
                Text(sleepStagesText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
    }

    private var healthHydrationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Water" : widget.customTitle,
                icon: "drop.fill",
                badge: ""
            )

            Spacer()

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(waterValueText)
                            .font(widget.fontFamily.font(size: widget.size == .small ? 26 : 32, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text("mL")
                            .font(widget.fontFamily.font(size: 12, weight: .bold))
                            .foregroundStyle(widget.tintColor)
                    }

                    ProgressView(value: min(healthService.waterIntakeMl / 2500.0, 1.0))
                        .tint(widget.tintColor)

                    Text("Goal \(waterGoalText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if widget.size != .small {
                    Divider()
                        .frame(height: 38)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.brown)
                            Text(caffeineText)
                                .font(widget.fontFamily.font(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                        }

                        Text("Limit \(400.formatted()) mg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 8) {
                if isInteractivePreview {
                    Button {
                        healthService.logWaterIntake(amountMl: 250)
                    } label: {
                        Label("\(250.formatted()) mL", systemImage: "plus")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        healthService.logCaffeine(amountMg: 60)
                    } label: {
                        Label("\(60.formatted()) mg", systemImage: "plus")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: LogHydrationIntent(amountMl: 250)) {
                        Label("\(250.formatted()) mL", systemImage: "plus")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundStyle(widget.tintColor)

            Spacer()
        }
        .padding(16)
    }

    private var healthBloodOxygenView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Blood oxygen" : widget.customTitle,
                icon: "lungs.fill",
                badge: ""
            )

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(oxygenValueText)
                    .font(widget.fontFamily.font(size: widget.size == .small ? 36 : 46, weight: .heavy))
                    .foregroundStyle(.primary)
                Text("%")
                    .font(widget.fontFamily.font(size: 16, weight: .bold))
                    .foregroundStyle(widget.tintColor)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                Text("Normal range")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if widget.size != .small {
            HStack(spacing: 8) {
                Label(breathsText, systemImage: "wind")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)

                Text("•")
                    .foregroundStyle(.secondary)

                Label("Resting \(restingRateText)", systemImage: "heart.fill")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.pink)
            }
            }

            Spacer()
        }
        .padding(16)
    }

    private var healthVitalsHubView: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Vitals" : widget.customTitle,
                icon: "waveform.path.ecg.rectangle.fill",
                badge: ""
            )

            Spacer()

            if widget.size == .extraLarge {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    vitalsHubCard(
                        title: "Heart rate",
                        value: heartRateText,
                        subtext: "Resting \(restingRateText)",
                        icon: "heart.fill",
                        color: .pink
                    )

                    vitalsHubCard(
                        title: "Blood oxygen",
                        value: oxygenText,
                        subtext: breathsText,
                        icon: "lungs.fill",
                        color: .cyan
                    )

                    vitalsHubCard(
                        title: "Sleep",
                        value: sleepText,
                        subtext: "Score \(healthService.sleepScore.formatted())",
                        icon: "bed.double.fill",
                        color: .purple
                    )

                    vitalsHubCard(
                        title: "Water",
                        value: waterText,
                        subtext: "Caffeine \(caffeineText)",
                        icon: "drop.fill",
                        color: .teal
                    )

                    vitalsHubCard(
                        title: "Steps",
                        value: stepsText,
                        subtext: "Goal \(stepGoalText)",
                        icon: "figure.walk",
                        color: .green
                    )

                    vitalsHubCard(
                        title: "Active energy",
                        value: caloriesText,
                        subtext: "Today",
                        icon: "flame.fill",
                        color: .orange
                    )
                }

            } else if widget.size == .small {
                VStack(spacing: 8) {
                    vitalsHubCard(
                        title: "Heart rate",
                        value: heartRateText,
                        subtext: "Resting \(restingRateText)",
                        icon: "heart.fill",
                        color: .pink
                    )

                    vitalsHubCard(
                        title: "Blood oxygen",
                        value: oxygenText,
                        subtext: breathsText,
                        icon: "lungs.fill",
                        color: .cyan
                    )
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    vitalsHubCard(
                        title: "Heart rate",
                        value: heartRateText,
                        subtext: "Resting \(restingRateText)",
                        icon: "heart.fill",
                        color: .pink
                    )

                    vitalsHubCard(
                        title: "Blood oxygen",
                        value: oxygenText,
                        subtext: breathsText,
                        icon: "lungs.fill",
                        color: .cyan
                    )

                    vitalsHubCard(
                        title: "Sleep",
                        value: sleepText,
                        subtext: "Score \(healthService.sleepScore.formatted())",
                        icon: "bed.double.fill",
                        color: .purple
                    )

                    vitalsHubCard(
                        title: "Water",
                        value: waterText,
                        subtext: "Caffeine \(caffeineText)",
                        icon: "drop.fill",
                        color: .teal
                    )
                }
            }

            Spacer()
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private func vitalsHubCard(title: String, value: String, subtext: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(widget.fontFamily.font(size: 15, weight: .heavy))
                .foregroundStyle(.primary)

            Text(subtext)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 2. CLOCK CATEGORY VIEWS

    private var clockDigitalView: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerBar(title: widget.customTitle.isEmpty ? "Local time" : widget.customTitle, icon: "clock.fill", badge: "")

            Spacer()

            if widget.size == .extraLarge {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Date.now, format: .dateTime.hour().minute().second())
                        .font(widget.fontFamily.font(size: 48, weight: .black))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    HStack {
                        Text(Date.now, format: .dateTime.weekday(.wide).month().day().year())
                            .font(widget.fontFamily.font(size: 15, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(TimeZone.current.identifier)
                            .font(widget.fontFamily.font(size: 12, weight: .bold))
                            .foregroundStyle(widget.tintColor)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Text("Other cities")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(clockService.cities.prefix(4)) { city in
                            worldCityRow(city)
                        }
                    }
                }
            } else {
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(widget.fontFamily.font(size: widget.size == .small ? 36 : 46, weight: .heavy))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                HStack {
                    Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                        .font(widget.fontFamily.font(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(TimeZone.current.abbreviation() ?? "GMT")
                        .font(widget.fontFamily.font(size: 11, weight: .bold))
                        .foregroundStyle(widget.tintColor)
                }
            }

            Spacer()
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private var clockWorldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "World clock" : widget.customTitle, icon: "globe.americas.fill", badge: "")

            if widget.size == .extraLarge {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(clockService.cities.prefix(6)) { city in
                        worldCityRow(city)
                    }
                }
            } else if widget.size == .large {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(clockService.cities.prefix(4)) { city in
                        worldCityRow(city)
                    }
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(clockService.cities.prefix(widget.size == .small ? 1 : 2)) { city in
                        worldCityRow(city)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(widget.size == .small ? 12 : 14)
    }

    private func worldCityRow(_ city: WorldCityTime) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(city.cityName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(city.timeOffsetDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(city.formattedTime)
                .font(widget.fontFamily.font(size: widget.size == .small ? 15 : 18, weight: .black))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(widget.size == .small ? 6 : 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var clockAnalogView: some View {
        let dialDiameter: CGFloat = {
            switch widget.size {
            case .small: return 76.0
            case .medium: return 84.0
            case .large: return 120.0
            case .extraLarge: return 160.0
            }
        }()

        return VStack(spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Clock" : widget.customTitle, icon: "clock", badge: "")

            Spacer()

            ZStack {
                Circle()
                    .strokeBorder(widget.tintColor.opacity(0.3), lineWidth: 2)
                    .frame(width: dialDiameter, height: dialDiameter)

                // Hour markings
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(i % 3 == 0 ? widget.tintColor : Color.secondary.opacity(0.4))
                        .frame(width: 2, height: i % 3 == 0 ? 8 : 4)
                        .offset(y: -dialDiameter / 2 + 6)
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                // Clock hands (Simulated 10:10:30)
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 3.5, height: dialDiameter * 0.28)
                    .offset(y: -dialDiameter * 0.14)
                    .rotationEffect(.degrees(300))

                Rectangle()
                    .fill(widget.tintColor)
                    .frame(width: 2.5, height: dialDiameter * 0.38)
                    .offset(y: -dialDiameter * 0.19)
                    .rotationEffect(.degrees(60))

                Circle()
                    .fill(widget.tintColor)
                    .frame(width: 6, height: 6)
            }

            if widget.size == .large || widget.size == .extraLarge {
                Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    // MARK: - 3. REMINDERS CATEGORY VIEWS

    private var remindersListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Reminders" : widget.customTitle,
                icon: "checklist",
                badge: ""
            )

            let maxItems: Int = {
                switch widget.size {
                case .small: return 2
                case .medium: return 3
                case .large: return 5
                case .extraLarge: return 8
                }
            }()

            VStack(alignment: .leading, spacing: widget.size == .extraLarge ? 5 : 6) {
                ForEach(remindersService.reminders.prefix(maxItems)) { reminder in
                    if isInteractivePreview {
                        Button {
                            remindersService.toggleReminder(id: reminder.id)
                        } label: {
                            reminderRow(reminder)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: ToggleReminderIntent(reminderId: reminder.id)) {
                            reminderRow(reminder)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 0)

            if widget.size == .extraLarge {
                let completed = remindersService.reminders.filter { $0.isCompleted }.count
                let total = remindersService.reminders.count
                HStack {
                    Label("\(completed.formatted()) of \(total.formatted()) done", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(widget.tintColor)
                    Spacer()
                }
            }
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private func reminderRow(_ reminder: GlassReminderItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(reminder.isCompleted ? .green : widget.tintColor)

            Text(reminder.title)
                .font(.caption)
                .fontWeight(.medium)
                .strikethrough(reminder.isCompleted)
                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            Text(reminder.dueDateDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, widget.size == .extraLarge ? 3 : 4)
    }

    private var remindersTodayView: some View {
        let completed = remindersService.reminders.filter { $0.isCompleted }.count
        let total = remindersService.reminders.count
        let remaining = total - completed

        return VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Today" : widget.customTitle, icon: "checklist.checked", badge: "")

            if widget.size == .small {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(completed.formatted()) of \(total.formatted())")
                            .font(widget.fontFamily.font(size: 24, weight: .black))
                            .foregroundStyle(.primary)
                        Text("Done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 5)
                            .frame(width: 42, height: 42)
                        Circle()
                            .trim(from: 0, to: total > 0 ? CGFloat(completed) / CGFloat(total) : 0)
                            .stroke(widget.tintColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 42, height: 42)
                            .rotationEffect(.degrees(-90))
                    }
                }
                Spacer()
            } else if widget.size == .medium {
                HStack(spacing: 14) {
                    // Left Progress Metric
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(completed.formatted()) of \(total.formatted())")
                            .font(widget.fontFamily.font(size: 22, weight: .black))
                            .foregroundStyle(.primary)
                        Text("\(remaining.formatted()) left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 5)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: total > 0 ? CGFloat(completed) / CGFloat(total) : 0)
                                .stroke(widget.tintColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                        }
                        .padding(.top, 2)
                    }

                    Divider()
                        .frame(height: 50)

                    // Right items
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(remindersService.reminders.prefix(2)) { reminder in
                            reminderRow(reminder)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            } else {
                // Large and Extra Large layout
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(completed.formatted()) of \(total.formatted())")
                            .font(widget.fontFamily.font(size: 28, weight: .black))
                            .foregroundStyle(.primary)
                        Text("Done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 6)
                            .frame(width: 52, height: 52)
                        Circle()
                            .trim(from: 0, to: total > 0 ? CGFloat(completed) / CGFloat(total) : 0)
                            .stroke(widget.tintColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))

                        Text((total > 0 ? Double(completed) / Double(total) : 0).formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }

                Divider()
                    .padding(.vertical, 2)

                let taskCount = widget.size == .extraLarge ? 6 : 4
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(remindersService.reminders.prefix(taskCount)) { reminder in
                        if isInteractivePreview {
                            Button {
                                remindersService.toggleReminder(id: reminder.id)
                            } label: {
                                reminderRow(reminder)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: ToggleReminderIntent(reminderId: reminder.id)) {
                                reminderRow(reminder)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    // MARK: - 4. CALENDAR CATEGORY VIEWS (APPLE CALENDAR / EVENTKIT)

    @ViewBuilder
    private var calendarUpcomingView: some View {
        switch widget.size {
        case .small:
            calendarUpcomingSmallView
        case .medium:
            calendarUpcomingMediumView
        case .large:
            calendarUpcomingLargeView
        case .extraLarge:
            calendarUpcomingExtraLargeView
        }
    }

    private var calendarUpcomingSmallView: some View {
        let event = calendarService.nextUpcomingEvent
        let cal = Calendar.current
        let dayNum = cal.component(.day, from: Date())
        let monthStr = Date.now.formatted(.dateTime.month(.abbreviated))

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(monthStr)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(widget.tintColor)
                    Text(dayNum.formatted())
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Spacer()
                if let event = event {
                    Text(event.relativeDescription)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(widget.tintColor)
                }
            }

            Spacer()

            if let event = event {
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(widget.fontFamily.font(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(event.timeDescription)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)

                    if !event.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 8))
                            Text(event.location)
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No upcoming events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }

    private var calendarUpcomingMediumView: some View {
        let cal = Calendar.current
        let dayNum = cal.component(.day, from: Date())
        let dayName = Date.now.formatted(.dateTime.weekday(.abbreviated))
        let monthStr = Date.now.formatted(.dateTime.month(.abbreviated))
        let upcoming = Array(calendarService.upcomingEvents.prefix(2))

        return VStack(alignment: .leading, spacing: 10) {
            headerBar(title: widget.customTitle.isEmpty ? "Calendar" : widget.customTitle, icon: "calendar", badge: "")

            HStack(spacing: 14) {
                // Left Date Hero Tile
                VStack(spacing: 2) {
                    Text(dayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(widget.tintColor)
                    Text(dayNum.formatted())
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(monthStr)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 66)

                // Right: Upcoming event list
                VStack(alignment: .leading, spacing: 6) {
                    if upcoming.isEmpty {
                        Text("No scheduled events")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(upcoming) { event in
                            calendarEventRow(event)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(16)
    }

    private var calendarUpcomingLargeView: some View {
        let upcoming = Array(calendarService.upcomingEvents.prefix(4))

        return VStack(alignment: .leading, spacing: 12) {
            headerBar(title: widget.customTitle.isEmpty ? "Up next" : widget.customTitle, icon: "calendar.badge.clock", badge: "")

            VStack(spacing: 8) {
                ForEach(upcoming) { event in
                    calendarEventRowLarge(event)
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private var calendarUpcomingExtraLargeView: some View {
        let upcoming = Array(calendarService.upcomingEvents.prefix(5))
        let nextEvent = calendarService.nextUpcomingEvent
        let cal = Calendar.current
        let dayNum = cal.component(.day, from: Date())
        let dayName = Date.now.formatted(.dateTime.weekday(.abbreviated))
        let monthStr = Date.now.formatted(.dateTime.month(.abbreviated))

        return VStack(alignment: .leading, spacing: 10) {
            headerBar(
                title: widget.customTitle.isEmpty ? "Calendar" : widget.customTitle,
                icon: "calendar.badge.clock",
                badge: ""
            )

            // Top Hero: Date & Next Meeting
            HStack(spacing: 12) {
                VStack(spacing: 1) {
                    Text(dayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(widget.tintColor)
                    Text(dayNum.formatted())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(monthStr)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Up next")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(widget.tintColor)

                    if let event = nextEvent {
                        Text(event.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        Text(event.timeDescription)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        if !event.location.isEmpty {
                            Label(event.location, systemImage: "mappin.and.ellipse")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No upcoming meetings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Text("Later")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            if upcoming.isEmpty {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 20))
                        .foregroundStyle(widget.tintColor)
                    Text("Nothing scheduled")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(upcoming) { event in
                        calendarEventRowLarge(event)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Label("\(calendarService.todayEvents.count.formatted()) events today", systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(14)
    }

    private func calendarEventRow(_ event: GlassCalendarEvent) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 4, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(event.timeDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if !event.location.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(event.location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
    }

    private func calendarEventRowLarge(_ event: GlassCalendarEvent) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(event.startFormatted)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text(event.relativeDescription)
                    .font(.system(size: 9))
                    .foregroundStyle(widget.tintColor)
            }
            .frame(width: 54, alignment: .trailing)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 3.5, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(event.timeDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Calendar Month View
    @ViewBuilder
    private var calendarMonthView: some View {
        switch widget.size {
        case .small:
            calendarMonthSmallView
        case .medium:
            calendarMonthMediumView
        case .large:
            calendarMonthLargeView
        case .extraLarge:
            calendarMonthExtraLargeView
        }
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    /// Weekday headers plus the day grid for the current month.
    private func monthGrid(cellHeight: CGFloat, fontSize: CGFloat, spacing: CGFloat) -> some View {
        let grid = MonthGrid()

        return VStack(spacing: spacing) {
            HStack(spacing: 0) {
                ForEach(grid.weekdaySymbols.indices, id: \.self) { index in
                    Text(grid.weekdaySymbols[index])
                        .font(.system(size: fontSize - 0.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: spacing) {
                ForEach(grid.cells) { cell in
                    if let day = cell.day {
                        let isToday = day == grid.today
                        Text(day.formatted())
                            .font(.system(size: fontSize, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? Color.white : Color.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(width: cellHeight + 2, height: cellHeight)
                            .background {
                                if isToday {
                                    Circle().fill(widget.tintColor)
                                }
                            }
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(height: cellHeight)
                    }
                }
            }
        }
    }

    private var calendarMonthSmallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(widget.customTitle.isEmpty ? Date.now.formatted(.dateTime.month(.wide)) : widget.customTitle)
                .font(widget.fontFamily.font(size: 12, weight: .semibold))
                .foregroundStyle(widget.tintColor)
                .lineLimit(1)

            monthGrid(cellHeight: 14, fontSize: 8.5, spacing: 2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var calendarMonthMediumView: some View {
        let upcoming = Array(calendarService.upcomingEvents.prefix(2))

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.month(.wide)))
                    .font(widget.fontFamily.font(size: 12, weight: .semibold))
                    .foregroundStyle(widget.tintColor)
                    .lineLimit(1)

                monthGrid(cellHeight: 14, fontSize: 8.5, spacing: 2)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: 155)

            VStack(alignment: .leading, spacing: 8) {
                Text(widget.customTitle.isEmpty ? "Up next" : widget.customTitle)
                    .font(widget.fontFamily.font(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if upcoming.isEmpty {
                    Text("No more events today")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcoming) { event in
                        compactEventRow(event)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func compactEventRow(_ event: GlassCalendarEvent) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 3, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(event.timeDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }

    private var calendarMonthLargeView: some View {
        let upcoming = Array(calendarService.upcomingEvents.prefix(2))

        return VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? monthTitle : widget.customTitle, icon: "calendar", badge: "")

            monthGrid(cellHeight: 18, fontSize: 11, spacing: 3)

            Divider()
                .padding(.vertical, 2)

            VStack(spacing: 6) {
                ForEach(upcoming) { event in
                    calendarEventRowLarge(event)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var calendarMonthExtraLargeView: some View {
        let upcoming = Array(calendarService.upcomingEvents.prefix(3))

        return VStack(alignment: .leading, spacing: 10) {
            headerBar(title: widget.customTitle.isEmpty ? monthTitle : widget.customTitle, icon: "calendar", badge: "")

            monthGrid(cellHeight: 30, fontSize: 14, spacing: 6)

            Divider()
                .padding(.vertical, 2)

            if upcoming.isEmpty {
                Text("No more events today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(upcoming) { event in
                        calendarEventRowLarge(event)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var calendarDayView: some View {
        let isCompact = widget.size == .small
        let limit: Int = {
            switch widget.size {
            case .small, .medium: return 2
            case .large: return 4
            case .extraLarge: return 7
            }
        }()
        let events = Array(calendarService.todayEvents.prefix(limit))

        return VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            headerBar(title: widget.customTitle.isEmpty ? "Today" : widget.customTitle, icon: "list.bullet.below.rectangle", badge: "")

            if events.isEmpty {
                Spacer(minLength: 0)
                Text("No events today")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: isCompact ? 6 : 8) {
                    ForEach(events) { event in
                        timelineRow(event, compact: isCompact)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(isCompact ? 12 : 16)
    }

    private func timelineRow(_ event: GlassCalendarEvent, compact: Bool) -> some View {
        let isNext = event.id == calendarService.nextUpcomingEvent?.id
        let isPast = event.endDate < Date.now

        return HStack(spacing: compact ? 6 : 10) {
            Text(event.startFormatted)
                .font(.system(size: compact ? 10 : 11, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(isNext ? widget.tintColor : .secondary)
                .lineLimit(1)
                .frame(width: compact ? 46 : 60, alignment: .leading)

            Text(event.title)
                .font(compact ? .caption2 : .caption)
                .fontWeight(isNext ? .semibold : .regular)
                .foregroundStyle(isPast ? .secondary : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            if isPast {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 6 : 8)
        .background(
            isNext ? widget.tintColor.opacity(0.18) : Color.white.opacity(0.05),
            in: RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
        )
    }

    // MARK: - 5. NOTES CATEGORY VIEWS

    private var notesQuickMemoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                headerBar(title: widget.customTitle.isEmpty ? "Note" : widget.customTitle, icon: "note.text", badge: "")
                Spacer()
                Button {
                    notesService.openAppleNotesApp()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(widget.tintColor)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let note = notesService.activeNote {
                Text(note.title)
                    .font(widget.fontFamily.font(size: widget.size == .small ? 14 : 17, weight: .bold))
                    .foregroundStyle(widget.tintColor)
                    .lineLimit(1)

                Text(widget.customSubtitle.isEmpty ? note.content : widget.customSubtitle)
                    .font(widget.fontFamily.font(size: widget.size == .small ? 12 : 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(widget.size == .extraLarge ? 12 : (widget.size == .large ? 6 : (widget.size == .medium ? 4 : 2)))
                    .multilineTextAlignment(.leading)
            } else {
                Text(widget.customSubtitle.isEmpty ? "Tap to add note" : widget.customSubtitle)
                    .font(widget.fontFamily.font(size: widget.size == .small ? 13 : 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private var notesScratchpadView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Scratchpad" : widget.customTitle, icon: "square.and.pencil", badge: "")

            VStack(alignment: .leading, spacing: 6) {
                let allItems = [
                    "Call the plumber",
                    "Book flights for May",
                    "Pick up dry cleaning",
                    "Renew passport",
                    "Plan weekend hike",
                    "Return library books",
                    "Water the plants"
                ]
                let items: [String] = {
                    switch widget.size {
                    case .small: return Array(allItems.prefix(2)).map { "• \($0)" }
                    case .medium: return Array(allItems.prefix(3)).map { "• \($0)" }
                    case .large: return Array(allItems.prefix(5)).map { "• \($0)" }
                    case .extraLarge: return allItems.map { "• \($0)" }
                    }
                }()

                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(widget.size == .small ? .caption2 : .caption)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    // MARK: - 6. ALARMS CATEGORY VIEWS

    private var alarmsNextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Alarm" : widget.customTitle, icon: "alarm.fill", badge: "")

            Spacer()

            Text(alarmsService.nextAlarmFormatted)
                .font(widget.fontFamily.font(size: widget.size == .extraLarge ? 52 : (widget.size == .large ? 42 : (widget.size == .small ? 26 : 34)), weight: .heavy))
                .foregroundStyle(.primary)

            if widget.size == .extraLarge || widget.size == .large {
                HStack(spacing: 8) {
                    let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
                    ForEach(symbols.indices, id: \.self) { index in
                        Text(symbols[index])
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(widget.isToggled ? widget.tintColor : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06), in: Circle())
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Text(alarmsService.nextAlarm?.label ?? "Alarm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isInteractivePreview {
                    Button {
                        onToggleTap?()
                    } label: {
                        alarmToggleBadge
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: ToggleWidgetStateIntent(widgetId: widget.id.uuidString)) {
                        alarmToggleBadge
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(widget.size == .small ? 12 : 16)
    }

    private var alarmToggleBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(widget.isToggled ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(widget.isToggled ? "On" : "Off")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(widget.isToggled ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1), in: Capsule())
    }

    private var alarmsHubView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle.isEmpty ? "Alarms" : widget.customTitle, icon: "bell.badge.fill", badge: "")

            if widget.size == .extraLarge {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(alarmsService.alarms.prefix(6)) { alarm in
                        alarmHubButton(alarm)
                    }
                }

                Spacer()

                HStack {
                    Label("Next: \(alarmsService.nextAlarmFormatted)", systemImage: "alarm.fill")
                        .font(.caption2)
                        .foregroundStyle(widget.tintColor)
                    Spacer()
                }
            } else if widget.size == .large {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(alarmsService.alarms.prefix(4)) { alarm in
                        alarmHubButton(alarm)
                    }
                }
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 6) {
                    ForEach(alarmsService.alarms.prefix(widget.size == .small ? 1 : 2)) { alarm in
                        alarmHubButton(alarm)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(widget.size == .small ? 12 : 14)
    }

    @ViewBuilder
    private func alarmHubButton(_ alarm: GlassAlarmItem) -> some View {
        if isInteractivePreview {
            Button {
                alarmsService.toggleAlarm(id: alarm.id)
            } label: {
                alarmHubRow(alarm)
            }
            .buttonStyle(.plain)
        } else {
            Button(intent: ToggleAlarmIntent(alarmId: alarm.id)) {
                alarmHubRow(alarm)
            }
            .buttonStyle(.plain)
        }
    }

    private func alarmHubRow(_ alarm: GlassAlarmItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(alarm.timeFormatted)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(alarm.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: alarm.isEnabled ? "bell.fill" : "bell.slash")
                .foregroundStyle(alarm.isEnabled ? widget.tintColor : .secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Legacy Views

    private var legacyQuickHubView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle, icon: "switch.2", badge: "")
            Spacer()
            Text("Count \(widget.counterValue.formatted())")
                .font(.headline)
            Spacer()
        }
        .padding(16)
    }

    private var legacyCalendarView: some View {
        calendarUpcomingView
    }

    private var legacyVitalsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBar(title: widget.customTitle, icon: "battery.100.bolt", badge: "")
            Spacer()
            Text("Battery")
                .font(.headline)
            Spacer()
        }
        .padding(16)
    }

    // MARK: - Shared Glass Header
    private func headerBar(title: String, icon: String, badge: String) -> some View {
        HStack(spacing: 6) {
            Label(title, systemImage: icon)
                .font(widget.fontFamily.font(size: widget.size == .small ? 12 : 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 2)

            if !badge.isEmpty {
                let badgeText = badge

                if isInteractivePreview {
                    Button {
                        onToggleTap?()
                    } label: {
                        headerBadge(badgeText)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: CycleGlassMaterialIntent(widgetId: widget.id.uuidString)) {
                        headerBadge(badgeText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func headerBadge(_ text: String) -> some View {
        Text(text)
            .font(widget.fontFamily.font(size: 11, weight: .semibold))
            .foregroundStyle(widget.tintColor)
            .lineLimit(1)
    }
}

// MARK: - Month Layout

/// Locale-aware layout for a month grid.
/// Leading blanks get negative IDs so they never collide with day numbers inside `ForEach`.
struct MonthGrid {
    struct Cell: Identifiable {
        let id: Int
        let day: Int?
    }

    let cells: [Cell]
    let weekdaySymbols: [String]
    let today: Int

    init(date: Date = .now, calendar: Calendar = .current) {
        let firstOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let leadingBlanks = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

        cells = (0..<leadingBlanks).map { Cell(id: -1 - $0, day: nil) }
            + (1...dayCount).map { Cell(id: $0, day: $0) }

        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        weekdaySymbols = Array(symbols[start...] + symbols[..<start])
        today = calendar.component(.day, from: date)
    }
}
