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
                title: "Weekend plans",
                content: "Farmers market in the morning, then a bike ride along the river.",
                isPinned: true
            ),
            GlassNoteItem(
                title: "Book list",
                content: "• The Overstory\n• Piranesi\n• Project Hail Mary",
                isPinned: true
            ),
            GlassNoteItem(
                title: "Groceries",
                content: "• Oat milk\n• Berries\n• Bread",
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
