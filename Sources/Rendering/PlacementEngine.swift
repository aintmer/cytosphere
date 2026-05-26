import CoreGraphics
import CoreImage
import Foundation

/// Per-layer element-type chooser. Mirrors pickUniqueType / pickVariedType
/// from the HTML reference: foreground layers want unique "hero" types,
/// mid/near layers avoid recent repeats, the background is fully random.
final class TypePicker {
    enum Mode { case random, recent, unique }

    private let mode: Mode
    private var recent: [String] = []
    private var used: Set<String> = []

    init(_ mode: Mode) { self.mode = mode }

    func pick(from weighted: [String], prng: PRNG) -> String {
        guard !weighted.isEmpty else { return "" }
        switch mode {
        case .random:
            return weighted[index(prng.random(prng.next() * 17.31), weighted.count)]

        case .recent:
            let available = weighted.filter { !recent.contains($0) }
            let pool = available.isEmpty ? weighted : available
            let choice = pool[index(prng.random(prng.next() * 17.31), pool.count)]
            recent.append(choice)
            if recent.count > 2 { recent.removeFirst() }
            return choice

        case .unique:
            var available: [String] = []
            var seen = Set<String>()
            for t in weighted where !used.contains(t) && !seen.contains(t) {
                available.append(t)
                seen.insert(t)
            }
            let pool = available.isEmpty ? weighted : available
            let choice = pool[index(prng.random(prng.next() * 23.47), pool.count)]
            used.insert(choice)
            return choice
        }
    }

    private func index(_ r: Double, _ count: Int) -> Int {
        min(count - 1, max(0, Int(r * Double(count))))
    }
}

/// Layered placement with depth-of-field. Mirrors placeWithLayers from the HTML
/// reference: four depth layers (background → foreground) each with its own
/// element count, spacing, size range, blur and opacity. Far layers are blurred
/// with a Gaussian (Core Image) so the result has real depth of field.
enum PlacementEngine {

    struct Options {
        var bgCount = 36;  var bgMinDist = 240.0;  var bgSize = 120.0...320.0
        var midCount = 15; var midMinDist = 410.0; var midSize = 280.0...540.0
        var nearCount = 7; var nearMinDist = 540.0; var nearSize = 400.0...660.0
        var fgCount = 5;   var fgMinDist = 720.0;  var fgSize = 520.0...860.0
        init() {}
    }

    /// drawElement: draws one element of `type`, centered at the origin, into a
    /// context already translated + rotated to the element's slot. `x`/`y` are
    /// the element's canvas-space center — patterns whose color depends on
    /// position (e.g. bacteria's radial palette) need it; others ignore it.
    static func place(
        in cg: CGContext,
        size: CGSize,
        config: RenderConfig,
        scale: Double,
        areaScale: Double,
        prng: PRNG,
        weighted: [String],
        options: Options = Options(),
        drawElement: (CGContext, _ x: Double, _ y: Double,
                      _ type: String, _ size: Double, _ prng: PRNG) -> Void
    ) {
        let dofMul = config.depthOfField
        let densMul = config.density * areaScale / 3
        let distScale = scale / sqrt(max(0.5, densMul))

        // --- one standard depth layer (bg / mid / near) --------------------
        func standardLayer(count: Int, minDist: Double, sizeRange: ClosedRange<Double>,
                           blur: Double, opacity: Double, picker: TypePicker) {
            renderLayer(into: cg, size: size, blur: blur, opacity: opacity) { layerCG in
                var placed: [(x: Double, y: Double)] = []
                var attempts = 0
                let target = Int((Double(count) * densMul).rounded())
                while placed.count < target && attempts < target * 50 {
                    attempts += 1
                    let s1 = prng.next()
                    let x = prng.random(s1) * size.width
                    let y = prng.random(s1 + 0.3) * size.height
                    var close = false
                    for p in placed where hypot(p.x - x, p.y - y) < minDist {
                        close = true; break
                    }
                    if close { continue }
                    let elemSize = (sizeRange.lowerBound
                        + pow(prng.random(prng.next()), 1.6)
                          * (sizeRange.upperBound - sizeRange.lowerBound)) * scale
                    let rot = prng.random(prng.next() * 4.97) * 360
                    let type = picker.pick(from: weighted, prng: prng)
                    layerCG.saveGState()
                    layerCG.translateBy(x: x, y: y)
                    layerCG.rotate(by: rot * .pi / 180)
                    drawElement(layerCG, x, y, type, elemSize, prng)
                    layerCG.restoreGState()
                    placed.append((x, y))
                }
            }
        }

        standardLayer(count: options.bgCount,
                      minDist: options.bgMinDist * distScale,
                      sizeRange: options.bgSize,
                      blur: 6 * scale * dofMul, opacity: 0.5,
                      picker: TypePicker(.random))
        standardLayer(count: options.midCount,
                      minDist: options.midMinDist * distScale,
                      sizeRange: options.midSize,
                      blur: 3 * scale * dofMul, opacity: 0.65,
                      picker: TypePicker(.recent))
        standardLayer(count: options.nearCount,
                      minDist: options.nearMinDist * distScale,
                      sizeRange: options.nearSize,
                      blur: 1.2 * scale * dofMul, opacity: 0.8,
                      picker: TypePicker(.recent))

        // --- foreground layer (no blur, unique heroes, inset placement) ----
        let fgPicker = TypePicker(.unique)
        renderLayer(into: cg, size: size, blur: 0, opacity: 1.0) { layerCG in
            var placed: [(x: Double, y: Double)] = []
            var attempts = 0
            let fgTarget = max(3, Int((Double(options.fgCount)
                                       * min(densMul * 2, 2)).rounded()))
            let fgDist = options.fgMinDist * scale / sqrt(max(0.5, densMul / 2))
            while placed.count < fgTarget && attempts < 800 {
                attempts += 1
                let s1 = prng.next()
                let x = (0.15 + prng.random(s1) * 0.7) * size.width
                let y = (0.15 + prng.random(s1 + 0.3) * 0.7) * size.height
                var close = false
                for p in placed where hypot(p.x - x, p.y - y) < fgDist {
                    close = true; break
                }
                if close { continue }
                let elemSize = (options.fgSize.lowerBound
                    + prng.random(prng.next())
                      * (options.fgSize.upperBound - options.fgSize.lowerBound)) * scale
                let rot = prng.random(prng.next() * 7.91) * 360
                let type = fgPicker.pick(from: weighted, prng: prng)
                layerCG.saveGState()
                layerCG.translateBy(x: x, y: y)
                layerCG.rotate(by: rot * .pi / 180)
                drawElement(layerCG, x, y, type, elemSize, prng)
                layerCG.restoreGState()
                placed.append((x, y))
            }
        }
    }

