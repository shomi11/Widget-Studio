import SwiftUI

/// A full-featured widget editor studio for customizing Liquid Glass materials,
/// optical parameters, typography, Apple category selection, and category permissions.
@MainActor
public struct WidgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WidgetStore
    @ObservedObject var permissionManager = CategoryPermissionManager.shared

    @State public var widget: WidgetConfig
    public let isNew: Bool

    // Category permission request sheet
    @State private var showingPermissionSheet: Bool = false
    @State private var permissionPromptCategory: WidgetCategory? = nil

    // Simulated Wallpaper backgrounds to demonstrate real-time glass refraction
    @State private var selectedWallpaper: SimulatedWallpaper = .aurora
    @State private var previewScale: CGFloat = 1.0
    @State private var setAsActiveHome: Bool = true

    public enum SimulatedWallpaper: String, CaseIterable, Identifiable {
        case aurora = "Aurora Waves"
        case neonSunset = "Neon Sunset"
        case deepObsidian = "Deep Obsidian"
        case abstractGeometry = "Prism Blur"

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
            case .neonSunset:
                LinearGradient(
                    colors: [Color(hex: "#FA709A"), Color(hex: "#FEE140"), Color(hex: "#301860")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .deepObsidian:
                LinearGradient(
                    colors: [Color(hex: "#0D0D11"), Color(hex: "#1A1A24"), Color(hex: "#050508")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .abstractGeometry:
                AngularGradient(
                    gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                    center: .center
                )
                .blur(radius: 40)
            }
        }
    }

    private let presetColors: [String] = [
        "#0A84FF", // Electric Blue
        "#30D158", // Mint Green
        "#BF5AF2", // Neon Purple
        "#FF375F", // Hot Pink
        "#FF9F0A", // Sunset Orange
        "#FFD60A", // Golden Yellow
        "#64D2FF", // Ice Cyan
        "#FFFFFF"  // Pure White
    ]

    private let solidPaletteSwatches: [(name: String, hex: String)] = [
        ("Obsidian", "#000000"),
        ("Space Gray", "#1C1C1E"),
        ("Midnight Navy", "#0A192F"),
        ("Royal Indigo", "#1E1B4B"),
        ("Deep Spruce", "#064E3B"),
        ("Crimson", "#4C0519"),
        ("Royal Plum", "#3B0764"),
        ("Graphite", "#2C2C2E"),
        ("Deep Mocha", "#3B1F0E"),
        ("Slate Teal", "#134E4A"),
        ("Amber", "#451A03"),
        ("Snow White", "#F2F2F7")
    ]

    private var solidColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: widget.solidColorHex) },
            set: { widget.solidColorHex = $0.toHex() }
        )
    }

    private var gradientStartBinding: Binding<Color> {
        Binding(
            get: { Color(hex: widget.gradientStartHex) },
            set: { widget.gradientStartHex = $0.toHex() }
        )
    }

    private var gradientEndBinding: Binding<Color> {
        Binding(
            get: { Color(hex: widget.gradientEndHex) },
            set: { widget.gradientEndHex = $0.toHex() }
        )
    }

    private var glassTintBinding: Binding<Color> {
        Binding(
            get: { Color(hex: widget.tintHex) },
            set: { widget.tintHex = $0.toHex() }
        )
    }

    private func meshNodeBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: {
                if index < widget.meshColorsHex.count {
                    return Color(hex: widget.meshColorsHex[index])
                }
                return .blue
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

    public init(widget: WidgetConfig, isNew: Bool = false, store: WidgetStore? = nil) {
        self._widget = State(initialValue: widget)
        self.isNew = isNew
        self.store = store ?? .shared
    }

    private var previewContainerHeight: CGFloat {
        switch widget.size {
        case .small: return 220
        case .medium: return 220
        case .large: return 380
        case .extraLarge: return 560
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Live Interactive Canvas
                    livePreviewCanvas

                    // 2. Apple Ecosystem Category Picker & Permission Status
                    categoryPickerSection

                    // 3. Widget Type & Form Factor
                    widgetTypeSection

                    // 4. Material & Optics Section
                    materialOpticsSection

                    // 5. Content & Category Specifics
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(widget.name.isEmpty ? "Widget Studio" : widget.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
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
                    .fontWeight(.bold)
                    .tint(widget.tintColor)
                }
            }
            .sheet(item: $permissionPromptCategory) { category in
                CategoryPermissionSheet(category: category) {
                    // Permission resolved
                    permissionManager.refreshStatuses()
                }
            }
        }
    }

    // MARK: - 1. Live Interactive Canvas
    private var livePreviewCanvas: some View {
        VStack(spacing: 14) {
            ZStack {
                selectedWallpaper.backgroundView
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)

                // 1:1 Live Widget Display
                WidgetDisplayView(
                    widget: widget,
                    isInteractivePreview: true,
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
                .frame(width: widget.size.previewWidth, height: widget.size.previewHeight)
                .padding(24)
            }
            .frame(height: previewContainerHeight)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: widget.size)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

            // Wallpaper Switcher Pills
            HStack(spacing: 8) {
                Text("Wallpaper:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(SimulatedWallpaper.allCases) { wallpaper in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedWallpaper = wallpaper
                                }
                            } label: {
                                Text(wallpaper.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedWallpaper == wallpaper ? Color.primary.opacity(0.18) : Color.primary.opacity(0.06),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedWallpaper == wallpaper ? .primary : .secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 2. Category Picker & Permission Section
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("APPLE APP CATEGORY", systemImage: "square.stack.3d.up")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Category Segmented Grid
            HStack(spacing: 8) {
                ForEach(WidgetCategory.allCases) { category in
                    let isSelected = widget.category == category
                    let tint = Color(hex: category.defaultTintHex)

                    Button {
                        switchCategory(to: category)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 18, weight: .bold))
                            Text(category.rawValue)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? tint : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Permission Status Alert / Badge
            let currentStatus = permissionManager.status(for: widget.category)
            HStack(spacing: 10) {
                Image(systemName: currentStatus.isUsable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(currentStatus.badgeColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(widget.category.appleApp) (\(widget.category.frameworkName))")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(currentStatus.isUsable ? "Authorized for real-time widget synchronization." : "Permission required to fetch live data from this Apple framework.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !currentStatus.isUsable {
                    Button("Grant Access") {
                        permissionPromptCategory = widget.category
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: widget.category.defaultTintHex), in: Capsule())
                    .foregroundStyle(.white)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Authorized")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12), in: Capsule())
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - 3. Widget Type & Form Factor
    private var widgetTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("WIDGET VARIANT & SIZE", systemImage: "square.grid.2x2")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Redesigned Form Factor Selector (Grid of Glass Badges)
            VStack(alignment: .leading, spacing: 6) {
                Text("FORM FACTOR")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(WidgetSize.allCases) { size in
                        let isSelected = widget.size == size
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                widget.size = size
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(size.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    Spacer(minLength: 0)
                                }

                                Text(size.dimensionLabel)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? widget.tintColor : Color.primary.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(isSelected ? widget.tintColor.opacity(0.8) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Filtered Types for this Category
            VStack(spacing: 8) {
                ForEach(widget.category.widgetTypes) { type in
                    Button {
                        withAnimation { widget.type = type }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(widget.type == type ? widget.tintColor : .secondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                Text(type.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()

                            if widget.type == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(widget.tintColor)
                            }
                        }
                        .padding(12)
                        .background(
                            widget.type == type ? widget.tintColor.opacity(0.12) : Color.primary.opacity(0.04),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - 4. Background & Surface Design Section
    private var materialOpticsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("WIDGET BACKGROUND & SURFACE", systemImage: "paintbrush.fill")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Background Mode Selector Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                ForEach(WidgetBackgroundMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            widget.backgroundMode = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .bold))
                            Text(mode.rawValue)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            widget.backgroundMode == mode ? widget.tintColor.opacity(0.18) : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(widget.backgroundMode == mode ? widget.tintColor : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(widget.backgroundMode == mode ? widget.tintColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Mode-specific configuration view
            Group {
                switch widget.backgroundMode {
                case .liquidGlass:
                    liquidGlassControls
                case .solidColor:
                    solidColorControls
                case .linearGradient, .radialGradient:
                    gradientControls
                case .meshGradient:
                    meshGradientControls
                }
            }

            Divider()

            // Universal Optics & Surface Overcoat
            universalOpticsControls
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // Liquid Glass Sub-Panel
    private var liquidGlassControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Glass Material Style")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 10) {
                ForEach(GlassMaterialStyle.allCases) { style in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            widget.glassStyle = style
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: style.systemIcon)
                                .font(.system(size: 18, weight: .bold))
                            Text(style.rawValue)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            widget.glassStyle == style ? widget.tintColor.opacity(0.18) : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(widget.glassStyle == style ? widget.tintColor : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(widget.glassStyle == style ? widget.tintColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Glass Infused Tint with Swatches + Native ColorPicker
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Glass Infused Tint")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    ColorPicker("", selection: glassTintBinding, supportsOpacity: false)
                        .labelsHidden()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button {
                                withAnimation { widget.tintHex = hex }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: widget.tintHex.uppercased() == hex.uppercased() ? 2.5 : 0)
                                    )
                                    .shadow(color: Color(hex: hex).opacity(0.4), radius: 3)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Refraction Blur Radius")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(widget.blurRadius)) pt")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $widget.blurRadius, in: 10...50, step: 1)
                    .tint(widget.tintColor)
            }
        }
    }

    // Solid Color Sub-Panel with Picker & Curated Swatches
    private var solidColorControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Solid Background Color")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(widget.solidColorHex.uppercased())
                    .font(.caption2.monospaced())
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08), in: Capsule())
                ColorPicker("", selection: solidColorBinding, supportsOpacity: false)
                    .labelsHidden()
            }

            Text("Curated Apple Dark & Vibrant Swatches")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                ForEach(solidPaletteSwatches, id: \.hex) { swatch in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            widget.solidColorHex = swatch.hex
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: swatch.hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: widget.solidColorHex.uppercased() == swatch.hex.uppercased() ? 2.5 : 0.5)
                                    )
                                .shadow(color: Color(hex: swatch.hex).opacity(0.35), radius: 4)
                            Text(swatch.name)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // Gradient Sub-Panel (Linear & Radial)
    private var gradientControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            if widget.backgroundMode == .linearGradient {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gradient Direction")
                        .font(.caption)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        ForEach(WidgetGradientDirection.allCases) { dir in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    widget.gradientDirection = dir
                                }
                            } label: {
                                Text(dir.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        widget.gradientDirection == dir ? widget.tintColor.opacity(0.2) : Color.primary.opacity(0.05),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(widget.gradientDirection == dir ? widget.tintColor : Color.clear, lineWidth: 1.5)
                                    )
                                    .foregroundStyle(widget.gradientDirection == dir ? widget.tintColor : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Dual Color Pickers
            HStack(spacing: 14) {
                // Start Color
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: widget.gradientStartHex))
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Color")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(widget.gradientStartHex.uppercased())
                            .font(.caption2.monospaced())
                            .fontWeight(.bold)
                    }
                    Spacer()
                    ColorPicker("", selection: gradientStartBinding, supportsOpacity: false)
                        .labelsHidden()
                }
                .padding(10)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                // End Color
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: widget.gradientEndHex))
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("End Color")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(widget.gradientEndHex.uppercased())
                            .font(.caption2.monospaced())
                            .fontWeight(.bold)
                    }
                    Spacer()
                    ColorPicker("", selection: gradientEndBinding, supportsOpacity: false)
                        .labelsHidden()
                }
                .padding(10)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Curated Gradient Presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Curated Gradient Themes")
                    .font(.caption)
                    .fontWeight(.semibold)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WidgetGradientPreset.all) { preset in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    widget.gradientStartHex = preset.startHex
                                    widget.gradientEndHex = preset.endHex
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: preset.startHex), Color(hex: preset.endHex)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 22, height: 22)

                                    Text(preset.name)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    widget.gradientStartHex.uppercased() == preset.startHex.uppercased() && widget.gradientEndHex.uppercased() == preset.endHex.uppercased()
                                        ? widget.tintColor.opacity(0.18)
                                        : Color.primary.opacity(0.05),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            widget.gradientStartHex.uppercased() == preset.startHex.uppercased() && widget.gradientEndHex.uppercased() == preset.endHex.uppercased()
                                                ? widget.tintColor
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // Native Mesh Gradient Sub-Panel (Curated Themes + Corner Node Customization)
    private var meshGradientControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mesh Gradient Theme Presets")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Preset Theme Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WidgetMeshPreset.allCases) { preset in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                widget.meshPreset = preset
                                widget.meshColorsHex = preset.defaultColorsHex
                            }
                        } label: {
                            VStack(spacing: 6) {
                                // Mini mesh preview
                                MeshGradient(
                                    width: 3,
                                    height: 3,
                                    points: [
                                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                                        .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                                    ],
                                    colors: (0..<9).map { idx in
                                        idx < preset.defaultColorsHex.count ? Color(hex: preset.defaultColorsHex[idx]) : .black
                                    }
                                )
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )

                                Text(preset.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                widget.meshPreset == preset ? widget.tintColor.opacity(0.18) : Color.primary.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(widget.meshPreset == preset ? widget.tintColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            // Custom Mesh Nodes Tuner
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mesh Vector Nodes (3×3 Grid)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Corner & Center Nodes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    meshNodePickerCell(title: "Top-L", index: 0)
                    meshNodePickerCell(title: "Top-R", index: 2)
                    meshNodePickerCell(title: "Center", index: 4)
                    meshNodePickerCell(title: "Btm-L", index: 6)
                    meshNodePickerCell(title: "Btm-R", index: 8)
                }
            }
        }
    }

    private func meshNodePickerCell(title: String, index: Int) -> some View {
        VStack(spacing: 4) {
            ColorPicker("", selection: meshNodeBinding(at: index), supportsOpacity: false)
                .labelsHidden()
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // Universal Surface & Glass Overcoat Controls
    private var universalOpticsControls: some View {
        VStack(spacing: 14) {
            Toggle(isOn: $widget.glassOverlayEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Glass Specular Overcoat")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Layers Liquid Glass optical shine and glare")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(widget.tintColor)

            if widget.glassOverlayEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Specular Light Sheen")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(widget.specularIntensity * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $widget.specularIntensity, in: 0.0...1.0, step: 0.05)
                        .tint(widget.tintColor)
                }

                Toggle("Liquid Rim Highlight (Edge Shine)", isOn: $widget.showEdgeShine)
                    .font(.caption)
                    .fontWeight(.medium)
                    .tint(widget.tintColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Background Opacity")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(widget.backgroundOpacity * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $widget.backgroundOpacity, in: 0.3...1.0, step: 0.05)
                    .tint(widget.tintColor)
            }
        }
    }

    // MARK: - 5. Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("CONTENT & LABELS", systemImage: "text.alignleft")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Widget Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Widget Name", text: $widget.name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Header Tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Header Tag", text: $widget.customTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Subtitle / Note Content")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Subtitle", text: $widget.customSubtitle)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Typography Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography Family")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Font", selection: $widget.fontFamily) {
                    ForEach(WidgetFontFamily.allCases) { font in
                        Text(font.rawValue).tag(font)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Active Home Screen Routing
            Toggle(isOn: $setAsActiveHome) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set as Active Home Screen Widget")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("Immediately updates and displays this customized widget on your Home Screen.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(widget.tintColor)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Category Switch & Permission Trigger
    private func switchCategory(to category: WidgetCategory) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            // Pick default type in new category
            if let firstType = category.widgetTypes.first {
                widget.type = firstType
            }
            widget.tintHex = category.defaultTintHex
            widget.customTitle = ""
            widget.customSubtitle = ""

            // Check permission
            if !permissionManager.isAuthorized(for: category) {
                permissionPromptCategory = category
            }
        }
    }

    private func saveWidget() {
        if isNew {
            store.add(widget: widget)
        } else {
            store.update(widget: widget)
        }
        if setAsActiveHome {
            store.setActiveHomeWidget(widget)
        }
        dismiss()
    }
}
