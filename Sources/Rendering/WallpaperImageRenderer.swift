import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders a `RenderConfig` to a `PlatformImage` at a given PIXEL size.
///
/// Pure CoreGraphics into an off-screen bitmap — no UIKit/AppKit drawing — so
/// it's safe to call off the main thread (and concurrently: `WallpaperRenderer`
/// keeps no shared state and seeds a fresh PRNG per call). Shared by the live
/// preview (`LivePreviewRenderer`) and the preset thumbnails
/// (`PresetThumbnailStore`) so the context setup lives in one place.
enum WallpaperImageRenderer {
    static func image(config: RenderConfig, pixelSize: CGSize) -> PlatformImage? {
        let w = Int(pixelSize.width.rounded())
        let h = Int(pixelSize.height.rounded())
        guard w > 0, h > 0 else { return nil }
        guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
              let cg = CGContext(
                data: nil, width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }

        // The renderer assumes a y-down coordinate space (top-left origin).
        // CGContext defaults to y-up, so flip before drawing.
        cg.translateBy(x: 0, y: CGFloat(h))
        cg.scaleBy(x: 1, y: -1)
        WallpaperRenderer.draw(in: cg, size: CGSize(width: w, height: h),
                               config: config)
        guard let image = cg.makeImage() else { return nil }
        #if canImport(UIKit)
        return UIImage(cgImage: image)
        #elseif canImport(AppKit)
        return NSImage(cgImage: image, size: NSSize(width: w, height: h))
        #else
        return nil
        #endif
    }
}
