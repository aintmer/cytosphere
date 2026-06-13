import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import Photos
import UIKit
#endif

/// End-to-end PNG export: renders the wallpaper at full target resolution on a
/// background task (so the UI stays responsive), then writes it out. On macOS
/// the user picks a location with NSSavePanel; on iOS it lands in the Photos
/// library. The `status` closure feeds the button label so the UI can show
/// "Rendering…" / "Saving…" / a final success or failure message.
@MainActor
enum Exporter {

    enum Status: Equatable {
        case idle
        case rendering
        case saving
        case success(String)
        case failure(String)
        /// Photos write access was denied or restricted (iOS). Kept distinct
        /// from a generic `failure` so the UI can offer an actionable "Open
        /// Settings" button instead of a dead-end "Tap to open Settings" line.
        case failurePhotosDenied
    }

    static func export(config: RenderConfig,
                       aspect: AspectPreset,
                       quality: ExportQuality,
                       status: @MainActor (Status) -> Void) async {
        status(.rendering)
        let pixelSize = PNGExporter.pixelSize(aspect: aspect, quality: quality)
        Telemetry.track(.exportStarted, [
            "pattern": config.pattern.rawValue,
            "quality": quality.rawValue,
            "aspect":  aspect.rawValue,
        ])

        // Hold a background-task assertion for the lifetime of this export so
        // the OS doesn't suspend us if the user switches apps mid-render. The
        // expiration handler flips the flag below; we check it after the
        // detached render returns and surface a clear error if we lost time.
        var didExpire = false
        let guardian = BackgroundTaskGuard(name: "Export PNG") {
            didExpire = true
        }
        defer { guardian.end() }

        let renderStart = Date()
        // autoreleasepool: per-layer offscreen bitmaps at Ultra are hundreds
        // of MB each. Without the pool they accumulate until the detached
        // Task returns and can OOM on iOS.
        let cg: CGImage? = await Task.detached(priority: .userInitiated) {
            autoreleasepool {
                PNGExporter.renderImage(config: config, pixelSize: pixelSize)
            }
        }.value
        let renderSeconds = Date().timeIntervalSince(renderStart)
        print(String(format: "Export render: %.2fs (%dx%d, %@)",
                     renderSeconds, Int(pixelSize.width), Int(pixelSize.height),
                     config.pattern.rawValue))

        // If iOS forced us to give up the background-task assertion, the
        // render result may be incomplete or arriving too late to save —
        // tell the user clearly instead of pretending success.
        if didExpire {
            Telemetry.track(.exportExpired, [
                "pattern": config.pattern.rawValue,
                "quality": quality.rawValue,
            ])
            status(.failure("Export interrupted — keep the app in the foreground while exporting."))
            return
        }

        guard let cg else {
            status(.failure("Render failed"))
            Telemetry.track(.exportFailed, [
                "pattern": config.pattern.rawValue,
                "reason":  "render_returned_nil",
            ])
            return
        }
        status(.saving)
        do {
            let message = try await save(cg, defaultName: filename(config, aspect, quality))
            status(.success(message))
            Telemetry.track(.exportSucceeded, [
                "pattern":  config.pattern.rawValue,
                "quality":  quality.rawValue,
                "duration": String(format: "%.1f", renderSeconds),
            ])
        } catch ExportError.cancelled {
            status(.idle)
        } catch ExportError.photosAccessDenied {
            status(.failurePhotosDenied)
            Telemetry.track(.exportFailed, [
                "pattern": config.pattern.rawValue,
                "reason":  "photos_denied",
            ])
        } catch {
            status(.failure(error.localizedDescription))
            Telemetry.track(.exportFailed, [
                "pattern": config.pattern.rawValue,
                "reason":  "\(error)",
            ])
            Telemetry.recordError(error)
        }
    }

    private static func filename(_ c: RenderConfig,
                                 _ a: AspectPreset,
                                 _ q: ExportQuality) -> String {
        "wallpaper-\(c.pattern.rawValue)-\(c.background.rawValue)-\(a.rawValue)"
            + "-\(q.dimension)-\(c.seed).png"
    }

    // MARK: - Platform save -------------------------------------------------

    #if os(macOS)
    private static func save(_ image: CGImage, defaultName: String) async throws -> String {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        let response = await panel.begin()
        guard response == .OK, let url = panel.url else { throw ExportError.cancelled }
        try await Task.detached(priority: .userInitiated) {
            try writePNG(image, to: url)
        }.value
        return url.lastPathComponent
    }
    #else
    private static func save(_ image: CGImage, defaultName: String) async throws -> String {
        let auth = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard auth == .authorized || auth == .limited else {
            // Surfaced specifically so the UI can offer a "Open Settings"
            // button — a plain text error is a dead end when the OS won't
            // re-prompt after a previous denial.
            throw ExportError.photosAccessDenied
        }

        // Stream the PNG to a temp file first, then hand it to Photos by URL
        // instead of holding the full UIImage in memory. At Ultra quality
        // the bitmap is ~1 GB; the temp-file path lets PHAssetCreationRequest
        // import via `addResource(with:fileURL:)` without doubling memory
        // pressure (which would OOM on iPhones with ≤6 GB RAM).
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cytosphere-\(UUID().uuidString).png")
        try await Task.detached(priority: .userInitiated) {
            try writePNG(image, to: tempURL)
        }.value
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true   // Photos takes ownership; no copy
            request.addResource(with: .photo, fileURL: tempURL, options: options)
        }
        return "Saved to Photos"
    }
    #endif

    /// Shared PNG writer — used by macOS (NSSavePanel target URL) and iOS
    /// (temp-file then Photos import). `nonisolated` so background tasks can
    /// call it without main-actor hops.
    nonisolated private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { throw ExportError.failed("Could not create image destination") }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw ExportError.failed("Could not write PNG")
        }
    }

    enum ExportError: LocalizedError {
        case cancelled
        case failed(String)
        case photosAccessDenied
        var errorDescription: String? {
            switch self {
            case .cancelled:           return "Cancelled"
            case .photosAccessDenied:  return "Photos access denied. Tap to open Settings."
            case .failed(let msg):  return msg
            }
        }
    }
}
