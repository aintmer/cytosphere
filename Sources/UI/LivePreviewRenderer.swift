import SwiftUI

/// Drives the live preview render **off the main thread**, with *adaptive*
/// resolution so the image keeps up with a drag regardless of how expensive
/// the current pattern is.
///
/// SwiftUI's `Canvas` runs its draw closure inline on the main thread, so every
/// slider tick used to block the UI while the (heavy) wallpaper re-rendered.
/// This renders asynchronously instead. Patterns vary enormously in cost — the
/// detailed ones (mitosis, blood, parasites, organelles) take several times
/// longer per element than the simple ones — so a fixed draft resolution is
/// either too slow for the heavy patterns or needlessly soft for the light
/// ones. Instead each in-drag frame is *timed*, and the draft resolution is
/// nudged toward a frame-time budget: cheap patterns settle at full draft
/// resolution (crisp), expensive ones automatically shrink until they track the
/// finger. Either way, when the drag stops a debounced **full-resolution** pass
/// renders the exact image. Requests coalesce to the latest config; only one
/// render runs at a time and stale frames are dropped.
@MainActor
@Observable
final class LivePreviewRenderer {
    private(set) var image: PlatformImage?

    private var pending: Request?
    private var isRendering = false
    /// The request currently shown at FULL resolution, if any.
    private var shownFull: Request?
    private var settleTask: Task<Void, Never>?

    private struct Request: Equatable {
        var config: RenderConfig
        var fullSize: CGSize
    }

    // MARK: - Adaptive draft resolution

    /// Target wall-clock per in-drag frame (~25fps). The cap is nudged to keep
    /// the measured render near this.
    private static let frameBudgetMs = 40.0
    /// Hard floor — below this the preview gets too blocky to be useful.
    private static let minCap: CGFloat = 340
    /// Hard ceiling — kept just under PlacementEngine's blur-skip threshold
    /// (760) so draft frames never pay for the depth-of-field blur.
    private static let maxCap: CGFloat = 720

    /// Current longest-side cap for in-drag frames. Mutable: it adapts to the
    /// active pattern's measured cost and persists across drags, so by the
    /// second frame of a drag it's already dialed in for that pattern.
    private var interactiveCap: CGFloat = maxCap

    /// Request a render for `config`, fitted into `containerSize`. Cheap to call
    /// at slider-drag frequency. `zoom` (≥1) renders the full pass at higher
    /// resolution so a zoomed-in preview stays crisp instead of upscaling a
    /// blur; the in-drag draft is still capped low for speed.
    func request(config: RenderConfig, aspect: AspectPreset,
                 containerSize: CGSize, scale: CGFloat, zoom: CGFloat = 1) {
        let fullSize = Self.fittedPixelSize(aspect: aspect,
                                            container: containerSize,
                                            scale: scale, zoom: zoom)
        guard fullSize.width >= 1, fullSize.height >= 1 else { return }
        let req = Request(config: config, fullSize: fullSize)

        // Already showing exactly this at full resolution — nothing to do.
        if req == shownFull {
            settleTask?.cancel()
            return
        }

        settleTask?.cancel()
        pending = req
        guard !isRendering else { return }   // in-flight render will pick it up
        renderNext(interactive: true)
    }

    private func renderNext(interactive: Bool) {
        guard let req = pending else { return }
        pending = nil
        isRendering = true
        let pixelSize = interactive ? interactiveSize(req.fullSize) : req.fullSize
        let renderedFull = !interactive

        Task.detached(priority: .userInitiated) {
            let t0 = CFAbsoluteTimeGetCurrent()
            let img = WallpaperImageRenderer.image(config: req.config,
                                                   pixelSize: pixelSize)
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000

            await MainActor.run {
                self.isRendering = false
                if interactive { self.adaptCap(lastRenderMs: elapsedMs) }

                let hasNewer = self.pending != nil

                // Never publish a stale FULL settle: it's slow, so if the user
                // has already grabbed the slider again, showing it would flash
                // the previous value before the new draft lands.
                let staleSettle = hasNewer && renderedFull
                if let img, !staleSettle {
                    self.image = img
                }
                self.shownFull = (renderedFull && !hasNewer) ? req : nil

                if hasNewer {
                    self.renderNext(interactive: true)
                } else if !renderedFull {
                    self.scheduleSettle(req)
                }
            }
        }
    }

    /// Nudge the draft cap toward the frame budget. Render cost is ~quadratic in
    /// the longest side (rasterization-bound), so multiplicative steps converge
    /// fast — typically within a frame or two of a drag starting.
    private func adaptCap(lastRenderMs: Double) {
        if lastRenderMs > Self.frameBudgetMs * 1.25 {
            interactiveCap = max(Self.minCap, interactiveCap * 0.82)
        } else if lastRenderMs < Self.frameBudgetMs * 0.6 {
            interactiveCap = min(Self.maxCap, interactiveCap * 1.12)
        }
    }

    private func scheduleSettle(_ req: Request) {
        settleTask?.cancel()
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled,
                  self.pending == nil,
                  !self.isRendering else { return }
            self.pending = req
            self.renderNext(interactive: false)
        }
    }

    /// Downscaled size for in-drag frames — `fullSize` clamped so its longest
    /// side is at most the (adaptive) `interactiveCap`.
    private func interactiveSize(_ fullSize: CGSize) -> CGSize {
        let longest = max(fullSize.width, fullSize.height)
        guard longest > interactiveCap else { return fullSize }
        let k = interactiveCap / longest
        return CGSize(width: fullSize.width * k, height: fullSize.height * k)
    }

    /// Fitted pixel size for an aspect inside a container, capped so a very
    /// large canvas (e.g. a wide Mac window) doesn't render needlessly huge —
    /// the preview is upscaled to fit and stays crisp well below the cap.
    private static func fittedPixelSize(aspect: AspectPreset,
                                        container: CGSize,
                                        scale: CGFloat,
                                        zoom: CGFloat = 1) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        let targetAR = aspect.ratio                 // width / height
        let containerAR = container.width / container.height
        var w: CGFloat, h: CGFloat
        if targetAR > containerAR {
            w = container.width
            h = w / targetAR
        } else {
            h = container.height
            w = h * targetAR
        }
        let z = max(1, zoom)
        var px = CGSize(width: w * scale * z, height: h * scale * z)
        // Higher ceiling when zoomed so detail actually resolves, but bounded
        // so a heavy pattern's full settle doesn't take seconds.
        let cap: CGFloat = z > 1 ? 2200 : 1600
        let longest = max(px.width, px.height)
        if longest > cap {
            let k = cap / longest
            px = CGSize(width: px.width * k, height: px.height * k)
        }
        return px
    }
}
