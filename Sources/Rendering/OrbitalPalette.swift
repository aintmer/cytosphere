import Foundation

/// Position-derived phase colors for atomic-orbital patterns. The two orbital
/// renderings (hybrid clouds + schematic diagrams) both use this: a "pos" hue
/// driven by canvas position, a "neg" lobe shifted by ~140° (visually distinct
/// opposite-phase counterpart), plus line and nucleus accents.
struct OrbitalPhaseColors {
    let pos: RGBA
    let posLine: RGBA
    let neg: RGBA
    let negLine: RGBA
    let nucleus: RGBA
}

func orbitalPhaseColors(x: Double, y: Double, w: Double, h: Double,
                        config: RenderConfig) -> OrbitalPhaseColors {
    let dx = x - w / 2, dy = y - h / 2
    let angle = atan2(dy, dx)
    let radius = (dx * dx + dy * dy).squareRoot() / max(w, h)
    var hue = ((angle + .pi) / (2 * .pi)) * 360 + config.hue
    hue = (hue + radius * 60).truncatingRemainder(dividingBy: 360)
    let s = config.saturation, l = config.lightness
    let sPos = min(100, s + 30)
    let sLine = min(100, s + 40)
    let sNuc = min(100, s + 50)
    let lLine = min(95, l + 15)
    let lNuc = min(95, l + 25)
    let negHue = (hue + 140).truncatingRemainder(dividingBy: 360)
    return OrbitalPhaseColors(
        pos:     ColorMath.hslToRGB(h: hue,    s: sPos,  l: l),
        posLine: ColorMath.hslToRGB(h: hue,    s: sLine, l: lLine),
        neg:     ColorMath.hslToRGB(h: negHue, s: sPos,  l: l),
        negLine: ColorMath.hslToRGB(h: negHue, s: sLine, l: lLine),
        nucleus: ColorMath.hslToRGB(h: hue,    s: sNuc,  l: lNuc)
    )
}
