#!/usr/bin/env swift
//
// render_app_icon.swift — generates AppIcon.appiconset for Cytosphere.
//
// Run from the project root:
//   ./Scripts/render-icon
//
// The icon design comes from a hand-tuned SVG prototype: ~14 chunky cells
// clustered into a spheroid silhouette on a pale lavender ground, with
// depth-shaded fills, front-facing nuclei, ground shadow, and a specular
// highlight. The cell data is encoded as a static array (rather than
// procedurally generated like earlier iterations) so the icon matches the
// exported SVG pixel-for-pixel at every output size.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Color

struct C {
    let r, g, b, a: CGFloat
    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = CGFloat(r); self.g = CGFloat(g); self.b = CGFloat(b); self.a = CGFloat(a)
    }
    init(rgb255 r: Int, _ g: Int, _ b: Int, _ a: Double = 1) {
        self.r = CGFloat(r) / 255; self.g = CGFloat(g) / 255; self.b = CGFloat(b) / 255
        self.a = CGFloat(a)
    }
    init(hex: String, _ a: Double = 1) {
        var s = hex; if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0
        self.r = CGFloat((v >> 16) & 0xFF) / 255
        self.g = CGFloat((v >> 8)  & 0xFF) / 255
        self.b = CGFloat( v        & 0xFF) / 255
        self.a = CGFloat(a)
    }
    func alpha(_ a: Double) -> C { C(Double(r), Double(g), Double(b), a) }
    /// Push each channel away from the pixel's own luminance (k>1 = punchier,
    /// less washed-out). Used to give the pastel cell fills more definition.
    func saturated(_ k: Double) -> C {
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        func mix(_ c: CGFloat) -> Double { Double(max(0, min(1, lum + (c - lum) * CGFloat(k)))) }
        return C(mix(r), mix(g), mix(b), Double(a))
    }
    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
}

// MARK: - Cell data (from the SVG prototype)

/// One cell rendered as a circle with an optional, smaller offset nucleus.
/// All coordinates and radii are in the 1024-canvas space — the renderer
/// scales them down for smaller output sizes.
struct IconCell {
    let cx, cy, r: Double           // cell circle
    let fillR, fillG, fillB: Int    // rgb 0–255
    let strokeOp: Double             // depth-derived stroke opacity
    let strokeW: Double              // depth-derived stroke width
    // Nucleus is optional — only front-facing cells in the SVG get one.
    let nucleus: Nucleus?
    struct Nucleus {
        let cx, cy, r: Double
        let opacity: Double
    }
}

/// Hard-coded cells (back-to-front render order) lifted from
/// `cytosphere-icon.html` Vivid → Lavender variant export. Edit this array
/// to tweak the layout; everything else in the renderer is just scaling.
let CELLS: [IconCell] = [
    IconCell(cx: 378.7, cy: 489.7, r: 85.9,
             fillR: 133, fillG: 51, fillB: 112,
             strokeOp: 0.34, strokeW: 6.01, nucleus: nil),
    IconCell(cx: 615.6, cy: 355.8, r: 83.3,
             fillR: 142, fillG: 61, fillB: 120,
             strokeOp: 0.36, strokeW: 5.83, nucleus: nil),
    IconCell(cx: 530.3, cy: 712.8, r: 69.7,
             fillR: 145, fillG: 64, fillB: 122,
             strokeOp: 0.37, strokeW: 4.88, nucleus: nil),
    IconCell(cx: 750.1, cy: 578.9, r: 82.9,
             fillR: 158, fillG: 78, fillB: 132,
             strokeOp: 0.40, strokeW: 5.80, nucleus: nil),
    IconCell(cx: 378.3, cy: 266.6, r: 92.5,
             fillR: 173, fillG: 95, fillB: 145,
             strokeOp: 0.44, strokeW: 6.48,
             nucleus: .init(cx: 388.8, cy: 267.6, r: 51.6, opacity: 0.28)),
    IconCell(cx: 248.4, cy: 623.5, r: 95.9,
             fillR: 179, fillG: 101, fillB: 150,
             strokeOp: 0.46, strokeW: 6.71,
             nucleus: .init(cx: 243.9, cy: 627.5, r: 48.5, opacity: 0.50)),
    IconCell(cx: 512.0, cy: 802.0, r: 75.8,
             fillR: 189, fillG: 111, fillB: 157,
             strokeOp: 0.49, strokeW: 5.31,
             nucleus: .init(cx: 504.4, cy: 803.7, r: 37.1, opacity: 0.84)),
    IconCell(cx: 512.0, cy: 222.0, r: 101.1,
             fillR: 189, fillG: 111, fillB: 157,
             strokeOp: 0.49, strokeW: 7.07,
             nucleus: .init(cx: 514.4, cy: 223.7, r: 53.7, opacity: 0.84)),
    IconCell(cx: 777.1, cy: 445.1, r: 97.1,
             fillR: 207, fillG: 131, fillB: 172,
             strokeOp: 0.55, strokeW: 6.80,
             nucleus: .init(cx: 787.5, cy: 443.4, r: 46.7, opacity: 0.92)),
    IconCell(cx: 264.6, cy: 400.5, r: 93.6,
             fillR: 208, fillG: 132, fillB: 173,
             strokeOp: 0.55, strokeW: 6.55,
             nucleus: .init(cx: 275.2, cy: 393.7, r: 46.4, opacity: 0.92)),
    IconCell(cx: 398.0, cy: 757.4, r: 104.5,
             fillR: 208, fillG: 132, fillB: 173,
             strokeOp: 0.55, strokeW: 7.31,
             nucleus: .init(cx: 405.5, cy: 755.1, r: 53.5, opacity: 0.92)),
    IconCell(cx: 660.7, cy: 668.2, r: 106.7,
             fillR: 225, fillG: 150, fillB: 186,
             strokeOp: 0.60, strokeW: 7.47,
             nucleus: .init(cx: 652.9, cy: 665.3, r: 56.5, opacity: 0.92)),
    IconCell(cx: 574.6, cy: 311.2, r: 113.2,
             fillR: 226, fillG: 151, fillB: 187,
             strokeOp: 0.61, strokeW: 7.92,
             nucleus: .init(cx: 578.1, cy: 305.0, r: 64.9, opacity: 0.92)),
    IconCell(cx: 436.9, cy: 534.3, r: 109.2,
             fillR: 240, fillG: 166, fillB: 198,
             strokeOp: 0.65, strokeW: 7.64,
             nucleus: .init(cx: 439.6, cy: 522.1, r: 55.6, opacity: 0.92)),
]

