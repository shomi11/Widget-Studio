import Foundation
import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Glass Note data model
public struct GlassNoteItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var content: String
    public var isPinned: Bool
    public var dateUpdated: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        isPinned: Bool = true,
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.dateUpdated = dateUpdated
    }
}

/// Service managing Notes integration and deep links to Apple Notes
@MainActor
public final class NotesService: ObservableObject {
    public static let shared = NotesService()

    @Published public var notes: [GlassNoteItem] = []

    public init() {
        notes = [
            GlassNoteItem(
                title: "Product Design Ideas",
                content: "1. Refractive dynamic materials\n2. Liquid Glass widget layers\n3. Haptic dial controls",
                isPinned: true
            ),
            GlassNoteItem(
                title: "Daily Reflections",
                content: "Water shapes itself to the vessel, yet cuts through stone.",
                isPinned: true
            ),
            GlassNoteItem(
                title: "Grocery Essentials",
                content: "• Matcha powder\n• Oat milk\n• Fresh berries",
                isPinned: false
            )
        ]
    }

    /// Primary pinned note for widget display
    public var activeNote: GlassNoteItem? {
        notes.first(where: { $0.isPinned }) ?? notes.first
    }

    /// Deep links directly to the Apple Notes native app safely across app and extension contexts
    public func openAppleNotesApp() {
        guard let url = URL(string: "mobilenotes://") else { return }
        #if canImport(UIKit)
        if let sharedApp = UIApplication.value(forKeyPath: "sharedApplication") as? AnyObject {
            _ = sharedApp.perform(NSSelectorFromString("openURL:"), with: url)
        }
        #endif
    }

    /// Updates or adds a note
    public func saveNote(title: String, content: String) {
        let note = GlassNoteItem(title: title, content: content, isPinned: true)
        notes.insert(note, at: 0)
    }
}
