import SwiftUI

extension RGBA {
    /// SwiftUI `Color` from this **0–255** RGBA.
    ///
    /// `RGBA` stores components in 0–255 (the drawing layer's currency, see
    /// `cgColor`), but SwiftUI's `Color(red:green:blue:)` expects 0–1 — passing
    /// the raw values clamps anything above 1 to white. This accessor scales
    /// correctly and tags the color sRGB, matching `cgColor` so UI swatches and
    /// the rendered canvas agree instead of drifting in wide-gamut contexts.
    var color: Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}