    // MARK: - Layer compositing

    private static let ciContext: CIContext = {
        var opts: [CIContextOption: Any] = [.useSoftwareRenderer: false]
        if let srgb = CGColorSpace(name: CGColorSpace.sRGB) {
            opts[.workingColorSpace] = srgb
            opts[.outputColorSpace] = srgb
        }
        return CIContext(options: opts)
    }()

    /// Renders a layer's content, optionally blurred, into the main context at
    /// the given layer opacity.
    ///
    /// For blurred layers we draw + blur at a **reduced resolution** (½ or ¼
    /// of the main context) and then upsample on composite. CIGaussianBlur's
    /// cost is O(W·H), so downsampling by 4× makes the blur **16× faster**
    /// for the bg/mid layers — by far the dominant cost of the export at
    /// 6K-16K resolutions. Quality stays identical to the eye: the blur is
    /// already smoothing away any detail finer than the blur radius, so
    /// rendering that detail at full resolution was wasted work to begin with.
    private static func renderLayer(into cg: CGContext, size: CGSize,
                                    blur: Double, opacity: Double,
                                    _ body: (CGContext) -> Void) {
        let cappedBlur = min(18.0, blur)

        if cappedBlur < 0.75 {
            // Sharp layer — draw straight into the main context.
            cg.saveGState()
            cg.setAlpha(CGFloat(opacity))
            cg.beginTransparencyLayer(auxiliaryInfo: nil)
            body(cg)
            cg.endTransparencyLayer()
            cg.restoreGState()
            return
        }

        // Pick a downsample factor matched to the blur strength. Stronger blur
        // tolerates more aggressive downsampling (the blur kernel was going to
        // erase any detail at that scale anyway). We never go larger than the
        // main context.
        let dsFactor: Double
        if cappedBlur >= 6 {
            dsFactor = 4   // strong blur (bg + mid layers at 6K+) — 16× cheaper
        } else if cappedBlur >= 2 {
            dsFactor = 2   // medium blur (near layer) — 4× cheaper
        } else {
            dsFactor = 1   // weak blur — full resolution
        }

        let lowW = max(1, Int((size.width / dsFactor).rounded()))
        let lowH = max(1, Int((size.height / dsFactor).rounded()))

        guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
              let off = CGContext(data: nil, width: lowW, height: lowH,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            // Allocation failed — fall back to a sharp draw.
            cg.saveGState()
            cg.setAlpha(CGFloat(opacity))
            cg.beginTransparencyLayer(auxiliaryInfo: nil)
            body(cg)
            cg.endTransparencyLayer()
            cg.restoreGState()
            return
        }

        // The body closure draws in the main context's coordinate space (size).
        // We want those coordinates to be honored but rendered into the smaller
        // `lowW × lowH` bitmap, so we pre-scale by 1/dsFactor. Then we flip to
        // y-down so the body's coordinate conventions match the main context.
        //
        // Whole layer wrapped in autoreleasepool so the offscreen bitmap and
        // intermediate CIImage memory is freed as soon as we composite —
        // matters at Ultra quality where each layer's offscreen can be
        // hundreds of MB.
        autoreleasepool {
            off.scaleBy(x: CGFloat(1.0 / dsFactor), y: CGFloat(1.0 / dsFactor))
            off.translateBy(x: 0, y: size.height)
            off.scaleBy(x: 1, y: -1)
            body(off)

            guard let raw = off.makeImage() else { return }
            // The blur radius is in pixels — scale it down to match the
            // reduced bitmap so the apparent blur stays the same after
            // upsampling.
            let blurred = gaussianBlur(raw, radius: cappedBlur / dsFactor) ?? raw

            cg.saveGState()
            cg.setAlpha(CGFloat(opacity))
            cg.translateBy(x: 0, y: size.height)
            cg.scaleBy(x: 1, y: -1)
            cg.draw(blurred, in: CGRect(origin: .zero, size: size))
            cg.restoreGState()
        }
    }

    private static func gaussianBlur(_ image: CGImage, radius: Double) -> CGImage? {
        let input = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return nil }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        return ciContext.createCGImage(output, from: rect)
    }
}
