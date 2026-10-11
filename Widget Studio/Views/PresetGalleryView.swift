import SwiftUI

/// Preset Gallery offering curated Liquid Glass styles categorized across the 6 core Apple apps:
/// Health, Clock, Reminders, Calendar, Notes, and Alarms. Enforces permission checks before adding widgets.
public struct PresetGalleryView: View {
    @ObservedObject var store: WidgetStore
    @Binding var isTabBarMinimized: Bool
    @ObservedObject var permissionManager = CategoryPermissionManager.shared

    @State private var selectedCategoryFilter: WidgetCategory? = nil
    @State private var addedWidgetAlertMessage: String = ""
    @State private var showAddedAlert: Bool = false
    @State private var pendingPresetToAdd: WidgetConfig? = nil
    @State private var permissionPromptCategory: WidgetCategory? = nil

    private let curatedGallery: [WidgetConfig] = [
        // 1. Health Category (Apple HealthKit)
        WidgetConfig(
            name: "Obsidian Health Rings",
            size: .medium,
            type: .stepActivity,
            glassStyle: .blackGlass,
            tintHex: "#FF375F",
            blurRadius: 30.0,
            specularIntensity: 0.98,
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
            blurRadius: 26.0,
            specularIntensity: 0.92,
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
            specularIntensity: 0.90,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "BLOOD OXYGEN",
            customSubtitle: "SpO2 Saturation",
            counterValue: 98,
            isToggled: true
        ),
        WidgetConfig(
            name: "Hydration & Focus Flow",
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
            name: "Pure Glass Vitals",
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
            customTitle: "VITALS TELEMETRY",
            customSubtitle: "Live HealthKit Matrix",
            counterValue: 72,
            isToggled: true
        ),

        // 2. Clock Category
        WidgetConfig(
            name: "Tokyo Cyber Chrono",
            size: .medium,
            type: .digitalClock,
            glassStyle: .blackGlass,
            tintHex: "#0A84FF",
            blurRadius: 28.0,
            specularIntensity: 0.94,
            showEdgeShine: true,
            fontFamily: .sfMono,
            customTitle: "LOCAL • TIME",
            customSubtitle: "Atomic Time Sync",
            counterValue: 0,
            isToggled: true
        ),
        WidgetConfig(
            name: "Global World Matrix",
            size: .large,
            type: .clockWorld,
            glassStyle: .tintedGlass,
            tintHex: "#0A84FF",
            blurRadius: 24.0,
            specularIntensity: 0.90,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "WORLD CLOCK MATRIX",
            customSubtitle: "TYO • LON • NYC • SFO",
            counterValue: 4,
            isToggled: true
        ),

        // 3. Reminders Category
        WidgetConfig(
            name: "Sunset Task Checklist",
            size: .medium,
            type: .remindersList,
            glassStyle: .tintedGlass,
            tintHex: "#FF9F0A",
            blurRadius: 24.0,
            specularIntensity: 0.88,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "APPLE REMINDERS",
            customSubtitle: "Synced with Apple Reminders",
            counterValue: 4,
            isToggled: false
        ),
        WidgetConfig(
            name: "Priority Action Matrix",
            size: .large,
            type: .remindersList,
            glassStyle: .blackGlass,
            tintHex: "#FF9F0A",
            blurRadius: 28.0,
            specularIntensity: 0.92,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "APPLE REMINDERS",
            customSubtitle: "Interactive task list",
            counterValue: 5,
            isToggled: false
        ),
        WidgetConfig(
            name: "Today Task Tracker",
            size: .small,
            type: .remindersToday,
            glassStyle: .ultraClear,
            tintHex: "#FF9F0A",
            blurRadius: 20.0,
            specularIntensity: 0.85,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "TASKS TODAY",
            customSubtitle: "4 Completed",
            counterValue: 4,
            isToggled: true
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
            customSubtitle: "Executive Keynote & Sync",
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
            type: .calendarDayView,
            glassStyle: .ultraClear,
            tintHex: "#FF3B30",
            blurRadius: 20.0,
            specularIntensity: 0.86,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "NEXT EVENT",
            customSubtitle: "In 45 minutes",
            counterValue: 1,
            isToggled: true
        ),

        // 5. Notes Category (Apple Notes)
        WidgetConfig(
            name: "Obsidian Scratchpad",
            size: .medium,
            type: .notesScratchpad,
            glassStyle: .blackGlass,
            tintHex: "#FFD60A",
            blurRadius: 28.0,
            specularIntensity: 0.92,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "APPLE NOTES",
            customSubtitle: "Synced with Apple Notes",
            counterValue: 3,
            isToggled: false
        ),
        WidgetConfig(
            name: "Minimalist Quick Note",
            size: .small,
            type: .aestheticQuote,
            glassStyle: .ultraClear,
            tintHex: "#FFD60A",
            blurRadius: 18.0,
            specularIntensity: 0.82,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "PINNED NOTE",
            customSubtitle: "Executive highlights",
            counterValue: 1,
            isToggled: true
        ),

        // 6. Alarms Category
        WidgetConfig(
            name: "Sunrise Wake Sentinel",
            size: .small,
            type: .alarmsNext,
            glassStyle: .tintedGlass,
            tintHex: "#BF5AF2",
            blurRadius: 22.0,
            specularIntensity: 0.88,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "MORNING WAKE",
            customSubtitle: "7:00 AM Active",
            counterValue: 7,
            isToggled: true
        ),
        WidgetConfig(
            name: "Smart Alarm Console",
            size: .medium,
            type: .alarmsHub,
            glassStyle: .blackGlass,
            tintHex: "#BF5AF2",
            blurRadius: 30.0,
            specularIntensity: 0.95,
            showEdgeShine: true,
            fontFamily: .sfMono,
            customTitle: "ALARM CONSOLE",
            customSubtitle: "Scheduled Chimes",
            counterValue: 2,
            isToggled: true
        )
    ]

