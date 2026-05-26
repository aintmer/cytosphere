# Marketing screenshots

App Store Connect needs at least 3 screenshots per device family, max 10.
For Cytosphere, the most compelling screenshots are the **wallpapers
themselves** rendered at the device's native aspect ratio, because that's
literally what the app produces and what users are buying.

This doc has two parts:
1. **Recommended set** — a curated list of 6 striking pattern + setting
   combinations that show off the range of the app.
2. **Step-by-step capture** — how to actually produce each PNG at the
   App Store-required sizes.

---

## App Store size requirements (as of 2026)

Apple has been simplifying these. The currently required minimum is:

| Device family | Required size | Notes |
|---|---|---|
| iPhone 6.9" (16 Pro Max) | 1290 × 2796 portrait | **Required for new apps** |
| iPad 13" (M4 Pro) | 2064 × 2752 portrait | Required if app supports iPad |
| Mac | 2880 × 1800 | Required if app supports Mac |

You can also upload 6.5" iPhone (1284 × 2778) and older sizes, but Apple
auto-scales the 6.9" up/down if you don't.

---

## The recommended showcase set

Below are six configurations hand-picked to demonstrate the visual range.
Each one is named so you can save it as a preset, then export at every
size you need.

### 1. "Cell carnival" — Mitosis × Void (already a starter preset)
- **Pattern**: Mitosis
- **Background**: Deep void
- **Hue**: 280° (purple)
- **Saturation**: 35
- **Density**: 1.0
- **Why**: Iconic, biological, shows the "procedural cells" style.

### 2. "Bohr blueprint" — Bohr atoms × Aurora (already a starter preset)
- **Pattern**: Bohr atoms
- **Background**: Cool aurora
- **Hue**: 200° (blue)
- **Saturation**: 40, **Lightness**: 55
- **Why**: Clean, schematic, instantly readable as "science."

### 3. "Coral hematopoiesis" — Blood × Coral (already a starter preset)
- **Pattern**: Blood elements (hematopoiesis)
- **Background**: Warm coral
- **Hue**: 15° (warm red-orange)
- **Saturation**: 25
- **Why**: Wide variety of cell shapes, warm palette, anatomical.

### 4. "Amber capsids" — Viruses × Amber (already a starter preset)
- **Pattern**: Viral capsids
- **Background**: Dark amber
- **Hue**: 30° (gold)
- **Saturation**: 45
- **Why**: Geometric, striking, very different aesthetic.

### 5. "Orbital storm" — Orbitals (hybrid) × Forest (new)
- **Pattern**: Atomic orbitals — hybrid
- **Background**: Deep forest
- **Hue**: 140° (teal-green)
- **Saturation**: 50, **Lightness**: 55
- **Element scale**: 1.2
- **Depth of field**: 1.5
- **Why**: Soft, dreamy, completely different from the schematic patterns.
- **Seed**: try 3141, 2718, 1618 for nice arrangements.

### 6. "Field static" — Fields × Black (new)
- **Pattern**: Electric & magnetic fields
- **Background**: Pure black
- **Hue**: 60° (yellow-green)
- **Saturation**: 50, **Lightness**: 60
- **Density**: 0.7 (so fields aren't crowded)
- **Why**: High-contrast, dramatic, shows the math-y / physics side.

---

## Step-by-step: capture each screenshot

### Method A — Mac (native, fastest)

1. Open Cytosphere on Mac.
2. From the **Presets** panel, tap the first showcase preset (or build one
   from scratch using the recipe above).
3. Set **Aspect** to **iPhone portrait — 1320 × 2868** for iPhone screenshots
   or **iPad portrait — 2048 × 2732** for iPad screenshots.
4. Set **Export quality** to **Standard 6K** (sufficient for App Store; faster
   to render).
5. Tap **Export PNG**, save to `~/Desktop/CytosphereScreenshots/`.
6. Repeat for each of the 6 showcases at each aspect.

You'll end up with 12-18 PNG files: ~6 iPhone shots + ~6 iPad shots + Mac shots.

### Method B — iOS Simulator (for "app UI" screenshots, optional)

If you want screenshots that show the actual app UI (sidebar, preview canvas,
etc.) — Apple sometimes prefers these to pure-output shots — run the app
in the iPhone 16 Pro Max simulator and use **Cmd-S** to save a screenshot.

```bash
# Launch the simulator
xcrun simctl boot "iPhone 16 Pro Max"
open -a Simulator
# Build + install + run via Xcode (⌘R with the simulator selected)
# Then in the simulator: File → Save Screen ( ⌘S )
```

A mix works well — 2-3 "what it produces" wallpaper exports + 2-3 "what it
looks like in use" UI shots.

### Method C — Real iPhone (waiting on Apple Developer activation)

Once your Developer enrollment activates + you've registered your iPhone:
1. Run the app on your iPhone via Xcode (⌘R with iPhone selected)
2. Configure each showcase, then press Side+Volume Up to take a screenshot
3. AirDrop to Mac, drop into your screenshots folder

This route gives you "real device" screenshots with the actual iOS UI chrome,
which look the most authentic on the App Store.

---

## Where to put them for the App Store submission

When you're in App Store Connect filling out the listing:
1. **iOS App** section → **App Previews and Screenshots**
2. Select the **iPhone 6.9"** dropdown
3. Drag your 6 files in, in the order you want them displayed
4. Repeat for **iPad 13"** dropdown
5. Repeat for **Mac** dropdown

Apple shows the FIRST screenshot prominently in search results, so make it
your strongest one. Recommendation:

- iPhone first slot: **"Coral hematopoiesis"** (warm, recognizable, shows
  variety of element types)
- iPad first slot: **"Orbital storm"** (dreamy, shows the depth-of-field
  feature uniquely well)
- Mac first slot: any landscape-orientation export looks best on Mac

---

## When you're done: feed them back into the landing page

The landing page at `docs/index.html` has 4 placeholder slots at the
"Sample exports" section. Drop your 4 best PNGs into `docs/assets/` as:

- `docs/assets/sample-1.png`
- `docs/assets/sample-2.png`
- `docs/assets/sample-3.png`
- `docs/assets/sample-4.png`

…and replace the four `<div class="shot placeholder"></div>` elements
with `<div class="shot"><img src="assets/sample-N.png" alt="..."></div>`.

I can do that swap for you once you have the files — just tell me which
files to use.
