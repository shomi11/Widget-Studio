import SwiftUI
import CoreMotion
import Combine

/// Tracks device attitude & motion to compute real-time specular highlights and refraction displacement.
@MainActor
public final class MotionManager: ObservableObject {
    public static let shared = MotionManager()

    @Published public var pitch: Double = 0.0
    @Published public var roll: Double = 0.0
    @Published public var normalizedOffset: CGSize = .zero

    private let motionManager = CMMotionManager()
    private var isSimulated: Bool = false
    private var simulationTimer: AnyCancellable?

    private var isExtensionContext: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
    }

    public init() {
        // Only start active motion tracking in interactive app environment, never in WidgetKit extensions
        if !isExtensionContext {
            startTracking()
        }
    }

    public func startTracking() {
        guard !isExtensionContext else { return }

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self, let motion = motion else { return }
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
                // Clamp and normalize offset to [-1.0, 1.0] range
                let clampedX = max(-1.0, min(1.0, motion.attitude.roll * 1.5))
                let clampedY = max(-1.0, min(1.0, motion.attitude.pitch * 1.5))
                withAnimation(.interpolatingSpring(stiffness: 120, damping: 14)) {
                    self.normalizedOffset = CGSize(width: clampedX, height: clampedY)
                }
            }
        } else {
            // Fallback for Simulator / Previews: gentle periodic fluid sway
            isSimulated = true
            var step: Double = 0.0
            simulationTimer = Timer.publish(every: 0.03, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    step += 0.04
                    let x = sin(step) * 0.35
                    let y = cos(step * 0.8) * 0.35
                    self.normalizedOffset = CGSize(width: x, height: y)
                    self.roll = x
                    self.pitch = y
                }
        }
    }

    public func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        simulationTimer?.cancel()
        simulationTimer = nil
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
        simulationTimer?.cancel()
    }
}
