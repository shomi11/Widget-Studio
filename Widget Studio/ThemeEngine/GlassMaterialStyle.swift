import SwiftUI

/// Defines the Liquid Glass material presets conforming to Apple's Liquid Glass design language.
public enum GlassMaterialStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case ultraClear = "Ultra Clear"
    case tintedGlass = "Tinted Glass"
    case blackGlass = "Black Glass"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ultraClear: return "Clear"
        case .tintedGlass: return "Tinted"
        case .blackGlass: return "Dark"
        }
    }

    public var systemIcon: String {
        switch self {
        case .ultraClear:
            return "sparkles"
        case .tintedGlass:
            return "paintpalette.fill"
        case .blackGlass:
            return "moon.stars.fill"
        }
    }

    public var description: String {
        switch self {
        case .ultraClear:
            return "Highly translucent optical glass prioritizing background fidelity."
        case .tintedGlass:
            return "Infused stained glass with dynamic chromatic refraction."
        case .blackGlass:
            return "Obsidian smoked glass with high-contrast specular edge sheen."
        }
    }

    /// Primary background overlay tint
    public func baseOverlay(tint: Color) -> Color {
        switch self {
        case .ultraClear:
            return Color.white.opacity(0.08)
        case .tintedGlass:
            return tint.opacity(0.32)
        case .blackGlass:
            return Color.black.opacity(0.78)
        }
    }

    /// Dimming underlayer to maintain legibility per Apple HIG
    public var dimmingOpacity: Double {
        switch self {
        case .ultraClear:
            return 0.35 // Apple HIG: 35% dark dimming layer for clear glass
        case .tintedGlass:
            return 0.20
        case .blackGlass:
            return 0.50
        }
    }

    /// Specular rim highlight opacity
    public var rimHighlightOpacity: Double {
        switch self {
        case .ultraClear:
            return 0.65
        case .tintedGlass:
            return 0.85
        case .blackGlass:
            return 0.95
        }
    }

    /// Default blur radius for dynamic refraction
    public var defaultBlurRadius: CGFloat {
        switch self {
        case .ultraClear:
            return 16.0
        case .tintedGlass:
            return 24.0
        case .blackGlass:
            return 32.0
        }
    }
}
