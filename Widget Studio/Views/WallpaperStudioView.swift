import SwiftUI
import Photos
import UIKit
import Combine

// MARK: - 1. WALLPAPER MODELS & DEVICE CONFIGURATION

/// Target device specification for high-resolution wallpaper rendering
public enum WallpaperDevice: String, CaseIterable, Identifiable {
    case iPhone = "iPhone"
    case iPad = "iPad"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        }
    }

    public var subtitle: String {
        switch self {
        case .iPhone: return "1290 × 2796 px (Ultra-HD)"
        case .iPad: return "2048 × 2732 px (Retina XDR)"
        }
    }

    public var pixelSize: CGSize {
        switch self {
        case .iPhone: return CGSize(width: 1290, height: 2796)
        case .iPad: return CGSize(width: 2048, height: 2732)
        }
    }

    public var aspectRatio: CGFloat {
        switch self {
        case .iPhone: return 1290.0 / 2796.0
        case .iPad: return 2048.0 / 2732.0
        }
    }
}

/// Rendering style for wallpapers
public enum WallpaperStyleType: String, CaseIterable, Identifiable {
    case mesh = "Mesh Gradient"
    case gradient = "Gradients"
    case solid = "Solid & OLED"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .mesh: return "circle.hexagongrid.fill"
        case .gradient: return "slider.horizontal.below.rectangle"
        case .solid: return "circle.fill"
        }
    }
}

/// Represents a curated or custom wallpaper
public struct WallpaperItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: WallpaperStyleType
    public let colorsHex: [String]
    public let meshPreset: WidgetMeshPreset?
    public let gradientDirection: WidgetGradientDirection?

    public static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }

    public init(
        id: String,
        name: String,
        category: WallpaperStyleType,
        colorsHex: [String],
        meshPreset: WidgetMeshPreset? = nil,
        gradientDirection: WidgetGradientDirection? = .diagonal
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.colorsHex = colorsHex
        self.meshPreset = meshPreset
        self.gradientDirection = gradientDirection
    }
}

// MARK: - 2. CURATED WALLPAPERS REPOSITORY

