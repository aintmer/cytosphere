import CoreGraphics

/// 0–255 RGB color with 0–1 alpha. The drawing layer's color currency.
struct RGBA: Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// Parse "#rrggbb" or "rrggbb".
    init(hex: String) {
        var h = hex
        if h.hasPrefix("#") { h.removeFirst() }
        let value = UInt64(h, radix: 16) ?? 0
        r = Double((value >> 16) & 0xFF)
        g = Double((value >> 8) & 0xFF)
        b = Double(value & 0xFF)
        a = 1
    }

    var cgColor: CGColor {
        // Tag explicitly as sRGB. The plain CGColor(red:...) initializer uses
        // an unspecified device color space, which causes a color cast (most
        // visible as a green tint in midtones) when CoreGraphics composites
        // into a wide-gamut context. Hex values are sRGB by definition.
        CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    func withAlpha(_ alpha: Double) -> RGBA {
        RGBA(r: r, g: g, b: b, a: alpha)
    }

    /// Shift lightness toward white (amount > 0) or black (amount < 0), in HSL
    /// space so HUE and SATURATION are preserved — only the L channel moves.
    /// A per-channel RGB lerp (the naive approach) drifts the hue: lightening
    /// washes a color into a tinted grey, and darkening a yellow lands on
    /// muddy olive. Working in HSL keeps the color's identity. amount in -1...1.
    func lightnessShifted(_ amount: Double) -> RGBA {
        if amount == 0 { return self }
        let t = max(-1, min(1, amount))
        let hsl = ColorMath.rgbToHSL(self)
        let l = t > 0
            ? hsl.l + (100 - hsl.l) * t   // toward white
            : hsl.l * (1 + t)             // toward black
        let rgb = ColorMath.hslToRGB(h: hsl.h, s: hsl.s, l: l)
        return RGBA(r: rgb.r, g: rgb.g, b: rgb.b, a: a)
    }
}

/// HSL conversion + the palette-shift used by hue/sat/light sliders.
/// All formulas mirror the JS in the HTML reference so output matches.
enum ColorMath {
    static func rgbToHSL(_ c: RGBA) -> (h: Double, s: Double, l: Double) {
        let r = c.r / 255, g = c.g / 255, b = c.b / 255
        let maxV = max(r, g, b), minV = min(r, g, b)
        var h = 0.0, s = 0.0
        let l = (maxV + minV) / 2
        if maxV != minV {
            let d = maxV - minV
            s = l > 0.5 ? d / (2 - maxV - minV) : d / (maxV + minV)
            if maxV == r {
                h = (g - b) / d + (g < b ? 6 : 0)
            } else if maxV == g {
                h = (b - r) / d + 2
            } else {
                h = (r - g) / d + 4
            }
            h *= 60
        }
        return (h, s * 100, l * 100)
    }

    static func hslToRGB(h: Double, s: Double, l: Double) -> RGBA {
        let sN = s / 100, lN = l / 100
        let hN = (h.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        func k(_ n: Double) -> Double {
            (n + hN / 30).truncatingRemainder(dividingBy: 12)
        }
        let a = sN * min(lN, 1 - lN)
        func f(_ n: Double) -> Double {
            lN - a * max(-1, min(min(k(n) - 3, 9 - k(n)), 1))
        }
        return RGBA(r: f(0) * 255, g: f(8) * 255, b: f(4) * 255, a: 1)
    }

    /// Mirrors shiftPaletteColor(): hue rotates, saturation scales around a
    /// baseline of 20, lightness shifts around a baseline of 45. At baseline
    /// (hue=0, sat=20, light=45) the operation is a no-op — input colors come
    /// back exactly, so a pattern that wants to preserve fixed colors by default
    /// still gets them at the slider defaults.
    static func paletteShift(_ color: RGBA,
                             hue: Double, sat: Double, light: Double) -> RGBA {
        var (h, s, l) = rgbToHSL(color)
        h = (h + hue).truncatingRemainder(dividingBy: 360)
        s = max(0, min(100, s * (sat / 20)))
        l = max(5, min(95, l + (light - 45)))
        var out = hslToRGB(h: h, s: s, l: l)
        out.a = color.a    // preserve original alpha
        return out
    }

    static func paletteShift(_ hex: String,
                             hue: Double, sat: Double, light: Double) -> RGBA {
        paletteShift(RGBA(hex: hex), hue: hue, sat: sat, light: light)
    }
}
