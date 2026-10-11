import SwiftUI

/// Tab identifier conforming to standard navigation hierarchy
public enum AppTab: String, CaseIterable, Identifiable {
    case widgets = "Widgets"
    case gallery = "Gallery"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .widgets: return "square.grid.2x2"
        case .gallery: return "square.stack"
        case .settings: return "gear"
        }
    }
}

/// Root view: a sidebar-adaptable TabView (tab bar on iPhone, sidebar on iPad).
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

            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.icon, value: .settings) {
                SettingsView(store: store)
            }
            .customizationID("com.liquidglass.tab.settings")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabCustomization)
    }
}
