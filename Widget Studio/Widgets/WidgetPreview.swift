import SwiftUI

/// Renders a widget the way WidgetKit does — same `WidgetDisplayView`, same background —
/// at its true point size, scaled down uniformly when the available space is smaller.
public struct WidgetPreview: View {
    public let widget: WidgetConfig
    public var isInteractive: Bool = false
    public var onCounterTap: (() -> Void)? = nil
    public var onToggleTap: (() -> Void)? = nil

    public init(
        widget: WidgetConfig,
        isInteractive: Bool = false,
        onCounterTap: (() -> Void)? = nil,
        onToggleTap: (() -> Void)? = nil
    ) {
        self.widget = widget
        self.isInteractive = isInteractive
        self.onCounterTap = onCounterTap
        self.onToggleTap = onToggleTap
    }

    private var nativeSize: CGSize {
        CGSize(width: widget.size.previewWidth, height: widget.size.previewHeight)
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / nativeSize.width, proxy.size.height / nativeSize.height)

            WidgetDisplayView(
                widget: widget,
                isInteractivePreview: isInteractive,
                onCounterTap: onCounterTap,
                onToggleTap: onToggleTap
            )
            .frame(width: nativeSize.width, height: nativeSize.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: nativeSize.width * scale, height: nativeSize.height * scale, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(nativeSize.width / nativeSize.height, contentMode: .fit)
        .frame(maxWidth: nativeSize.width, maxHeight: nativeSize.height)
        .allowsHitTesting(isInteractive)
    }
}
