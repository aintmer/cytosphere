# Trajectory Wallpaper — native macOS + iOS app

Native SwiftUI port of the procedural science-wallpaper generator
(`wallpaper-v6-hema.html`). One codebase, both platforms.

## Getting it to build

You need **Xcode 16 or newer**. Two routes — pick one.

### Route A — manual Xcode project (no extra tools)

1. Open Xcode → **File ▸ New ▸ Project…**
2. Choose **Multiplatform ▸ App**. Next.
3. Product Name: `TrajectoryWallpaper`. Interface: **SwiftUI**. Language: **Swift**.
   Uncheck Core Data / Tests. Save it **inside this folder** (`~/Developer/TrajectoryWallpaper`).
4. Xcode created its own `ContentView.swift` and `…App.swift` — **delete both**
   from the project (move to Trash).
5. Drag the **`Sources`** folder from Finder into the Xcode project navigator.
   In the dialog: tick **"Copy items if needed"** is OFF (the files already live
   here), choose **"Create groups"**, and make sure the app target is checked.
6. Set the **deployment targets**: iOS 17.0, macOS 14.0 (project ▸ target ▸ General).
7. Build & run (⌘R). Pick a Mac or iPhone simulator destination.

### Route B — XcodeGen (reproducible project file)

```
brew install xcodegen          # one-time, ~5 MB, MIT-licensed
cd ~/Developer/TrajectoryWallpaper
xcodegen generate
open TrajectoryWallpaper.xcodeproj
```

`project.yml` already describes the target. Re-run `xcodegen generate` any time
you add files.

## What works in this scaffold

- Full UI: pattern / background / aspect pickers, all sliders, re-roll, quality picker.
- Live `Canvas` preview that re-renders on every setting change.
- A **placeholder pattern** (scattered translucent cells) so the sliders are
  visibly wired up. Real patterns replace it one by one.
- Background presets + the background-lightness shift.
- Device-aware export quality tiers (Standard 6K / High 10K / Ultra 16K).
- `PNGExporter` that renders to a full-resolution `CGImage` (no WebView limit).

## What's still stubbed

- Real patterns (mitosis, parasites, blood, …) — `WallpaperRenderer` falls
  through to `PlaceholderPattern` until each `case` is filled in.
- The placement engine (`placeWithLayers` equivalent) — layered depth-of-field.
- Export *saving* — `PNGExporter` produces the image; writing it to the Photos
  library (iOS) / a Save panel (macOS) is the next piece.
- App icon, launch screen, haptics, native menus.

## Build order (one Claude session per line)

1. ✅ Scaffold (this).
2. Placement engine: `placeWithLayers` + depth-of-field layers.
3. Port **Mitosis** end-to-end — validates the engine against the HTML.
4. Port **Parasites** + **Bacteria**.
5. Extract Hematopoiesis symbols → JSON + write the SVG-path parser.
6. Port **Blood** using the parsed symbols.
7. Port the remaining patterns (orbitals, fields, bohr, feynman, molecules,
   viruses, organelles ×2).
8. Export pipeline: Photos save (iOS) + Save panel (macOS) + progress UI.
9. Polish: app icon, haptics, native menus, pattern thumbnails.
10. TestFlight → App Store submission.

## Layout

```
Sources/
  App/        TrajectoryWallpaperApp.swift, ContentView.swift
  Models/     AppState, RenderConfig, Pattern, Background, AspectPreset,
              DeviceCapabilities
  Rendering/  PRNG, ColorMath, WallpaperRenderer, Patterns/
  UI/         CanvasView, SidebarView, SliderRow
  Export/     PNGExporter
```

`AppState` (mutable, `@Observable`) ⟶ `RenderConfig` (immutable snapshot) ⟶
`WallpaperRenderer.draw(in:size:config:)` — the same call drives both the
preview and the export.
