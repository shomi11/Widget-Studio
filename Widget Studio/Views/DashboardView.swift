import SwiftUI

/// The user's widgets, grouped by category.
public struct DashboardView: View {
    @ObservedObject var store: WidgetStore
    @ObservedObject var permissionManager = CategoryPermissionManager.shared

    @State private var categoryFilter: WidgetCategory? = nil
    @State private var editorRequest: EditorRequest? = nil

    public init(store: WidgetStore) {
        self.store = store
    }

    private var sections: [(category: WidgetCategory, widgets: [WidgetConfig])] {
        let visible = store.widgets.filter { $0.size.isAvailableOnCurrentDevice }
        return WidgetCategory.allCases.compactMap { category in
            guard categoryFilter == nil || categoryFilter == category else { return nil }
            let widgets = visible.filter { $0.category == category }
            return widgets.isEmpty ? nil : (category, widgets)
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.category) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.widgets) { widget in
                            widgetRow(widget)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .headerProminence(.increased)
            .scrollEdgeEffectStyle(.soft, for: .all)
            .contentMargins(.bottom, 24, for: .scrollContent)
            .overlay {
                if sections.isEmpty {
                    emptyState
                }
            }
            .navigationTitle("Widget Studio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                }
            }
            .sheet(item: $editorRequest) { request in
                WidgetEditorView(widget: request.widget, isNew: request.isNew, store: store)
            }
        }
    }

    // MARK: - Row

    private func widgetRow(_ widget: WidgetConfig) -> some View {
        let isActive = store.isActiveHomeWidget(widget)

        return Button {
            editorRequest = EditorRequest(widget: widget, isNew: false)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                WidgetPreview(widget: widget)
                    .accessibilityHidden(true)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(widget.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitle(for: widget))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Active")
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityHint("Opens the editor")
        .contextMenu {
            Button {
                store.setActiveHomeWidget(widget)
            } label: {
                Label("Set as Active", systemImage: "checkmark.circle")
            }
            .disabled(isActive)

            Button {
                editorRequest = EditorRequest(widget: widget, isNew: false)
            } label: {
                Label("Edit", systemImage: "slider.horizontal.3")
            }

            Button {
                store.duplicate(widget: widget)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Divider()

            Button(role: .destructive) {
                store.delete(id: widget.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            if !isActive {
                Button {
                    store.setActiveHomeWidget(widget)
                } label: {
                    Label("Set as Active", systemImage: "checkmark.circle")
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.delete(id: widget.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func subtitle(for widget: WidgetConfig) -> String {
        var parts = [widget.size.rawValue, widget.type.displayName]
        if !permissionManager.isAuthorized(for: widget.category) {
            parts.append("Sample data")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Toolbar

    private var filterMenu: some View {
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

    private var addMenu: some View {
        Menu {
            Section("New Widget") {
                ForEach(WidgetCategory.allCases) { category in
                    Button {
                        editorRequest = EditorRequest(widget: .newWidget(for: category), isNew: true)
                    } label: {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            }
        } label: {
            Label("Add Widget", systemImage: "plus")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Widgets", systemImage: "square.grid.2x2")
        } description: {
            Text(categoryFilter == nil
                 ? "Add a widget, or pick one from the Gallery."
                 : "You don’t have any \(categoryFilter?.rawValue ?? "") widgets yet.")
        } actions: {
            if let category = categoryFilter {
                Button("Add \(category.rawValue) Widget") {
                    editorRequest = EditorRequest(widget: .newWidget(for: category), isNew: true)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// A widget to open in the editor, either existing or new.
struct EditorRequest: Identifiable {
    let id = UUID()
    let widget: WidgetConfig
    let isNew: Bool
}

extension WidgetConfig {
    /// A starting configuration for a new widget in `category`.
    static func newWidget(for category: WidgetCategory) -> WidgetConfig {
        WidgetConfig(
            name: "New \(category.rawValue) Widget",
            size: .medium,
            type: category.widgetTypes.first ?? .stepActivity,
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
    }
}
