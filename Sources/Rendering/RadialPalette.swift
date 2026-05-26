import CoreGraphics
import Foundation

/// Position-derived color triple. Several patterns (bacteria, fields, bohr,
/// feynman, etc.) tint elements by their canvas location rather than by a
/// fixed palette — the hue sweeps around the canvas center.
struct RadialColor {
    let line: RGBA   // outlines
    let pos: RGBA    // fills
    let neg: RGBA    // accents
}

/// Mirrors getColor() from the HTML reference. Hue sweeps with the angle from
/// the canvas center, drifting outward by radius; saturation and lightness
/// follow the global sliders.
func radialPalette(x: Double, y: Double, w: Double, h: Double,
                   config: RenderConfig) -> RadialColor {
    let dx = x - w / 2, dy = y - h / 2
    let angle = atan2(dy, dx)
    let radius = (dx * dx + dy * dy).squareRoot() / max(w, h)
    var hue = ((angle + .pi) / (2 * .pi)) * 360 + config.hue
    hue = (hue + radius * 60).truncatingRemainder(dividingBy: 360)
    let s = config.saturation, l = config.lightness
    return RadialColor(
        line: ColorMath.hslToRGB(h: hue, s: s, l: l),
        pos:  ColorMath.hslToRGB(h: (hue - 15 + 360).truncatingRemainder(dividingBy: 360),
                                 s: s + 10, l: l + 10),
        neg:  ColorMath.hslToRGB(h: (hue + 25).truncatingRemainder(dividingBy: 360),
                                 s: s + 5, l: l + 5)
    )
}
