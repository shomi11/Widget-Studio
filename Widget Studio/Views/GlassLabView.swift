import SwiftUI

/// An interactive laboratory to experiment with the Liquid Glass optical engine,
/// shape morphing via GlassEffectContainer, specular highlights, and tilt responsiveness.
public struct GlassLabView: View {
    @ObservedObject private var motion = MotionManager.shared
    @Binding var isTabBarMinimized: Bool

    @State private var labStyle: GlassMaterialStyle = .ultraClear
    @State private var labTint: Color = .blue
    @State private var containerSpacing: CGFloat = 36.0
    @State private var isShapeExpanded: Bool = false
    @State private var specularPower: Double = 0.90
    @Namespace private var glassNamespace

    public init(isTabBarMinimized: Binding<Bool> = .constant(false)) {
        self._isTabBarMinimized = isTabBarMinimized
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Physics & Optics Canvas
                    physicsPlaygroundCanvas

                    // Interactive Controls
                    opticsControlSection

                    // Morphing Explanation
                    morphingDetailsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { oldValue, newValue in
                let diff = newValue - oldValue
                if diff > 15 && newValue > 40 {
                    if !isTabBarMinimized {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isTabBarMinimized = true
                        }
                    }
                } else if diff < -15 {
                    if isTabBarMinimized {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isTabBarMinimized = false
                        }
                    }
                }
            }
            .navigationTitle("Glass Optics Lab")
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        }
    }

    private var physicsPlaygroundCanvas: some View {
        ZStack {
            // High dynamic range chromatic backdrop
            LinearGradient(
                colors: [Color.indigo, Color.purple, Color.pink, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Liquid Glass Morphing Shapes
                GlassEffectContainer(spacing: containerSpacing) {
                    HStack(spacing: containerSpacing) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: 76, height: 76)
                            .glassEffect(labStyle == .ultraClear ? .clear : .regular)
                            .glassEffectID("drop", in: glassNamespace)
                            .foregroundStyle(.white)

                        if isShapeExpanded {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32, weight: .bold))
                                .frame(width: 76, height: 76)
                                .glassEffect(labStyle == .ultraClear ? .clear : .regular)
                                .glassEffectID("sparkle", in: glassNamespace)
                                .foregroundStyle(labTint)
                        }

                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: 76, height: 76)
                            .glassEffect(labStyle == .ultraClear ? .clear : .regular)
                            .glassEffectID("grid", in: glassNamespace)
                            .foregroundStyle(.white)
                    }
                }

                // Interactive Morph Button
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                        isShapeExpanded.toggle()
                    }
                } label: {
                    Label(isShapeExpanded ? "Morph Together" : "Detach Droplet", systemImage: "arrow.triangle.merge")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule()
                    )
                }
                .buttonStyle(.plain)

                // Gyroscope Live Telemetry
                HStack(spacing: 16) {
                    telemetryBadge(title: "ROLL", value: String(format: "%.2f", motion.roll))
                    telemetryBadge(title: "PITCH", value: String(format: "%.2f", motion.pitch))
                    telemetryBadge(title: "SHEEN X", value: String(format: "%.2f", motion.normalizedOffset.width))
                }
            }
            .padding(24)
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
    }

    private func telemetryBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3), in: Capsule())
    }

    private var opticsControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("REFRACTIVE CONTROLS", systemImage: "slider.horizontal.3")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Material Preset Switcher
            Picker("Material", selection: $labStyle) {
                ForEach(GlassMaterialStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)

            // Spacing slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Container Blending Spacing")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(containerSpacing)) pt")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $containerSpacing, in: 10...60, step: 2)
                    .tint(.blue)
            }

            // Specular slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Specular Glare Power")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(specularPower * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $specularPower, in: 0.1...1.0, step: 0.05)
                    .tint(.purple)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var morphingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LIQUID GLASS HIG SPECIFICATION", systemImage: "info.circle.fill")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.blue)

            Text("Fluid Morphing & Spacing Mechanics")
                .font(.subheadline)
                .fontWeight(.bold)

            Text("Inside a GlassEffectContainer, adjacent glass elements blend together smoothly when within proximity. As elements detach, spring physics create a drop-like stretching effect before surface tension breaks into discrete lenses.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