    public init(store: WidgetStore = .shared, isTabBarMinimized: Binding<Bool> = .constant(false)) {
        self.store = store
        self._isTabBarMinimized = isTabBarMinimized
    }

    private var filteredGallery: [WidgetConfig] {
        if let cat = selectedCategoryFilter {
            return curatedGallery.filter { $0.category == cat }
        }
        return curatedGallery
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Filter Pills
                    categoryFilterRow

                    // Hero Intro Card
                    heroIntroCard

                    // Curated Presets List
                    ForEach(filteredGallery) { preset in
                        presetCard(preset: preset)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { oldValue, newValue in
                let diff = newValue - oldValue
                if diff > 15 && newValue > 40 {
                    if !isTabBarMinimized {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isTabBarMinimized = true
                        }
                    }
                } else if diff < -15 {
                    if isTabBarMinimized {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isTabBarMinimized = false
                        }
                    }
                }
            }
            .navigationTitle("Preset Gallery")
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
            .alert("Preset Added", isPresented: $showAddedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(addedWidgetAlertMessage)
            }
            .sheet(item: $permissionPromptCategory) { category in
                CategoryPermissionSheet(category: category) {
                    if let pending = pendingPresetToAdd {
                        store.add(widget: pending)
                        addedWidgetAlertMessage = "Added \(pending.name) to your widgets library!"
                        showAddedAlert = true
                        pendingPresetToAdd = nil
                    }
                }
            }
        }
    }

    private var heroIntroCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 38))
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Ecosystem Presets")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Pick from 16 curated designs pre-calibrated for HealthKit, EventKit Calendar, Reminders, Notes, and Alarms.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.12), Color.purple.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Category Filter Pills
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategoryFilter = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("All Presets")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedCategoryFilter == nil ? Color.blue : Color.primary.opacity(0.06),
                        in: Capsule()
                    )
                    .foregroundStyle(selectedCategoryFilter == nil ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)

                ForEach(WidgetCategory.allCases) { category in
                    let isSelected = selectedCategoryFilter == category
                    let tint = Color(hex: category.defaultTintHex)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategoryFilter = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? tint : Color.primary.opacity(0.06),
                            in: Capsule()
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Preset Preview Card
    private func presetCard(preset: WidgetConfig) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: preset.category.icon)
                            .font(.caption)
                            .foregroundStyle(preset.tintColor)
                        Text(preset.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Text("\(preset.category.appleApp) • \(preset.size.rawValue) • \(preset.backgroundMode.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()

                Button {
                    attemptAddPreset(preset)
                } label: {
                    Label("Add Preset", systemImage: "plus")
                        .font(.caption)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(preset.tintColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            // Interactive Glass Preview
            ZStack {
                WidgetDisplayView(widget: preset, isInteractivePreview: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: preset.size.previewHeight + 20)
        }
        .padding(18)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func attemptAddPreset(_ preset: WidgetConfig) {
        if permissionManager.isAuthorized(for: preset.category) {
            store.add(widget: preset)
            addedWidgetAlertMessage = "Added \(preset.name) to your widgets library!"
            showAddedAlert = true
        } else {
            pendingPresetToAdd = preset
            permissionPromptCategory = preset.category
        }
    }
}
