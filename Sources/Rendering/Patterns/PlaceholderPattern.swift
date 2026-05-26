import CoreGraphics

/// Temporary stand-in until the real patterns are ported. Scatters translucent
/// cells so every slider visibly affects the canvas — this proves the whole
/// pipeline (state → config → renderer → Canvas/export) works end to end.
///
/// Delete this once all real patterns exist; the dispatch in WallpaperRenderer
/// will no longer fall through to it.
enum PlaceholderPattern {
    private static let swatches = [
        "#c47dd0", "#e85a5a", "#5cc77a", "#f0a050", "#8acce8", "#a070b8",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig) {
        let prng = PRNG(seed: config.seed)
        let count = Int(160 * config.density)
        guard count > 0 else { return }

        let minSide = min(size.width, size.height)

        for _ in 0..<count {
            let s = prng.next()
            let x = prng.random(s) * size.width
            let y = prng.random(s + 0.3) * size.height
            let radius = (minSide * 0.015
                          + prng.random(prng.next()) * minSide * 0.06)
                         * config.elementScale
            let hex = swatches[Int(prng.random(prng.next())
                                   * Double(swatches.count)) % swatches.count]
            let color = ColorMath.paletteShift(
                hex,
                hue: config.hue,
                sat: config.saturation,
                light: config.lightness
            ).withAlpha(min(1, config.alpha * 2.4))

            cg.setFillColor(color.cgColor)
            cg.fillEllipse(in: CGRect(x: x - radius, y: y - radius,
                                      width: radius * 2, height: radius * 2))
        }
    }
}
