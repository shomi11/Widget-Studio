import SwiftUI

/// Widget editor: a pinned live preview above a standard grouped form.
@MainActor
public struct WidgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: WidgetStore
    @ObservedObject var permissionManager = CategoryPermissionManager.shared

    @State public var widget: WidgetConfig
    public let isNew: Bool

    @State private var previewBackground: PreviewBackground = .aurora
    @State private var setAsActive: Bool
    @State private var isRequestingAccess = false
    @State private var showsAdvanced = false

    /// Backdrops for judging how the widget reads on a Home Screen.
    public enum PreviewBackground: String, CaseIterable, Identifiable {
        case aurora = "Aurora"
        case sunset = "Sunset"
        case dark = "Dark"
        case prism = "Prism"

        public var id: String { rawValue }

        @ViewBuilder
        public var backgroundView: some View {
            switch self {
            case .aurora:
                LinearGradient(
                    colors: [Color(hex: "#0575E6"), Color(hex: "#00F260"), Color(hex: "#101026")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .sunset:
                LinearGradient(
                    colors: [Color(hex: "#FA709A"), Color(hex: "#FEE140"), Color(hex: "#301860")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .dark:
                LinearGradient(
                    colors: [Color(hex: "#0D0D11"), Color(hex: "#1A1A24"), Color(hex: "#050508")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .prism:
                AngularGradient(
                    gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                    center: .center
                )
                .blur(radius: 40)
            }
        }
    }

    public init(widget: WidgetConfig, isNew: Bool = false, store: WidgetStore? = nil) {
        let store = store ?? .shared
        self._widget = State(initialValue: widget)
        self.isNew = isNew
        self.store = store
        self._setAsActive = State(initialValue: isNew || store.isActiveHomeWidget(widget))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                previewPane

                Form {
                    if !permissionManager.isAuthorized(for: widget.category) {
                        dataAccessSection
                    }
                    widgetSection
                    sizeSection
                    styleSection
                    textSection
                    advancedSection
                    homeScreenSection
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(isNew ? "New Widget" : "Edit Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWidget()
                    }
                    .disabled(widget.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Pinned Preview

    private var previewPane: some View {
        previewBackground.backgroundView
            .overlay {
                WidgetPreview(
                    widget: widget,
                    isInteractive: true,
                    onCounterTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            widget.counterValue += 1
                        }
                    },
                    onToggleTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            widget.isToggled.toggle()
                        }
                    }
                )
                .padding(20)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Menu {
                    Picker("Preview Background", selection: $previewBackground) {
                        ForEach(PreviewBackground.allCases) { background in
                            Text(background.rawValue).tag(background)
                        }
                    }
                } label: {
                    Label("Preview Background", systemImage: "photo")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(10)
            }
            .animation(.smooth, value: widget.size)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    // MARK: - Data Access

    private var dataAccessSection: some View {
        let status = permissionManager.status(for: widget.category)

        return Section {
            if status == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } else {
                Button {
                    requestAccess()
                } label: {
                    HStack {
                        Text("Allow \(widget.category.rawValue) Access")
                        if isRequestingAccess {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isRequestingAccess)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("The preview shows sample data. \(widget.category.permissionRationale)")
        }
    }

    // MARK: - Widget

    private var widgetSection: some View {
        Section {
            LabeledContent("Name") {
                TextField("Name", text: $widget.name)
                    .multilineTextAlignment(.trailing)
            }

            Picker("Category", selection: categoryBinding) {
                ForEach(WidgetCategory.allCases) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }

            Picker("Layout", selection: $widget.type) {
                ForEach(typeOptions) { type in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.displayName)
                        Text(type.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var typeOptions: [WidgetType] {
        let options = widget.category.widgetTypes
        return options.contains(widget.type) ? options : options + [widget.type]
    }

    private var categoryBinding: Binding<WidgetCategory> {
        Binding(
            get: { widget.category },
            set: { switchCategory(to: $0) }
        )
    }

    // MARK: - Size

    private var sizeSection: some View {
        Section("Size") {
            HStack(spacing: 12) {
                ForEach(WidgetSize.availableSizes) { size in
                    sizeOption(size)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func sizeOption(_ size: WidgetSize) -> some View {
        let isSelected = widget.size == size
        let scale = 44 / max(338, size.previewHeight)

        return Button {
            withAnimation(.smooth) {
                widget.size = size
            }
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: size.previewWidth * scale, height: size.previewHeight * scale)
                    .frame(height: 44, alignment: .bottom)

                Text(size.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(size.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Style

    private var styleSection: some View {
        Section("Style") {
            Picker("Background", selection: $widget.backgroundMode) {
                ForEach(WidgetBackgroundMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            ColorPicker("Tint", selection: colorBinding(\.tintHex), supportsOpacity: false)

            switch widget.backgroundMode {
            case .liquidGlass:
                Picker("Material", selection: $widget.glassStyle) {
                    ForEach(GlassMaterialStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

            case .solidColor:
                ColorPicker("Color", selection: colorBinding(\.solidColorHex), supportsOpacity: false)

            case .linearGradient, .radialGradient:
                if widget.backgroundMode == .linearGradient {
                    Picker("Direction", selection: $widget.gradientDirection) {
                        ForEach(WidgetGradientDirection.allCases) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                }
                ColorPicker("Start Color", selection: colorBinding(\.gradientStartHex), supportsOpacity: false)
                ColorPicker("End Color", selection: colorBinding(\.gradientEndHex), supportsOpacity: false)
                Menu("Use a Preset") {
                    ForEach(WidgetGradientPreset.all) { preset in
                        Button(preset.name) {
                            widget.gradientStartHex = preset.startHex
                            widget.gradientEndHex = preset.endHex
                        }
                    }
                }

            case .meshGradient:
                Picker("Preset", selection: meshPresetBinding) {
                    ForEach(WidgetMeshPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                DisclosureGroup("Custom Colors") {
                    ColorPicker("Top Left", selection: meshNodeBinding(at: 0), supportsOpacity: false)
                    ColorPicker("Top Right", selection: meshNodeBinding(at: 2), supportsOpacity: false)
                    ColorPicker("Center", selection: meshNodeBinding(at: 4), supportsOpacity: false)
                    ColorPicker("Bottom Left", selection: meshNodeBinding(at: 6), supportsOpacity: false)
                    ColorPicker("Bottom Right", selection: meshNodeBinding(at: 8), supportsOpacity: false)
                }
            }
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<WidgetConfig, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: widget[keyPath: keyPath]) },
            set: { widget[keyPath: keyPath] = $0.toHex() }
        )
    }

    private var meshPresetBinding: Binding<WidgetMeshPreset> {
        Binding(
            get: { widget.meshPreset },
            set: { preset in
                widget.meshPreset = preset
                if preset != .custom {
                    widget.meshColorsHex = preset.defaultColorsHex
                }
            }
        )
    }

    private func meshNodeBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: {
                index < widget.meshColorsHex.count ? Color(hex: widget.meshColorsHex[index]) : .black
            },
            set: { newColor in
                while widget.meshColorsHex.count <= index {
                    widget.meshColorsHex.append("#1C1C1E")
                }
                widget.meshColorsHex[index] = newColor.toHex()
                widget.meshPreset = .custom
            }
        )
    }

    // MARK: - Text

    private var textSection: some View {
        Section("Text") {
            LabeledContent("Title") {
                TextField("Default", text: $widget.customTitle)
                    .multilineTextAlignment(.trailing)
            }

            if widget.type == .aestheticQuote {
                LabeledContent("Note") {
                    TextField("Pinned note", text: $widget.customSubtitle)
                        .multilineTextAlignment(.trailing)
                }
            }

            Picker("Font", selection: $widget.fontFamily) {
                ForEach(WidgetFontFamily.allCases) { font in
                    Text(font.displayName).tag(font)
                }
            }
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section {
            DisclosureGroup("Advanced", isExpanded: $showsAdvanced) {
                if widget.backgroundMode == .liquidGlass {
                    sliderRow("Blur", value: $widget.blurRadius, in: 10...50, step: 1) {
                        Text(Double(widget.blurRadius), format: .number.precision(.fractionLength(0)))
                    }
                }

                Toggle("Shine", isOn: $widget.glassOverlayEnabled)

                if widget.glassOverlayEnabled {
                    sliderRow("Shine Amount", value: $widget.specularIntensity, in: 0...1, step: 0.05) {
                        Text(Double(widget.specularIntensity), format: .percent.precision(.fractionLength(0)))
                    }
                }

                Toggle("Edge Glow", isOn: $widget.showEdgeShine)

                sliderRow("Opacity", value: $widget.backgroundOpacity, in: 0.3...1, step: 0.05) {
                    Text(widget.backgroundOpacity, format: .percent.precision(.fractionLength(0)))
                }
            }
        }
    }

    private func sliderRow<Value: BinaryFloatingPoint, Display: View>(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride,
        @ViewBuilder display: () -> Display
    ) -> some View where Value.Stride: BinaryFloatingPoint {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent(title) {
                display()
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step) {
                Text(title)
            }
        }
    }

    // MARK: - Home Screen

    private var homeScreenSection: some View {
        Section {
            Toggle("Set as Active", isOn: $setAsActive)
        } footer: {
            Text("The active widget is what the \(widget.size.rawValue) Widget Studio widget shows on your Home Screen.")
        }
    }

    // MARK: - Actions

    private func switchCategory(to category: WidgetCategory) {
        guard category != widget.category else { return }
        withAnimation(.smooth) {
            widget.type = category.widgetTypes.first ?? widget.type
            widget.tintHex = category.defaultTintHex
            widget.customTitle = ""
            widget.customSubtitle = ""
        }
    }

    private func requestAccess() {
        isRequestingAccess = true
        Task {
            await permissionManager.requestPermission(for: widget.category)
            isRequestingAccess = false
        }
    }

    private func saveWidget() {
        if isNew {
            store.add(widget: widget)
        } else {
            store.update(widget: widget)
        }
        if setAsActive {
            store.setActiveHomeWidget(widget)
        }
        dismiss()
    }
}