public enum CuratedWallpapersData {
    public static let all: [WallpaperItem] = [
        // MESH GRADIENTS (matching exact widget backgrounds)
        WallpaperItem(
            id: "mesh-cyberpunk",
            name: "Cyberpunk Glow",
            category: .mesh,
            colorsHex: WidgetMeshPreset.cyberpunk.defaultColorsHex,
            meshPreset: .cyberpunk
        ),
        WallpaperItem(
            id: "mesh-sunset",
            name: "Sunset Mirage",
            category: .mesh,
            colorsHex: WidgetMeshPreset.sunset.defaultColorsHex,
            meshPreset: .sunset
        ),
        WallpaperItem(
            id: "mesh-aurora",
            name: "Nordic Aurora",
            category: .mesh,
            colorsHex: WidgetMeshPreset.aurora.defaultColorsHex,
            meshPreset: .aurora
        ),
        WallpaperItem(
            id: "mesh-prism",
            name: "Liquid Prism",
            category: .mesh,
            colorsHex: WidgetMeshPreset.prism.defaultColorsHex,
            meshPreset: .prism
        ),
        WallpaperItem(
            id: "mesh-obsidian",
            name: "Obsidian Smoke",
            category: .mesh,
            colorsHex: WidgetMeshPreset.obsidian.defaultColorsHex,
            meshPreset: .obsidian
        ),
        WallpaperItem(
            id: "mesh-titanium",
            name: "Desert Titanium",
            category: .mesh,
            colorsHex: WidgetMeshPreset.titanium.defaultColorsHex,
            meshPreset: .titanium
        ),
        WallpaperItem(
            id: "mesh-nebula",
            name: "Cosmic Nebula",
            category: .mesh,
            colorsHex: [
                "#3A1C71", "#D76D77", "#FFAF7B",
                "#8A2387", "#4A00E0", "#E94057",
                "#0F2027", "#2C5364", "#120E43"
            ],
            meshPreset: .custom
        ),
        WallpaperItem(
            id: "mesh-electric",
            name: "Electric Emerald",
            category: .mesh,
            colorsHex: [
                "#00F260", "#0575E6", "#11998E",
                "#38EF7D", "#00C9FF", "#92FE9D",
                "#0F2027", "#16222F", "#0B1D13"
            ],
            meshPreset: .custom
        ),

        // LINEAR & RADIAL GRADIENTS
        WallpaperItem(
            id: "grad-sunset",
            name: "Sunset Horizon",
            category: .gradient,
            colorsHex: ["#FF512F", "#DD2476"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-aurora",
            name: "Aurora Neon",
            category: .gradient,
            colorsHex: ["#00C9FF", "#92FE9D"],
            gradientDirection: .bottomLeadingToTopTrailing
        ),
        WallpaperItem(
            id: "grad-violet",
            name: "Cosmic Violet",
            category: .gradient,
            colorsHex: ["#8A2387", "#E94057"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-midnight",
            name: "Midnight Cyber",
            category: .gradient,
            colorsHex: ["#0F2027", "#203A43", "#2C5364"],
            gradientDirection: .topToBottom
        ),
        WallpaperItem(
            id: "grad-ocean",
            name: "Ocean Abyss",
            category: .gradient,
            colorsHex: ["#1A2980", "#26D0CE"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-solar",
            name: "Solar Glow",
            category: .gradient,
            colorsHex: ["#F37335", "#FDC830"],
            gradientDirection: .leadingToTrailing
        ),
        WallpaperItem(
            id: "grad-emerald",
            name: "Emerald Dream",
            category: .gradient,
            colorsHex: ["#11998E", "#38EF7D"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-blossom",
            name: "Neon Blossom",
            category: .gradient,
            colorsHex: ["#FF0844", "#FFB199"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-titanium",
            name: "Dark Titanium",
            category: .gradient,
            colorsHex: ["#232526", "#414345"],
            gradientDirection: .topToBottom
        ),
        WallpaperItem(
            id: "grad-royal",
            name: "Royal Indigo",
            category: .gradient,
            colorsHex: ["#4A00E0", "#8E2DE2"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-lavender",
            name: "Electric Lavender",
            category: .gradient,
            colorsHex: ["#7F00FF", "#E100FF"],
            gradientDirection: .diagonal
        ),
        WallpaperItem(
            id: "grad-golden",
            name: "Golden Hour",
            category: .gradient,
            colorsHex: ["#F2994A", "#F2C94C"],
            gradientDirection: .topToBottom
        ),

        // SOLID & OLED MINIMALIST GLASS
        WallpaperItem(
            id: "solid-oled",
            name: "True OLED Obsidian",
            category: .solid,
            colorsHex: ["#000000"]
        ),
        WallpaperItem(
            id: "solid-slate",
            name: "Deep Slate",
            category: .solid,
            colorsHex: ["#0E1117"]
        ),
        WallpaperItem(
            id: "solid-navy",
            name: "Midnight Navy",
            category: .solid,
            colorsHex: ["#0A1128"]
        ),
        WallpaperItem(
            id: "solid-graphite",
            name: "Graphite Studio",
            category: .solid,
            colorsHex: ["#18191C"]
        ),
        WallpaperItem(
            id: "solid-emerald",
            name: "Pine Noir",
            category: .solid,
            colorsHex: ["#091E15"]
        ),
        WallpaperItem(
            id: "solid-crimson",
            name: "Crimson Eclipse",
            category: .solid,
            colorsHex: ["#1C0B12"]
        )
    ]
}

// MARK: - 3. PHOTO LIBRARY SAVER ENGINE

@MainActor
public final class PhotoLibrarySaver: NSObject, ObservableObject {
    public static let shared = PhotoLibrarySaver()

    @Published public var isSaving: Bool = false
    @Published public var showSuccessToast: Bool = false
    @Published public var errorMessage: String? = nil

    public func save(image: UIImage) {
        isSaving = true
        errorMessage = nil

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch status {
                case .authorized, .limited:
                    self.performSave(image: image)
                case .denied, .restricted:
                    self.isSaving = false
                    self.errorMessage = "Photos access is restricted. Enable permission in Settings > Widget Studio iOS."
                case .notDetermined:
                    self.isSaving = false
                @unknown default:
                    self.isSaving = false
                }
            }
        }
    }

    private func performSave(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false
                if success {
                    self.showSuccessToast = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.showSuccessToast = false
                    }
                } else {
                    self.errorMessage = error?.localizedDescription ?? "Could not save photo to camera roll."
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - 4. HIGH-RESOLUTION WALLPAPER CANVAS RENDERER

/// Renders a given wallpaper item at any size or aspect ratio
public struct WallpaperRenderView: View {
    public let colorsHex: [String]
    public let mode: WallpaperStyleType
    public let gradientDirection: WidgetGradientDirection
    public let meshPointsOffset: CGFloat
    public let showLiquidSheen: Bool
    public let showVignette: Bool

    public init(
        colorsHex: [String],
        mode: WallpaperStyleType,
        gradientDirection: WidgetGradientDirection = .diagonal,
        meshPointsOffset: CGFloat = 0.0,
        showLiquidSheen: Bool = false,
        showVignette: Bool = false
    ) {
        self.colorsHex = colorsHex
        self.mode = mode
        self.gradientDirection = gradientDirection
        self.meshPointsOffset = meshPointsOffset
        self.showLiquidSheen = showLiquidSheen
        self.showVignette = showVignette
    }

    public var body: some View {
        ZStack {
            baseColorOrGradient

            if showLiquidSheen {
                liquidGlassSheenOverlay
            }

            if showVignette {
                vignetteOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var baseColorOrGradient: some View {
        switch mode {
        case .mesh:
            let colors = (0..<9).map { idx -> Color in
                if idx < colorsHex.count {
                    return Color(hex: colorsHex[idx])
                }
                return Color(hex: "#1A1A2E")
            }

            let off = Float(meshPointsOffset)
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5 + off * 0.1), .init(0.5 + off * 0.15, 0.5), .init(1, 0.5 - off * 0.1),
                    .init(0, 1), .init(0.5, 1), .init(1, 1)
                ],
                colors: colors
            )
            .background(colors.count > 4 ? colors[4] : Color.purple)

        case .gradient:
            let colors = colorsHex.map { Color(hex: $0) }
            LinearGradient(
                colors: colors.isEmpty ? [.black, .purple] : colors,
                startPoint: gradientDirection.startPoint,
                endPoint: gradientDirection.endPoint
            )

        case .solid:
            Color(hex: colorsHex.first ?? "#0E1117")
        }
    }

    private var liquidGlassSheenOverlay: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Color.white.opacity(0.04),
                Color.clear,
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.12),
                Color.black.opacity(0.45)
            ],
            center: .center,
            startRadius: 80,
            endRadius: 600
        )
    }
}

// MARK: - 5. MAIN WALLPAPER STUDIO VIEW

public struct WallpaperStudioView: View {
    @StateObject private var saver = PhotoLibrarySaver.shared
    @Environment(\.openURL) private var openURL

    // Navigation segmented section
    public enum StudioSection: String, CaseIterable, Identifiable {
        case curated = "Curated Wallpapers"
        case creator = "Studio Creator"

        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .curated: return "sparkles.rectangle.stack.fill"
            case .creator: return "paintpalette.fill"
            }
        }
    }

