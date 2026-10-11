import SwiftUI

/// App settings: data access, Home Screen help, and maintenance.
public struct SettingsView: View {
    @ObservedObject var store: WidgetStore
    @ObservedObject var permissionManager = CategoryPermissionManager.shared
    @Environment(\.openURL) private var openURL

    @State private var confirmsRestore = false
    @State private var requestingCategory: WidgetCategory? = nil

    /// Categories backed by a system permission.
    private let permissionCategories: [WidgetCategory] = [.health, .calendar, .reminders, .alarms]

    public init(store: WidgetStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(permissionCategories) { category in
                        LabeledContent {
                            accessControl(for: category)
                        } label: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } header: {
                    Text("Data Access")
                } footer: {
                    Text("Widgets show sample data until you allow access.")
                }

                Section {
                    Label("Touch and hold an empty area of your Home Screen.", systemImage: "1.circle")
                    Label("Tap Edit, then Add Widget.", systemImage: "2.circle")
                    Label("Search for Widget Studio and choose a size.", systemImage: "3.circle")
                } header: {
                    Text("Add to Home Screen")
                } footer: {
                    Text("Each size shows the widget you set as active for it.")
                }

                Section {
                    Button("Restore Default Widgets", role: .destructive) {
                        confirmsRestore = true
                    }
                }

                #if DEBUG
                Section("Developer") {
                    NavigationLink("Optics Lab") {
                        GlassLabView()
                    }
                }
                #endif

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Restore default widgets?",
                isPresented: $confirmsRestore,
                titleVisibility: .visible
            ) {
                Button("Restore", role: .destructive) {
                    store.resetToDefaults()
                }
            } message: {
                Text("Your current widgets will be replaced.")
            }
        }
    }

    @ViewBuilder
    private func accessControl(for category: WidgetCategory) -> some View {
        switch permissionManager.status(for: category) {
        case .authorized, .notRequired:
            Text("Allowed")
        case .denied:
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
        case .notDetermined:
            if requestingCategory == category {
                ProgressView()
            } else {
                Button("Allow") {
                    requestingCategory = category
                    Task {
                        await permissionManager.requestPermission(for: category)
                        requestingCategory = nil
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
