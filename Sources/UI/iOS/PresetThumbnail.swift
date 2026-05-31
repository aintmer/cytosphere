import SwiftUI
import CoreGraphics
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Renders a small wallpaper preview for a saved preset and caches the
/// resulting image in memory. First appearance kicks off a background render;
/// subsequent appearances of the same preset hit the cache.
///
/// Cross-platform: uses UIImage on iOS / iPadOS, NSImage on macOS. View code
/// uses `swiftUIImage(...)` to render either backend through a single
/// `Image(_:)` initializer call.
@MainActor
@Observable
final class PresetThumbnailStore {
    private var images: [Int: PlatformImage] = [:]
    private var inFlight: Set<Int> = []

    func image(for preset: Preset) -> PlatformImage? {
        images[preset.config.hashValue]
    }

    func warm(_ preset: Preset, size: CGSize) {
        let key = preset.config.hashValue
        if images[key] != nil || inFlight.contains(key) { return }
        inFlight.insert(key)
        let config = preset.config
        Task.detached(priority: .userInitiated) {
            let rendered = WallpaperImageRenderer.image(config: config,
                                                        pixelSize: size)
            await MainActor.run {
                if let rendered {
                    self.images[key] = rendered
                }
                self.inFlight.remove(key)
            }
        }
    }
}

/// View-helper: produce a SwiftUI `Image` from whichever PlatformImage type
/// is in use. Saves callers from `#if`-ing in their bodies.
extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #else
        self.init(systemName: "questionmark")
        #endif
    }
}