// MARK: - Palette (constants that aren't per-cell)

enum Pal {
    // Background — pastel lavender (linear top-left → bottom-right)
    static let bgStart      = C(hex: "#E8DCF2")
    static let bgEnd        = C(hex: "#B89ED4")
    // Dark-appearance background (iOS Light/Dark app icon, iOS 18+) — a deep
    // purple-black so the cell cluster reads as glowing against it.
    static let bgDarkStart  = C(hex: "#1C1030")
    static let bgDarkEnd    = C(hex: "#050108")
    // Sphere base radial — interior fill so micro-gaps between cells don't show
    static let baseInner    = C(rgb255: 182, 104, 152)
    static let baseOuter    = C(hex: "#6A2078")
    // Outer glow ring (same color, 60→92→100 alpha ramp)
    static let glow         = C(hex: "#6A2078")
    // Cell stroke + nucleus colors used by every cell
    static let cellStroke   = C(hex: "#9D2D7A")
    static let nucleusFill  = C(hex: "#8B0F58")
}

// MARK: - Drawing

func drawCytosphere(_ cg: CGContext, size: Double, dark: Bool = false) {
    let cx = size / 2
    let cy = size / 2
    // All SVG coordinates are in 1024-space; multiply by this to render at
    // any target output size.
    let scale = size / 1024.0
    let sphereR     = 268.0 * scale
    let baseR       = sphereR       // base sits at the same radius as in SVG
    let glowR       = 328.0 * scale

    // The SVG uses y-down (top-left origin); CG bitmap is y-up. Flip once
    // here so every coordinate below maps 1:1 to the SVG.
    cg.translateBy(x: 0, y: CGFloat(size))
    cg.scaleBy(x: 1, y: -1)

    // -------- Background gradient (top-left → bottom-right) --------
    // Light theme = pale lavender; dark theme (iOS dark app icon) = deep
    // purple-black so the same vivid cells read as glowing.
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let bg0 = dark ? Pal.bgDarkStart : Pal.bgStart
    let bg1 = dark ? Pal.bgDarkEnd   : Pal.bgEnd
    if let g = CGGradient(colorsSpace: cs,
                          colors: [bg0.cg, bg1.cg] as CFArray,
                          locations: [0, 1]) {
        cg.drawLinearGradient(g,
            start: CGPoint(x: 0, y: 0),
            end:   CGPoint(x: size, y: size),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    // -------- Soft ground shadow (light theme only — invisible on dark) -----
    if !dark {
        cg.saveGState()
        cg.setFillColor(C(0, 0, 0, 0.28).cg)
        let shadowRx = 270.0 * scale
        let shadowRy = 28.0 * scale
        let shadowCy = 888.0 * scale
        cg.fillEllipse(in: CGRect(x: cx - shadowRx, y: shadowCy - shadowRy,
                                  width: 2 * shadowRx, height: 2 * shadowRy))
        cg.restoreGState()
    }

    // -------- Sphere base (radial fill inside the cell cluster) --------
    let baseBox = CGRect(x: cx - baseR, y: cy - baseR,
                         width: 2 * baseR, height: 2 * baseR)
    if let baseGrad = CGGradient(colorsSpace: cs,
                                 colors: [Pal.baseInner.cg, Pal.baseOuter.cg] as CFArray,
                                 locations: [0, 1]) {
        cg.saveGState()
        cg.addEllipse(in: baseBox)
        cg.clip()
        // SVG radial gradient cx=0.42, cy=0.4, r=0.55 — replicate using
        // absolute coordinates inside the base box.
        let gx = baseBox.minX + baseBox.width * 0.42
        let gy = baseBox.minY + baseBox.height * 0.40
        let gR = baseBox.width * 0.55
        cg.drawRadialGradient(baseGrad,
            startCenter: CGPoint(x: gx, y: gy), startRadius: 0,
            endCenter:   CGPoint(x: gx, y: gy), endRadius: gR,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        cg.restoreGState()
    }

    // -------- Outer perimeter glow --------
    let glowBox = CGRect(x: cx - glowR, y: cy - glowR,
                         width: 2 * glowR, height: 2 * glowR)
    // Brighter glow peak on dark so the perimeter reads as luminous.
    let glowPeak = dark ? 0.9 : 0.55
    let glowGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            Pal.glow.alpha(0).cg,
            Pal.glow.alpha(0).cg,
            Pal.glow.alpha(glowPeak).cg,
            Pal.glow.alpha(0).cg,
        ] as CFArray,
        locations: [0, 0.60, 0.92, 1.0]
    )
    if let glowGrad {
        cg.saveGState()
        cg.addEllipse(in: glowBox)
        cg.clip()
        let gx = glowBox.minX + glowBox.width * 0.50
        let gy = glowBox.minY + glowBox.height * 0.55
        let gR = glowBox.width * 0.55
        cg.drawRadialGradient(glowGrad,
            startCenter: CGPoint(x: gx, y: gy), startRadius: 0,
            endCenter:   CGPoint(x: gx, y: gy), endRadius: gR,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        cg.restoreGState()
    }

    // -------- Cells (back-to-front, depth-shaded fill + stroke + nucleus) --
    for cell in CELLS {
        let px = cell.cx * scale
        let py = cell.cy * scale
        let r  = cell.r  * scale
        let sw = cell.strokeW * scale
        // Punchier, less-washed fills + crisper, more opaque & slightly wider
        // outlines so each cell reads as well-defined at small Home Screen sizes.
        let fill   = C(rgb255: cell.fillR, cell.fillG, cell.fillB).saturated(1.3)
        let stroke = Pal.cellStroke.alpha(min(0.95, cell.strokeOp * 1.7))

        cg.setFillColor(fill.cg)
        cg.setStrokeColor(stroke.cg)
        cg.setLineWidth(CGFloat(sw * 1.3))
        cg.addEllipse(in: CGRect(x: px - r, y: py - r, width: 2 * r, height: 2 * r))
        cg.drawPath(using: .fillStroke)

        if let n = cell.nucleus {
            let nx = n.cx * scale
            let ny = n.cy * scale
            let nr = n.r  * scale
            cg.setFillColor(Pal.nucleusFill.alpha(n.opacity).cg)
            cg.fillEllipse(in: CGRect(x: nx - nr, y: ny - nr,
                                      width: 2 * nr, height: 2 * nr))
        }
    }

    // -------- Specular highlight (top-left) --------
    drawRotatedEllipse(cg, cx: 378 * scale, cy: 318 * scale,
                       rx: 138 * scale, ry: 56 * scale,
                       angleDeg: -32, fill: C(1, 1, 1, 0.11))
    drawRotatedEllipse(cg, cx: 348 * scale, cy: 278 * scale,
                       rx:  58 * scale, ry: 20 * scale,
                       angleDeg: -32, fill: C(1, 1, 1, 0.40))
}

func drawRotatedEllipse(_ cg: CGContext, cx: Double, cy: Double,
                        rx: Double, ry: Double, angleDeg: Double, fill: C) {
    cg.saveGState()
    cg.translateBy(x: CGFloat(cx), y: CGFloat(cy))
    cg.rotate(by: CGFloat(angleDeg * .pi / 180))
    cg.setFillColor(fill.cg)
    cg.fillEllipse(in: CGRect(x: -rx, y: -ry, width: 2 * rx, height: 2 * ry))
    cg.restoreGState()
}

// MARK: - Bitmap + PNG output

func renderPNG(size: Int, to url: URL, dark: Bool = false) throws {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let cg = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw NSError(domain: "icon", code: 1) }

    cg.setShouldAntialias(true)
    cg.interpolationQuality = .high
    drawCytosphere(cg, size: Double(size), dark: dark)

    guard let img = cg.makeImage() else { throw NSError(domain: "icon", code: 2) }
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else { throw NSError(domain: "icon", code: 3) }
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "icon", code: 4) }
}

