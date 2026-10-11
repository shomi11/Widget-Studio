import SwiftUI

/// Curated widget designs grouped by category, plus matching wallpapers.
public struct PresetGalleryView: View {
    @ObservedObject var store: WidgetStore

    @State private var categoryFilter: WidgetCategory? = nil
    @State private var editorRequest: EditorRequest? = nil

    static let curatedGallery: [WidgetConfig] = [
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
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
            customTitle: "",
            customSubtitle: "",
            counterValue: 2,
            isToggled: true
        )
    ]

    public init(store: WidgetStore) {
        self.store = store
    }

    private var sections: [(category: WidgetCategory, presets: [WidgetConfig])] {
        let available = Self.curatedGallery.filter { $0.size.isAvailableOnCurrentDevice }
        return WidgetCategory.allCases.compactMap { category in
            guard categoryFilter == nil || categoryFilter == category else { return nil }
            let presets = available.filter { $0.category == category }
            return presets.isEmpty ? nil : (category, presets)
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                if categoryFilter == nil {
                    Section {
                        NavigationLink {
                            WallpaperStudioView()
                        } label: {
                            Label("Wallpapers", systemImage: "photo.on.rectangle")
                        }
                    }
                }

                ForEach(sections, id: \.category) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.presets) { preset in
                            presetRow(preset)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .headerProminence(.increased)
            .scrollEdgeEffectStyle(.soft, for: .all)
            .contentMargins(.bottom, 24, for: .scrollContent)
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Category", selection: $categoryFilter) {
                            Text("All Categories")
                                .tag(WidgetCategory?.none)
                            ForEach(WidgetCategory.allCases) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(Optional(category))
                            }
                        }
                    } label: {
                        Label(
                            "Filter",
                            systemImage: categoryFilter == nil
                                ? "line.3.horizontal.decrease"
                                : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                }
            }
            .sheet(item: $editorRequest) { request in
                WidgetEditorView(widget: request.widget, isNew: true, store: store)
            }
        }
    }

    private func presetRow(_ preset: WidgetConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetPreview(widget: preset)
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.headline)
                    Text("\(preset.size.rawValue) · \(preset.type.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Add") {
                    var copy = preset
                    copy.id = UUID()
                    editorRequest = EditorRequest(widget: copy, isNew: true)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add \(preset.name)")
            }
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
