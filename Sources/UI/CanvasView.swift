import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Live preview.
///
/// Renders **off the main thread** via `LivePreviewRenderer` and displays the
/// resulting image, rather than drawing inline in a `Canvas` (whose closure
/// runs on the main thread and stutters the UI while a slider drags).
///
/// Supports **pinch-to-zoom + drag-to-pan** for inspecting detail while
/// configuring (double-tap resets). When zoomed, the renderer is asked for a
/// higher-resolution image so the zoomed view stays crisp instead of upscaling
/// a blur.
///
/// Letterbox treatment: when the wallpaper's aspect doesn't match the
/// container, fill the bands with a neutral system background (light in light
/// mode, black in dark mode) so the print's edge stays visible.
struct CanvasView: View {
    let config: RenderConfig
    let aspect: AspectPreset

    /// Called on a single tap on the preview — used by the iOS editor to
    /// dismiss an open panel. When `nil`, NO single-tap gesture is attached, so
    /// it never competes for taps with the floating buttons in the common
    /// (no-panel) state.
    var onSingleTap: (() -> Void)? = nil

    @State private var renderer = LivePreviewRenderer()
    @Environment(\.displayScale) private var displayScale

    // Zoom / pan. `committed*` persist between gestures; the @GestureState
    // values are the live in-progress deltas (auto-reset when the gesture ends).
    @State private var committedZoom: CGFloat = 1
    @State private var committedPan: CGSize = .zero
    @GestureState private var pinchDelta: CGFloat = 1
    @GestureState private var dragDelta: CGSize = .zero

    private let maxZoom: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let zoom = min(max(committedZoom * pinchDelta, 1), maxZoom)
            let offset = clampOffset(
                CGSize(width: committedPan.width + dragDelta.width,
                       height: committedPan.height + dragDelta.height),
                container: proxy.size, zoom: zoom
            )
            ZStack {
                letterboxColor
                if let image = renderer.image {
                    Image(platformImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(aspect.ratio, contentMode: .fit)
                        .scaleEffect(zoom)
                        .offset(offset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .gesture(zoomPan(container: proxy.size))
            .onTapGesture(count: 2) { resetZoom() }
            .optionalSingleTap(onSingleTap)
            .onAppear { request(proxy.size) }
            .onChange(of: config) { request(proxy.size) }
            .onChange(of: aspect) { resetZoom(); request(proxy.size) }
            .onChange(of: proxy.size) { request(proxy.size) }
            .onChange(of: committedZoom) { request(proxy.size) }
        }
    }

    // MARK: - Rendering

    private func request(_ size: CGSize) {
        renderer.request(config: config, aspect: aspect,
                         containerSize: size, scale: displayScale,
                         zoom: committedZoom)
    }

    // MARK: - Zoom / pan

    private func zoomPan(container: CGSize) -> some Gesture {
        let magnify = MagnifyGesture()
            .updating($pinchDelta) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                committedZoom = min(max(committedZoom * value.magnification, 1), maxZoom)
                committedPan = committedZoom <= 1
                    ? .zero
                    : clampOffset(committedPan, container: container, zoom: committedZoom)
            }

        let drag = DragGesture()
            .updating($dragDelta) { value, state, _ in
                if committedZoom > 1 { state = value.translation }
            }
            .onEnded { value in
                guard committedZoom > 1 else { return }
                let raw = CGSize(width: committedPan.width + value.translation.width,
                                 height: committedPan.height + value.translation.height)
                committedPan = clampOffset(raw, container: container, zoom: committedZoom)
            }

        return magnify.simultaneously(with: drag)
    }

    private func resetZoom() {
        guard committedZoom != 1 || committedPan != .zero else { return }
        withAnimation(.snappy(duration: 0.3)) {
            committedZoom = 1
            committedPan = .zero
        }
    }

    /// Clamp a pan offset so the zoomed image can't be dragged past its own
    /// edges (no panning the print off into the letterbox).
    private func clampOffset(_ o: CGSize, container: CGSize, zoom: CGFloat) -> CGSize {
        guard zoom > 1 else { return .zero }
        let img = fittedDisplaySize(container: container)
        let maxX = max(0, img.width  * (zoom - 1) / 2)
        let maxY = max(0, img.height * (zoom - 1) / 2)
        return CGSize(width: min(max(o.width, -maxX), maxX),
                      height: min(max(o.height, -maxY), maxY))
    }

    /// The on-screen size of the aspect-fit preview before zoom.
    private func fittedDisplaySize(container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return container }
        let ar = aspect.ratio
        let cAR = container.width / container.height
        if ar > cAR {
            return CGSize(width: container.width, height: container.width / ar)
        } else {
            return CGSize(width: container.height * ar, height: container.height)
        }
    }

    // MARK: - Letterbox

    private var letterboxColor: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.black
        #endif
    }
}

private extension View {
    /// Attach a single-tap handler only when one is provided. Keeping it
    /// conditional means no tap gesture exists in the common state, so it never
    /// competes with overlaid buttons.
    @ViewBuilder
    func optionalSingleTap(_ action: (() -> Void)?) -> some View {
        if let action {
            onTapGesture(count: 1, perform: action)
        } else {
            self
        }
    }
}
