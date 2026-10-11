import SwiftUI

/// Multi-layered Liquid Glass modifier conforming to Apple HIG.
/// Combines native system Glass effects with dynamic refraction, motion-reactive specular highlights,
/// and fluid drop-like edge sheen.
public struct LiquidGlassModifier: ViewModifier {
    public let style: GlassMaterialStyle
    public let tint: Color
    public let cornerRadius: CGFloat
    public let blurRadius: CGFloat
    public let motionReactive: Bool
    public let specularIntensity: Double
    public let showEdgeShine: Bool

    @ObservedObject private var motion = MotionManager.shared
    @State private var isHovered: Bool = false

    public init(
        style: GlassMaterialStyle = .ultraClear,
        tint: Color = .blue,
        cornerRadius: CGFloat = 26.0,
        blurRadius: CGFloat? = nil,
        motionReactive: Bool = true,
        specularIntensity: Double = 0.8,
        showEdgeShine: Bool = true
    ) {
        self.style = style
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.blurRadius = blurRadius ?? style.defaultBlurRadius
        self.motionReactive = motionReactive
        self.specularIntensity = specularIntensity
        self.showEdgeShine = showEdgeShine
    }

    public func body(content: Content) -> some View {
        let offset = motionReactive ? motion.normalizedOffset : .zero
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            if motionReactive {
                content
                    .glassEffect(style == .ultraClear ? .clear : .regular, in: shape)
                    .background {
                        glassBackgroundLayers(shape: shape, offset: offset)
                    }
            } else {
                // WidgetKit-safe rendering: Pure SpringBoard-safe materials guaranteed to render without freezing
                content
                    .background {
                        glassBackgroundLayers(shape: shape, offset: offset)
                    }
            }
        }
        .clipShape(shape)
        .shadow(
            color: style == .blackGlass ? Color.black.opacity(0.4) : tint.opacity(0.18),
            radius: 18,
            x: offset.width * 4,
            y: 10 + offset.height * 4
        )
    }

    @ViewBuilder
    private func glassBackgroundLayers(shape: RoundedRectangle, offset: CGSize) -> some View {
        ZStack {
            // 1. HIG Dimming Underlayer for legibility over bright wallpapers
            shape
                .fill(style == .blackGlass ? Color.black.opacity(0.85) : Color.black.opacity(style.dimmingOpacity * 0.75))

            // 2. Base Optical Refraction Layer with Material
            shape
                .fill(style.baseOverlay(tint: tint))
                .blur(radius: blurRadius * 0.1)

            // 3. Dynamic Motion-Reactive Specular Glare (Fluid drop highlight)
            if specularIntensity > 0 {
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.35 * specularIntensity),
                                Color.white.opacity(0.10 * specularIntensity),
                                Color.clear
                            ],
                            center: UnitPoint(
                                x: 0.35 + offset.width * 0.25,
                                y: 0.25 + offset.height * 0.25
                            ),
                            startRadius: 8,
                            endRadius: 180
                        )
                    )
                    .blendMode(.screen)
            }

            // 4. Perimeter Liquid Rim Highlight (Specular edge refraction)
            if showEdgeShine {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                tint.opacity(0.65),
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: UnitPoint(
                                x: 0.2 + offset.width * 0.3,
                                y: 0.1 + offset.height * 0.3
                            ),
                            endPoint: UnitPoint(
                                x: 0.8 - offset.width * 0.3,
                                y: 0.9 - offset.height * 0.3
                            )
                        ),
                        lineWidth: 1.5
                    )
            }
        }
    }
}

// MARK: - Comprehensive Widget Surface & Customizable Background Renderer

/// Dynamic background layer supporting Liquid Glass, Solid Colors, Linear/Radial Gradients, and Mesh Gradients
public struct WidgetBackgroundView: View {
    public let config: WidgetConfig
    public let cornerRadius: CGFloat
    public let isInteractivePreview: Bool

    @ObservedObject private var motion = MotionManager.shared