    @State private var activeSection: StudioSection = .curated
    @State private var selectedDevice: WallpaperDevice = .iPhone
    @State private var curatedFilter: WallpaperStyleType? = nil // nil means all

    // Studio Creator custom state
    @State private var creatorMode: WallpaperStyleType = .mesh
    @State private var creatorGradientDirection: WidgetGradientDirection = .diagonal
    @State private var creatorMeshColorsHex: [String] = WidgetMeshPreset.cyberpunk.defaultColorsHex
    @State private var creatorGradientStopsHex: [String] = ["#8A2387", "#E94057", "#F27121"]
    @State private var creatorSolidHex: String = "#0E1117"
    @State private var creatorMeshTurbulence: CGFloat = 0.0
    @State private var creatorLiquidSheen: Bool = true
    @State private var creatorVignette: Bool = false

    // Preview Sheet
    @State private var previewItem: WallpaperItem? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top device selector & section switcher
                topControlBar

                // Content instance
                ScrollView {
                    VStack(spacing: 24) {
                        if activeSection == .curated {
                            curatedWallpapersInstance
                        } else {
                            studioCreatorInstance
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Wallpaper Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $previewItem) { item in
                WallpaperFullscreenPreviewModal(
                    item: item,
                    device: selectedDevice,
                    meshTurbulence: item.category == .mesh ? creatorMeshTurbulence : 0.0,
                    liquidSheen: creatorLiquidSheen,
                    vignette: creatorVignette
                )
            }
            .overlay(alignment: .top) {
                if saver.showSuccessToast {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                        Text("Wallpaper saved to Photos in Ultra-HD!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .alert("Photos Access", isPresented: Binding(
                get: { saver.errorMessage != nil },
                set: { if !$0 { saver.errorMessage = nil } }
            )) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(saver.errorMessage ?? "")
            }
        }
    }

