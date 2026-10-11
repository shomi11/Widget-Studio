import SwiftUI

/// Tab identifier conforming to standard navigation hierarchy
public enum AppTab: String, CaseIterable, Identifiable {
    case widgets = "Widgets"
    case gallery = "Gallery"
    case wallpapers = "Wallpapers"
    case opticsLab = "Optics Lab"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .widgets: return "square.grid.2x2.fill"
        case .gallery: return "sparkles.rectangle.stack.fill"
        case .wallpapers: return "paintpalette.fill"
        case .opticsLab: return "eyedropper.halffull"
        }
    }
}

/// Root application view implementing Apple's native sidebar-adaptable TabView,
/// seamlessly adapting between a bottom Tab Bar on iPhone and an integrated top bar / sidebar on iPad
/// adhering strictly to Apple Human Interface Guidelines and modern SwiftUI specifications.
public struct MainTabView: View {
    @StateObject private var store = WidgetStore.shared
    @State private var selectedTab: AppTab = .widgets
    @AppStorage("mainTabViewCustomization") private var tabCustomization: TabViewCustomization

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.widgets.rawValue, systemImage: AppTab.widgets.icon, value: .widgets) {
                DashboardView(store: store)
            }
            .customizationID("com.liquidglass.tab.widgets")

            Tab(AppTab.gallery.rawValue, systemImage: AppTab.gallery.icon, value: .gallery) {
                PresetGalleryView(store: store)
            }
            .customizationID("com.liquidglass.tab.gallery")

            Tab(AppTab.wallpapers.rawValue, systemImage: AppTab.wallpapers.icon, value: .wallpapers) {
                WallpaperStudioView()
            }
            .customizationID("com.liquidglass.tab.wallpapers")

            Tab(AppTab.opticsLab.rawValue, systemImage: AppTab.opticsLab.icon, value: .opticsLab) {
                GlassLabView()
            }
            .customizationID("com.liquidglass.tab.opticsLab")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewCustomization($tabCustomization)
        .tabViewSidebarHeader {
            sidebarBrandingHeader
        }
        .tabViewSidebarBottomBar {
            sidebarBottomTelemetryBar
        }
    }

    // MARK: - iPad Sidebar Header
    private var sidebarBrandingHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Liquid Glass")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Architectural Widget Studio")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - iPad Sidebar Bottom Bar
    private var sidebarBottomTelemetryBar: some View {
        HStack {
            Label("\(store.widgets.count) Widgets Active", systemImage: "square.stack.3d.up.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Live")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