// MARK: - Contents.json

let contentsJSON = """
{
  "images" : [
    { "filename" : "mac-16.png",      "idiom" : "mac",       "scale" : "1x", "size" : "16x16" },
    { "filename" : "mac-16@2x.png",   "idiom" : "mac",       "scale" : "2x", "size" : "16x16" },
    { "filename" : "mac-32.png",      "idiom" : "mac",       "scale" : "1x", "size" : "32x32" },
    { "filename" : "mac-32@2x.png",   "idiom" : "mac",       "scale" : "2x", "size" : "32x32" },
    { "filename" : "mac-128.png",     "idiom" : "mac",       "scale" : "1x", "size" : "128x128" },
    { "filename" : "mac-128@2x.png",  "idiom" : "mac",       "scale" : "2x", "size" : "128x128" },
    { "filename" : "mac-256.png",     "idiom" : "mac",       "scale" : "1x", "size" : "256x256" },
    { "filename" : "mac-256@2x.png",  "idiom" : "mac",       "scale" : "2x", "size" : "256x256" },
    { "filename" : "mac-512.png",     "idiom" : "mac",       "scale" : "1x", "size" : "512x512" },
    { "filename" : "mac-512@2x.png",  "idiom" : "mac",       "scale" : "2x", "size" : "512x512" },
    { "filename" : "ios-1024.png",    "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "filename" : "ios-1024-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024", "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ] }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

let slots: [(file: String, px: Int, dark: Bool)] = [
    ("mac-16.png",        16,  false),
    ("mac-16@2x.png",     32,  false),
    ("mac-32.png",        32,  false),
    ("mac-32@2x.png",     64,  false),
    ("mac-128.png",      128,  false),
    ("mac-128@2x.png",   256,  false),
    ("mac-256.png",      256,  false),
    ("mac-256@2x.png",   512,  false),
    ("mac-512.png",      512,  false),
    ("mac-512@2x.png",  1024,  false),
    ("ios-1024.png",    1024,  false),
    // iOS dark-appearance variant (Light/Dark app icon, iOS 18+).
    ("ios-1024-dark.png", 1024, true),
]

let assetsContentsJSON = """
{ "info" : { "author" : "xcode", "version" : 1 } }
"""

// MARK: - Main

let projectRoot = FileManager.default.currentDirectoryPath
let assetsDir = URL(fileURLWithPath: projectRoot)
    .appendingPathComponent("Sources/Resources/Assets.xcassets")
let iconDir = assetsDir.appendingPathComponent("AppIcon.appiconset")
let renderingDir = URL(fileURLWithPath: projectRoot)
    .appendingPathComponent("Sources/Rendering")
guard FileManager.default.fileExists(atPath: renderingDir.path) else {
    FileHandle.standardError.write(Data(
        "ERROR: run this from the project root (Sources/Rendering not found here).\n".utf8
    ))
    exit(1)
}

try FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)
try assetsContentsJSON.write(to: assetsDir.appendingPathComponent("Contents.json"),
                             atomically: true, encoding: .utf8)
try contentsJSON.write(to: iconDir.appendingPathComponent("Contents.json"),
                       atomically: true, encoding: .utf8)

if let existing = try? FileManager.default.contentsOfDirectory(atPath: iconDir.path) {
    for f in existing where f.hasSuffix(".png") {
        try? FileManager.default.removeItem(at: iconDir.appendingPathComponent(f))
    }
}

for slot in slots {
    let url = iconDir.appendingPathComponent(slot.file)
    try renderPNG(size: slot.px, to: url, dark: slot.dark)
    print("✓ \(slot.file) (\(slot.px)px)\(slot.dark ? " [dark]" : "")")
}

print("\nWrote \(slots.count) PNGs + Contents.json to:")
print("  \(iconDir.path)")
