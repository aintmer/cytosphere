import CoreGraphics
import Foundation

/// Renders the wallpaper to a full-resolution bitmap. No WebView canvas limit
/// applies here — the only ceiling is device memory (see DeviceCapabilities).
enum PNGExporter {
    /// Pixel size for an aspect + quality tier: the quality dimension is applied
    /// to the longest side, the other side follows the aspect ratio.
    static func pixelSize(aspect: AspectPreset, quality: ExportQuality) -> CGSize {
        let longest = CGFloat(quality.dimension)
        let ratio = aspect.ratio
        if ratio >= 1 {
            return CGSize(width: longest, height: longest / ratio)
        } else {
            return CGSize(width: longest * ratio, height: longest)
        }
    }

    /// Render to a CGImage at the requested pixel size.
    static func renderImage(config: RenderConfig, pixelSize: CGSize) -> CGImage? {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        guard width > 0, height > 0,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cg = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }

        // Flip to a top-left origin so pattern code matches the SwiftUI Canvas
        // coordinate space (Canvas is y-down; a raw CGContext is y-up).
        cg.translateBy(x: 0, y: CGFloat(height))
        cg.scaleBy(x: 1, y: -1)

        WallpaperRenderer.draw(in: cg,
                               size: CGSize(width: width, height: height),
                               config: config)
        return cg.makeImage()
    }

    // NOTE: platform-specific saving (PHPhotoLibrary on iOS, NSSavePanel on
    // macOS) is wired up in the dedicated export session — see the project
    // README's task list.
}