    // MARK: - Top Bar

    private var topControlBar: some View {
        VStack(spacing: 12) {
            // Section Switcher
            Picker("Mode", selection: $activeSection) {
                ForEach(StudioSection.allCases) { section in
                    Label(section.rawValue, systemImage: section.icon).tag(section)
                }
            }
            .pickerStyle(.segmented)

            // Target Device Resolution Switcher
            HStack(spacing: 12) {
                Text("Target Device:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(WallpaperDevice.allCases) { device in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDevice = device
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: device.icon)
                                    .font(.caption2)
                                Text(device.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedDevice == device ? Color.blue : Color.primary.opacity(0.06),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedDevice == device ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Instance 1: Curated Wallpapers

    private var curatedWallpapersInstance: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Resolution Badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Matching Widget Backgrounds")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Pre-crafted mesh, gradient, and solid textures styled for \(selectedDevice.rawValue) (\(selectedDevice.subtitle))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterPill(title: "All", isSelected: curatedFilter == nil) {
                        curatedFilter = nil
                    }
                    ForEach(WallpaperStyleType.allCases) { style in
                        filterPill(title: style.rawValue, isSelected: curatedFilter == style) {
                            curatedFilter = style
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            // Grid of Curated Cards
            let filteredItems = CuratedWallpapersData.all.filter {
                curatedFilter == nil || $0.category == curatedFilter
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 16
            ) {
                ForEach(filteredItems) { item in
                    curatedWallpaperCard(item: item)
                }
            }
        }
    }

    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.primary : Color.primary.opacity(0.06),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func curatedWallpaperCard(item: WallpaperItem) -> some View {
        Button {
            previewItem = item
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Device Mockup Container
                ZStack {
                    WallpaperRenderView(
                        colorsHex: item.colorsHex,
                        mode: item.category,
                        gradientDirection: item.gradientDirection ?? .diagonal,
                        meshPointsOffset: 0.0,
                        showLiquidSheen: true,
                        showVignette: false
                    )

                    // Subtle inner bezel
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)

                    // Quick Tap to Preview Overlay
                    VStack {
                        Spacer()
                        HStack {
                            Text(item.category.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                            Spacer()
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                    }
                }
                .aspectRatio(selectedDevice.aspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Instance 2: Studio Creator

    private var studioCreatorInstance: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interactive Studio Creator")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Craft custom harmonic mesh and gradient canvases exported in high quality for \(selectedDevice.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Live Interactive Preview Canvas
            ZStack {
                WallpaperRenderView(
                    colorsHex: creatorColorsHex,
                    mode: creatorMode,
                    gradientDirection: creatorGradientDirection,
                    meshPointsOffset: creatorMeshTurbulence,
                    showLiquidSheen: creatorLiquidSheen,
                    showVignette: creatorVignette
                )

                // Bezel stroke
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)

                // Top Floating Action Button (Expand / Preview)
                VStack {
                    HStack {
                        Label(selectedDevice.rawValue, systemImage: selectedDevice.icon)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            previewItem = WallpaperItem(
                                id: UUID().uuidString,
                                name: "Custom \(creatorMode.rawValue)",
                                category: creatorMode,
                                colorsHex: creatorColorsHex,
                                gradientDirection: creatorGradientDirection
                            )
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(14)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(selectedDevice.aspectRatio, contentMode: .fit)
            .frame(maxHeight: 380)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 14, y: 6)

            // Creator Mode Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Wallpaper Type")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Picker("Style", selection: $creatorMode) {
                    ForEach(WallpaperStyleType.allCases) { style in
                        Label(style.rawValue, systemImage: style.icon).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Type-Specific Studio Controls
            if creatorMode == .mesh {
                meshCreatorControls
            } else if creatorMode == .gradient {
                gradientCreatorControls
            } else {
                solidCreatorControls
            }

            // Texture & Optical Overlays
            opticalOverlaysSection

            // Export Direct Actions
            VStack(spacing: 10) {
                Button {
                    exportAndSaveCustomWallpaper()
                } label: {
                    HStack(spacing: 10) {
                        if saver.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.headline)
                        }
                        Text(saver.isSaving ? "Rendering in Ultra-HD..." : "Save High-Res to Photos (\(selectedDevice.rawValue))")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                }
                .disabled(saver.isSaving)

                Button {
                    previewItem = WallpaperItem(
                        id: UUID().uuidString,
                        name: "Custom \(creatorMode.rawValue)",
                        category: creatorMode,
                        colorsHex: creatorColorsHex,
                        gradientDirection: creatorGradientDirection
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("Open Fullscreen Mockup Preview")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var creatorColorsHex: [String] {
        switch creatorMode {
        case .mesh: return creatorMeshColorsHex
        case .gradient: return creatorGradientStopsHex
        case .solid: return [creatorSolidHex]
        }
    }

    // MARK: - Mesh Creator Controls

    private var meshCreatorControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Mesh Nodes (3×3 Grid)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    randomizeMeshPalette()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dice.fill")
                        Text("Harmonic Shuffle")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
                }
            }

            // 3x3 Color Pickers Matrix
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            meshColorNodeButton(index: index)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Turbulence / Curvature Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Mesh Point Curvature")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "%.1f", creatorMeshTurbulence))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $creatorMeshTurbulence, in: -1.0...1.0)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func meshColorNodeButton(index: Int) -> some View {
        let currentColor = Color(hex: index < creatorMeshColorsHex.count ? creatorMeshColorsHex[index] : "#1A1A2E")

        return ColorPicker("", selection: Binding(
            get: { currentColor },
            set: { newColor in
                if index < creatorMeshColorsHex.count {
                    creatorMeshColorsHex[index] = newColor.toHex()
                }
            }
        ))
        .labelsHidden()
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(currentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    private func randomizeMeshPalette() {
        let palettes: [[String]] = [
            ["#FF007F", "#7928CA", "#0070F3", "#00DFD8", "#7928CA", "#FF007F", "#0070F3", "#00DFD8", "#1A1A2E"],
            ["#FF4E50", "#F9D423", "#FF6B6B", "#7928CA", "#FF8E53", "#FE6B8B", "#2B0938", "#C33764", "#1D2671"],
            ["#0575E6", "#00F260", "#0575E6", "#00F260", "#11998E", "#38EF7D", "#0F2027", "#203A43", "#2C5364"],
            ["#3A1C71", "#D76D77", "#FFAF7B", "#8A2387", "#4A00E0", "#E94057", "#0F2027", "#2C5364", "#120E43"],
            ["#0D0D11", "#1E1E28", "#121217", "#2C2C3E", "#15151E", "#32324A", "#0A0A0E", "#181822", "#0F0F14"]
        ]
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            creatorMeshColorsHex = palettes.randomElement() ?? palettes[0]
            creatorMeshTurbulence = CGFloat.random(in: -0.6...0.6)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Gradient Creator Controls

    private var gradientCreatorControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gradient Stops & Direction")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Stops pickers
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(0..<creatorGradientStopsHex.count, id: \.self) { idx in
                        VStack(spacing: 4) {
                            Text("Stop \(idx + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ColorPicker("", selection: Binding(
                                get: { Color(hex: creatorGradientStopsHex[idx]) },
                                set: { creatorGradientStopsHex[idx] = $0.toHex() }
                            ))
                            .labelsHidden()
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(Color(hex: creatorGradientStopsHex[idx]), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                        }
                    }
                }

                HStack {
                    if creatorGradientStopsHex.count < 4 {
                        Button {
                            withAnimation {
                                creatorGradientStopsHex.append("#00F260")
                            }
                        } label: {
                            Label("Add Stop", systemImage: "plus.circle.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()

                    if creatorGradientStopsHex.count > 2 {
                        Button(role: .destructive) {
                            withAnimation {
                                _ = creatorGradientStopsHex.popLast()
                            }
                        } label: {
                            Label("Remove Stop", systemImage: "minus.circle.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Direction Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Direction Angle")
                    .font(.caption)
                    .fontWeight(.semibold)

                Picker("Direction", selection: $creatorGradientDirection) {
                    ForEach(WidgetGradientDirection.allCases) { dir in
                        Text(dir.rawValue).tag(dir)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Solid Creator Controls

    private var solidCreatorControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Solid Tint")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            HStack {
                Text("Select Base Color")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                ColorPicker("", selection: Binding(
                    get: { Color(hex: creatorSolidHex) },
                    set: { creatorSolidHex = $0.toHex() }
                ))
                .labelsHidden()
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Optical Overlays

    private var opticalOverlaysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Atmospheric Overlays")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Toggle(isOn: $creatorLiquidSheen) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liquid Glass Sheen")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Adds subtle diagonal glass reflections")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                Toggle(isOn: $creatorVignette) {
                    HStack(spacing: 10) {
                        Image(systemName: "circle.circle")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("OLED Vignette Focus")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Darkens outer perimeter for icon contrast")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Export Logic

    private func exportAndSaveCustomWallpaper() {
        let renderView = WallpaperRenderView(
            colorsHex: creatorColorsHex,
            mode: creatorMode,
            gradientDirection: creatorGradientDirection,
            meshPointsOffset: creatorMeshTurbulence,
            showLiquidSheen: creatorLiquidSheen,
            showVignette: creatorVignette
        )

        let targetSize = selectedDevice.pixelSize
        if let highResImage = WallpaperExportEngine.render(view: renderView, size: targetSize) {
            saver.save(image: highResImage)
        }
    }
}

// MARK: - 6. FULLSCREEN INTERACTIVE PREVIEW & EXPORT MODAL

public struct WallpaperFullscreenPreviewModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var saver = PhotoLibrarySaver.shared
    @Environment(\.openURL) private var openURL

    public let item: WallpaperItem
    public let device: WallpaperDevice
    public let meshTurbulence: CGFloat
    public let liquidSheen: Bool
    public let vignette: Bool

    // Preview Toggles
    @State private var showMockHomeElements: Bool = true
    @State private var showMockWidgets: Bool = true

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background base
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                // Fullscreen Wallpaper Canvas
                WallpaperRenderView(
                    colorsHex: item.colorsHex,
                    mode: item.category,
                    gradientDirection: item.gradientDirection ?? .diagonal,
                    meshPointsOffset: meshTurbulence,
                    showLiquidSheen: liquidSheen,
                    showVignette: vignette
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                // Mock iOS Home Screen Overlay (Live Clock, Widgets, App Grid)
                if showMockHomeElements {
                    mockHomeScreenOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.headline)
                            Text("Done")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        // Toggle Mock UI
                        Button {
                            withAnimation {
                                showMockHomeElements.toggle()
                            }
                        } label: {
                            Image(systemName: showMockHomeElements ? "eye.fill" : "eye.slash.fill")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }

                        // Save Button
                        Button {
                            saveHighRes()
                        } label: {
                            if saver.isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue, in: Capsule())
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Save HD")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.blue, in: Capsule())
                                .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                bottomBar
            }
        }
    }

    private var mockHomeScreenOverlay: some View {
        VStack(spacing: 16) {
            // Lock Screen / Top Clock Mockup
            VStack(spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 1)

                Text(Date().formatted(.dateTime.hour().minute()))
                    .font(.system(size: 76, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
            }
            .padding(.top, 40)

            Spacer()

            // Floating Mock Liquid Glass Widget Preview
            if showMockWidgets {
                HStack(spacing: 14) {
                    mockWidgetGlassCard(title: "CALENDAR", subtitle: "Team Sync", icon: "calendar")
                    mockWidgetGlassCard(title: "HEALTH", subtitle: "9,420 Steps", icon: "flame.fill")
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Bottom Home Bar Indicator
            Capsule()
                .fill(Color.white.opacity(0.6))
                .frame(width: 134, height: 5)
                .padding(.bottom, 80)
        }
    }

    private func mockWidgetGlassCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            Text(subtitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("\(device.rawValue) • \(device.subtitle)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button {
                saveHighRes()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.to.line.compact")
                    Text("Save to Photos")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white, in: Capsule())
                .foregroundStyle(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func saveHighRes() {
        let renderView = WallpaperRenderView(
            colorsHex: item.colorsHex,
            mode: item.category,
            gradientDirection: item.gradientDirection ?? .diagonal,
            meshPointsOffset: meshTurbulence,
            showLiquidSheen: liquidSheen,
            showVignette: vignette
        )

        let targetSize = device.pixelSize
        if let highRes = WallpaperExportEngine.render(view: renderView, size: targetSize) {
            saver.save(image: highRes)
        }
    }
}

// MARK: - 7. HIGH-RESOLUTION EXPORT ENGINE

@MainActor
public enum WallpaperExportEngine {
    /// Renders any SwiftUI view into an exact high-resolution UIImage
    public static func render<Content: View>(view: Content, size: CGSize) -> UIImage? {
        let controller = UIHostingController(
            rootView: view
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
        )

        guard let targetView = controller.view else { return nil }

        targetView.bounds = CGRect(origin: .zero, size: size)
        targetView.backgroundColor = .clear

        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1.0 // 1.0 because size is already in true hardware pixels

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        return renderer.image { _ in
            targetView.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}