    public init(config: WidgetConfig, cornerRadius: CGFloat, isInteractivePreview: Bool = false) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.isInteractivePreview = isInteractivePreview
    }

    public var body: some View {
        let offset = isInteractivePreview ? motion.normalizedOffset : .zero
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            // 1. Base Surface Fill
            baseSurfaceLayer
                .opacity(config.backgroundOpacity)

            // 2. Liquid Glass Specular Glare Overcoat (if enabled)
            if config.glassOverlayEnabled && config.specularIntensity > 0 {
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.35 * config.specularIntensity),
                                Color.white.opacity(0.10 * config.specularIntensity),
                                Color.clear
                            ],
                            center: UnitPoint(
                                x: 0.35 + offset.width * 0.25,
                                y: 0.25 + offset.height * 0.25
                            ),
                            startRadius: 8,
                            endRadius: 180
                        )
                    )
                    .blendMode(.screen)
            }

            // 3. Liquid Rim Highlight (Specular edge refraction)
            if config.showEdgeShine {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                config.tintColor.opacity(0.65),
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: UnitPoint(
                                x: 0.2 + offset.width * 0.3,
                                y: 0.1 + offset.height * 0.3
                            ),
                            endPoint: UnitPoint(
                                x: 0.8 - offset.width * 0.3,
                                y: 0.9 - offset.height * 0.3
                            )
                        ),
                        lineWidth: 1.5
                    )
            }
        }
        .clipShape(shape)
    }

    @ViewBuilder
    private var baseSurfaceLayer: some View {
        switch config.backgroundMode {
        case .liquidGlass:
            ZStack {
                Color.black.opacity(config.glassStyle == .blackGlass ? 0.85 : config.glassStyle.dimmingOpacity * 0.75)
                config.glassStyle.baseOverlay(tint: config.tintColor)
                    .blur(radius: config.blurRadius * 0.1)
            }

        case .solidColor:
            Color(hex: config.solidColorHex)

        case .linearGradient:
            LinearGradient(
                colors: [Color(hex: config.gradientStartHex), Color(hex: config.gradientEndHex)],
                startPoint: config.gradientDirection.startPoint,
                endPoint: config.gradientDirection.endPoint
            )

        case .radialGradient:
            RadialGradient(
                colors: [Color(hex: config.gradientStartHex), Color(hex: config.gradientEndHex)],
                center: .center,
                startRadius: 10,
                endRadius: 260
            )

        case .meshGradient:
            meshGradientLayer
        }
    }

    @ViewBuilder
    private var meshGradientLayer: some View {
        let colors = (0..<9).map { index -> Color in
            if index < config.meshColorsHex.count {
                return Color(hex: config.meshColorsHex[index])
            }
            return Color(hex: "#1A1A2E")
        }

        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: colors
        )
    }
}

/// View modifier applying the full widget surface styling
public struct WidgetSurfaceModifier: ViewModifier {
    public let config: WidgetConfig
    public let cornerRadius: CGFloat
    public let motionReactive: Bool

    @ObservedObject private var motion = MotionManager.shared

    public init(config: WidgetConfig, cornerRadius: CGFloat, motionReactive: Bool = true) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.motionReactive = motionReactive
    }

    public func body(content: Content) -> some View {
        let offset = motionReactive ? motion.normalizedOffset : .zero
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            if motionReactive && config.backgroundMode == .liquidGlass {
                content
                    .glassEffect(config.glassStyle == .ultraClear ? .clear : .regular, in: shape)
                    .background {
                        WidgetBackgroundView(config: config, cornerRadius: cornerRadius, isInteractivePreview: true)
                    }
            } else {
                content
                    .background {
                        WidgetBackgroundView(config: config, cornerRadius: cornerRadius, isInteractivePreview: motionReactive)
                    }
            }
        }
        .clipShape(shape)
        .shadow(
            color: config.backgroundMode == .solidColor
                ? Color(hex: config.solidColorHex).opacity(0.35)
                : (config.glassStyle == .blackGlass ? Color.black.opacity(0.4) : config.tintColor.opacity(0.20)),
            radius: 18,
            x: offset.width * 4,
            y: 10 + offset.height * 4
        )
    }
}

public extension View {
    func liquidGlass(
        style: GlassMaterialStyle = .ultraClear,
        tint: Color = .blue,
        cornerRadius: CGFloat = 26.0,
        blurRadius: CGFloat? = nil,
        motionReactive: Bool = true,
        specularIntensity: Double = 0.8,
        showEdgeShine: Bool = true
    ) -> some View {
        modifier(
            LiquidGlassModifier(
                style: style,
                tint: tint,
                cornerRadius: cornerRadius,
                blurRadius: blurRadius,
                motionReactive: motionReactive,
                specularIntensity: specularIntensity,
                showEdgeShine: showEdgeShine
            )
        )
    }

    func widgetSurface(
        config: WidgetConfig,
        cornerRadius: CGFloat = 26.0,
        motionReactive: Bool = true
    ) -> some View {
        modifier(
            WidgetSurfaceModifier(
                config: config,
                cornerRadius: cornerRadius,
                motionReactive: motionReactive
            )
        )
    }
}
