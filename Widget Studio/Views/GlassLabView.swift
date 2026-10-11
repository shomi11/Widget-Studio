import SwiftUI

/// An interactive laboratory to experiment with the Liquid Glass optical engine,
/// shape morphing via GlassEffectContainer, specular highlights, and tilt responsiveness.
public struct GlassLabView: View {

    @State private var labStyle: GlassMaterialStyle = .ultraClear
    @State private var labTint: Color = .blue
    @State private var containerSpacing: CGFloat = 36.0
    @State private var isShapeExpanded: Bool = false
    @State private var specularPower: Double = 0.90
    @Namespace private var glassNamespace

    public init() {}

    /// Pushed from Settings › Developer, so it doesn't own a NavigationStack.
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                physicsPlaygroundCanvas
                opticsControlSection
                morphingDetailsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .contentMargins(.bottom, 24, for: .scrollContent)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Optics Lab")
        .navigationBarTitleDisplayMode(.inline)
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
                    Label(isShapeExpanded ? "Merge" : "Separate", systemImage: "arrow.triangle.merge")
                }
                .buttonStyle(.glass)

            }
            .padding(24)
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
    }

    private var opticsControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.headline)

            // Material Preset Switcher
            Picker("Material", selection: $labStyle) {
                ForEach(GlassMaterialStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)

            // Spacing slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Merge distance")
                    Spacer()
                    Text("\(Double(containerSpacing).formatted(.number.precision(.fractionLength(0)))) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $containerSpacing, in: 10...60, step: 2)
            }

            // Specular slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Shine")
                    Spacer()
                    Text(specularPower, format: .percent.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $specularPower, in: 0.1...1.0, step: 0.05)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var morphingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How merging works")
                .font(.headline)

            Text("Inside a GlassEffectContainer, adjacent glass elements blend together smoothly when within proximity. As elements detach, spring physics create a drop-like stretching effect before surface tension breaks into discrete lenses.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}
