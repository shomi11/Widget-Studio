import SwiftUI

/// Dashboard displaying user widgets organized per category (Health, Clock, Reminders, Calendar, Notes, Alarms),
/// featuring live Apple API integration banners and permission verification on widget creation.
public struct DashboardView: View {
    @ObservedObject var store: WidgetStore
    @Binding var isTabBarMinimized: Bool
    @ObservedObject var permissionManager = CategoryPermissionManager.shared
    @ObservedObject var healthService = HealthKitService.shared
    @ObservedObject var remindersService = RemindersService.shared
    @ObservedObject var calendarService = CalendarService.shared
    @ObservedObject var alarmsService = AlarmsService.shared
    @ObservedObject var clockService = ClockService.shared
    @ObservedObject var notesService = NotesService.shared

    @State private var selectedCategoryFilter: CategoryFilter = .all
    @State private var editingWidget: WidgetConfig? = nil
    @State private var pendingCreateWidget: WidgetConfig? = nil
    @State private var permissionPromptCategory: WidgetCategory? = nil
    @State private var showSetupGuide: Bool = true

    public enum CategoryFilter: Hashable, Identifiable {
        case all
        case category(WidgetCategory)

        public var id: String {
            switch self {
            case .all: return "All"
            case .category(let cat): return cat.rawValue
            }
        }

        public var title: String {
            switch self {
            case .all: return "All Widgets"
            case .category(let cat): return cat.rawValue
            }
        }

