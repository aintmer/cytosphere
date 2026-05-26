import SwiftUI

/// Live preview. `config` is an Equatable value, so the view re-initialises
/// (and the Canvas re-renders) exactly when a setting changes — nothing more.
struct CanvasView: View {
    let config: RenderConfig
    let aspect: AspectPreset

    var body: some View {
        Canvas { context, size in
            context.withCGContext { cg in
                WallpaperRenderer.draw(in: cg, size: size, config: config)
            }
        }
        .aspectRatio(aspect.ratio, contentMode: .fit)
        .background(Color.black)
    }
}
