import SwiftUI

/// Elegant Liquid Glass permission sheet presented whenever the user creates or adds
/// a widget for a specific category that requires Apple framework authorization.
public struct CategoryPermissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var permissionManager = CategoryPermissionManager.shared

    public let category: WidgetCategory
    public var onAuthorized: () -> Void

    @State private var isRequesting: Bool = false
    @State private var showSettingsPrompt: Bool = false

    public init(category: WidgetCategory, onAuthorized: @escaping () -> Void) {
        self.category = category
        self.onAuthorized = onAuthorized
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header Icon with Fluid Glass Aura
                ZStack {
                    Circle()
                        .fill(Color(hex: category.defaultTintHex).opacity(0.18))
                        .frame(width: 84, height: 84)

                    Circle()
                        .strokeBorder(Color(hex: category.defaultTintHex).opacity(0.4), lineWidth: 2)
                        .frame(width: 84, height: 84)

                    Image(systemName: category.icon)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color(hex: category.defaultTintHex))
                }
                .padding(.top, 14)

                // Category & Integration Title
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(category.appleApp)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(category.frameworkName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: category.defaultTintHex).opacity(0.15), in: Capsule())
                            .foregroundStyle(Color(hex: category.defaultTintHex))
                    }

                    Text("Allow \(category.rawValue) Access")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                }

                // Health Metrics Grid Breakdown if Category is Health
                if category == .health {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HEALTH DATA TYPES ACCESSED")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            metricBadge(title: "Sleep & Score", icon: "bed.double.fill", color: .purple)
                            metricBadge(title: "Blood O2 (SpO2)", icon: "lungs.fill", color: .cyan)
                            metricBadge(title: "Water Intake", icon: "drop.fill", color: .teal)
                            metricBadge(title: "Caffeine Tracking", icon: "cup.and.saucer.fill", color: .brown)
                            metricBadge(title: "Heart Rate & Vitals", icon: "heart.fill", color: .pink)
                            metricBadge(title: "Steps & Calories", icon: "flame.fill", color: .orange)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else if category == .calendar {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CALENDAR FEATURES ENABLED")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            metricBadge(title: "Upcoming Agenda", icon: "calendar.badge.clock", color: .red)
                            metricBadge(title: "Monthly Matrix", icon: "calendar", color: .orange)
                            metricBadge(title: "Meeting Locations", icon: "mappin.and.ellipse", color: .blue)
                            metricBadge(title: "Timeline Countdowns", icon: "hourglass", color: .purple)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                // Rationale Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(category.permissionRationale)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(2)

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("100% On-Device & Private")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Your personal \(category.rawValue.lowercased()) data never leaves this device.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        handleAuthorization()
                    } label: {
                        HStack(spacing: 8) {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Authorize \(category.rawValue) Access")
                            }
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: category.defaultTintHex), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                        .shadow(color: Color(hex: category.defaultTintHex).opacity(0.4), radius: 10, y: 5)
                    }
                    .disabled(isRequesting)

                    Button {
                        // User can choose demo mode or bypass
                        dismiss()
                        onAuthorized()
                    } label: {
                        Text("Continue in Demo Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func metricBadge(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func handleAuthorization() {
        isRequesting = true
        Task {
            let _ = await permissionManager.requestPermission(for: category)
            isRequesting = false
            dismiss()
            onAuthorized()
        }
    }
}