        public var icon: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .category(let cat): return cat.icon
            }
        }
    }

    public init(store: WidgetStore = .shared, isTabBarMinimized: Binding<Bool> = .constant(false)) {
        self.store = store
        self._isTabBarMinimized = isTabBarMinimized
    }

    public var filteredWidgets: [WidgetConfig] {
        switch selectedCategoryFilter {
        case .all:
            return store.widgets
        case .category(let cat):
            return store.widgets(for: cat)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category Selector Pills
                    categoryFilterBar

                    // Home Screen Setup & Onboarding Guide
                    if showSetupGuide {
                        homeScreenSetupGuideBanner
                    }

                    // Home Screen Active Slots Routing Bar
                    homeScreenRoutingBanner

                    // Live Apple API Integration Status Card
                    appleFrameworkStatusCard

                    // Widget Grid or Empty State
                    if filteredWidgets.isEmpty {
                        categoryEmptyStateView
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredWidgets) { widget in
                                widgetCard(widget: widget)
                            }
                        }
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
            .navigationTitle("Liquid Glass")
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            withAnimation {
                                store.resetToDefaults()
                            }
                        } label: {
                            Label("Restore All Presets", systemImage: "arrow.counterclockwise")
                        }

                        Button {
                            withAnimation {
                                showSetupGuide.toggle()
                            }
                        } label: {
                            Label(showSetupGuide ? "Hide Setup Guide" : "Show Setup Guide", systemImage: "questionmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                    }

                    Button {
                        initiateWidgetCreation(for: currentCategory)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(hex: currentCategory.defaultTintHex))
                    }
                }
            }
            .sheet(item: $editingWidget) { widget in
                WidgetEditorView(widget: widget, isNew: false, store: store)
            }
            .sheet(item: $pendingCreateWidget) { newWidget in
                WidgetEditorView(widget: newWidget, isNew: true, store: store)
            }
            .sheet(item: $permissionPromptCategory) { category in
                CategoryPermissionSheet(category: category) {
                    // When permission granted, launch editor for this category
                    launchEditor(for: category)
                }
            }
        }
    }

    private var currentCategory: WidgetCategory {
        switch selectedCategoryFilter {
        case .all: return .health
        case .category(let cat): return cat
        }
    }

    // MARK: - Home Screen Setup & Onboarding Guide Banner
    private var homeScreenSetupGuideBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("HOW TO ADD TO HOME SCREEN", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)

                Spacer()

                Button {
                    withAnimation {
                        showSetupGuide = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                stepRow(
                    step: "1",
                    icon: "hand.tap.fill",
                    title: "Select Active Widget",
                    desc: "Tap 'Set as Active Home Screen Widget' on any card below."
                )

                stepRow(
                    step: "2",
                    icon: "plus.app.fill",
                    title: "Go to Home Screen & Tap +",
                    desc: "Long-press anywhere on your Home Screen, then tap the '+' button in the top corner."
                )

                stepRow(
                    step: "3",
                    icon: "square.grid.2x2.fill",
                    title: "Search 'Widget Studio iOS' & Add",
                    desc: "Pick 'Liquid Glass Widget' or dedicated Health, Calendar, Reminders, Clock, or Alarms widgets."
                )
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.12), Color.purple.opacity(0.08), Color.black.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }

    private func stepRow(step: String, icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 22, height: 22)
                Text(step)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Home Screen Slots Routing Bar
    private var homeScreenRoutingBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("ACTIVE HOME SCREEN WIDGETS", systemImage: "sparkles.rectangle.stack.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("LIVE SYNC")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12), in: Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                slotPill(size: .small, config: store.activeWidget(for: .small))
                slotPill(size: .medium, config: store.activeWidget(for: .medium))
                slotPill(size: .large, config: store.activeWidget(for: .large))
                slotPill(size: .extraLarge, config: store.activeWidget(for: .extraLarge))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func slotPill(size: WidgetSize, config: WidgetConfig) -> some View {
        Button {
            editingWidget = config
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: config.category.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(size.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if size == .extraLarge {
                        Text("FULL")
                            .font(.system(size: 7.5, weight: .heavy))
                            .foregroundStyle(config.tintColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(config.tintColor.opacity(0.15), in: Capsule())
                    }
                }
                .foregroundStyle(config.tintColor)

                Text(config.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(config.tintColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Filters
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" filter pill
                filterPill(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    count: store.widgets.count,
                    isSelected: selectedCategoryFilter == .all,
                    tint: .blue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategoryFilter = .all
                    }
                }

                // Core Categories
                ForEach(WidgetCategory.allCases) { category in
                    let count = store.widgets(for: category).count
                    let isSelected = selectedCategoryFilter == .category(category)
                    let tintColor = Color(hex: category.defaultTintHex)
                    let isAuth = permissionManager.isAuthorized(for: category)

                    filterPill(
                        title: category.rawValue,
                        icon: category.icon,
                        count: count,
                        isSelected: isSelected,
                        tint: tintColor,
                        isAuthorized: isAuth
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategoryFilter = .category(category)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterPill(
        title: String,
        icon: String,
        count: Int,
        isSelected: Bool,
        tint: Color,
        isAuthorized: Bool? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let isAuth = isAuthorized, isAuth {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08), in: Capsule())
            }
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

    // MARK: - Apple Framework Status Card
    @ViewBuilder
    private var appleFrameworkStatusCard: some View {
        let category = currentCategory
        let status = permissionManager.status(for: category)
        let isUsable = status.isUsable

        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.defaultTintHex).opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: category.defaultTintHex))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(category.appleApp)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(category.frameworkName)
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color(hex: category.defaultTintHex))
                    }

                    Text(isUsable ? "Authorized • Connected & Live Sync Active" : "Not Authorized • Permission required for live widget sync")
                        .font(.caption)
                        .foregroundStyle(isUsable ? .green : .secondary)
                }

                Spacer()

                if !isUsable {
                    Button {
                        permissionPromptCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Authorize")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: category.defaultTintHex), in: Capsule())
                        .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Authorized")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12), in: Capsule())
                }
            }

            // Category Quick Live Preview Sub-Banner
            switch category {
            case .health:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    frameworkMetricPill(icon: "figure.walk", text: "\(healthService.todaySteps) steps", color: .green)
                    frameworkMetricPill(icon: "heart.fill", text: "\(healthService.currentHeartRate) bpm", color: .pink)
                    frameworkMetricPill(icon: "lungs.fill", text: "\(String(format: "%.1f", healthService.bloodOxygen))% O2", color: .cyan)
                    frameworkMetricPill(icon: "bed.double.fill", text: "\(String(format: "%.1f", healthService.sleepHours))h sleep", color: .purple)
                    frameworkMetricPill(icon: "drop.fill", text: "\(Int(healthService.waterIntakeMl)) mL", color: .blue)
                    frameworkMetricPill(icon: "cup.and.saucer.fill", text: "\(Int(healthService.caffeineMg)) mg", color: .orange)
                }
            case .clock:
                HStack(spacing: 8) {
                    frameworkMetricPill(icon: "network", text: "Atomic Sync Active", color: .green)
                    frameworkMetricPill(icon: "globe", text: TimeZone.current.identifier, color: .blue)
                }
            case .reminders:
                HStack(spacing: 8) {
                    frameworkMetricPill(icon: "checklist", text: "\(remindersService.reminders.count) Reminders", color: .orange)
                    frameworkMetricPill(icon: "circle", text: "\(remindersService.reminders.filter { !$0.isCompleted }.count) Pending", color: .yellow)
                }
            case .calendar:
                HStack(spacing: 8) {
                    frameworkMetricPill(icon: "calendar.badge.clock", text: "\(calendarService.events.count) Events Synced", color: .red)
                    frameworkMetricPill(icon: "clock", text: "Next: \(calendarService.nextUpcomingEvent?.title ?? "None")", color: .blue)
                }
            case .notes:
                HStack(spacing: 8) {
                    frameworkMetricPill(icon: "note.text", text: "\(notesService.notes.count) Memos", color: .yellow)
                    frameworkMetricPill(icon: "arrow.up.right.square", text: "Deep Link Active", color: .green)
                }
            case .alarms:
                HStack(spacing: 8) {
                    frameworkMetricPill(icon: "alarm.fill", text: "Next: \(alarmsService.nextAlarmFormatted)", color: .orange)
                    frameworkMetricPill(icon: "bell.fill", text: "Notifications Active", color: .green)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func frameworkMetricPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Widget Card
    private func widgetCard(widget: WidgetConfig) -> some View {
        let isActive = store.isActiveHomeWidget(widget)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: widget.category.icon)
                            .font(.caption)
                            .foregroundStyle(widget.tintColor)
                        Text(widget.name)
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    HStack(spacing: 6) {
                        Text(widget.size.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.08), in: Capsule())

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(widget.glassStyle.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(widget.category.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(widget.tintColor)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        store.setActiveHomeWidget(widget)
                    } label: {
                        Label(isActive ? "Active Slot (\(widget.size.rawValue))" : "Set as Active for \(widget.size.rawValue)", systemImage: isActive ? "checkmark.seal.fill" : "star")
                    }

                    Button {
                        editingWidget = widget
                    } label: {
                        Label("Edit Configuration", systemImage: "pencil")
                    }

                    Button {
                        store.duplicate(widget: widget)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        store.delete(id: widget.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }

            // Interactive Glass Preview Card
            ZStack {
                LinearGradient(
                    colors: [widget.tintColor.opacity(0.12), Color.purple.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                WidgetDisplayView(
                    widget: widget,
                    isInteractivePreview: true,
                    onCounterTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            store.incrementCounter(for: widget.id)
                        }
                    },
                    onToggleTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            store.toggleSwitch(for: widget.id)
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: widget.size.previewHeight + 20)
            .onTapGesture {
                editingWidget = widget
            }

            // Active Toggle Action Button
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        store.setActiveHomeWidget(widget)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isActive ? "checkmark.seal.fill" : "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isActive ? .green : widget.tintColor)

                        Text(isActive ? "Active Home Screen Widget (\(widget.size.rawValue))" : "Set as Active for \(widget.size.rawValue)")
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(isActive ? .primary : widget.tintColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isActive ? Color.green.opacity(0.12) : widget.tintColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isActive ? Color.green.opacity(0.4) : widget.tintColor.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    editingWidget = widget
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 34)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var categoryEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: currentCategory.icon)
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: currentCategory.defaultTintHex))

            Text("No \(currentCategory.rawValue) Widgets Yet")
                .font(.headline)

            Text("Design a personalized Liquid Glass widget powered by \(currentCategory.appleApp).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 12) {
                Button("Restore Default Presets") {
                    withAnimation {
                        store.resetToDefaults()
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color(hex: currentCategory.defaultTintHex))

                Button("Create New Widget") {
                    initiateWidgetCreation(for: currentCategory)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: currentCategory.defaultTintHex))
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Permission Verification Flow on Create
    private func initiateWidgetCreation(for category: WidgetCategory) {
        if permissionManager.isAuthorized(for: category) {
            launchEditor(for: category)
        } else {
            // Ask for permissions first
            permissionPromptCategory = category
        }
    }

    private func launchEditor(for category: WidgetCategory) {
        let initialType: WidgetType = {
            switch category {
            case .health: return .stepActivity
            case .clock: return .digitalClock
            case .reminders: return .remindersList
            case .calendar: return .calendarUpcoming
            case .notes: return .aestheticQuote
            case .alarms: return .alarmsNext
            }
        }()

        let newConfig = WidgetConfig(
            name: "New \(category.rawValue) Widget",
            size: .medium,
            type: initialType,
            glassStyle: .ultraClear,
            tintHex: category.defaultTintHex,
            blurRadius: 22.0,
            specularIntensity: 0.88,
            showEdgeShine: true,
            fontFamily: .sfRounded,
            customTitle: "",
            customSubtitle: "",
            counterValue: 5,
            isToggled: true
        )

        pendingCreateWidget = newConfig
    }
}
