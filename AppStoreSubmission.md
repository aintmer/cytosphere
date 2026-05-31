# Cytosphere — App Store Connect Submission Guide

Self-driving checklist to finish the listing and hit **Submit for Review**.
Copy/paste blocks are exact; just paste into the matching ASC field.

App: **Cytosphere** · bundle `com.aintmer.TrajectoryWallpaper` · team `F6GPTM54F7`
Model: **Free** download + one IAP (`com.aintmer.cytosphere.unlock_all`, €9.99)
to unlock all patterns (2 free: `.mitosis`, `.organellesSketch`).

---

## 0 · Verify first (5 min) — avoids review rejections

- [x] **Privacy Policy URL is LIVE** — verified: `…/cytosphere`, `/privacy`, `/support` all return HTTP 200. ✅
- [x] **Pattern count reconciled** — copy now says **Thirteen** (the picker has 13 patterns; the 11 description bullets cover all 13 via the "Atomic orbitals — hybrid + schematic" and "Cell organelles — sketch + textbook" groupings). ✅
- [ ] **IAP is attached to this version** (see §4). A new app's first IAP must be submitted *with* the app, or review can't see it.
- [ ] **iOS vs Mac record.** Cytosphere is one multiplatform app. In ASC the app has platform tabs — **iOS** (iPhone+iPad screenshots) and **macOS** (Mac screenshots). If they're two separate app records instead, do each separately.

---

## 1 · Screenshots

Files are ready at `~/Desktop/CytosphereScreenshots/upload/`, ordered `01`–`06`,
all at exact spec.

ASC → **My Apps → Cytosphere → [1.0 version] → Previews and Screenshots**.

| Slot (in ASC) | Drag these | Size |
|---|---|---|
| **iPhone 6.9″ Display** (iOS tab) | `upload/iphone/01–06.png` | 1320×2868 |
| **iPad 13″ Display** (iOS tab) | `upload/ipad/01–06.png` | 2064×2752 |
| **Mac** (macOS tab) | `upload/mac/01–06.png` | 2880×1800 |

- Drag all 6 of a set in at once; reorder by dragging. **The first one is the hero** (shows largest in search) — lead with a colorful clean preview, not a settings panel.
- iPhone 6.9″ is the only required iPhone size — Apple auto-scales it down for smaller phones.
- Minimum 1 per slot, max 10.

---

## 2 · Version page — copy/paste

**Name** (30):
```
Cytosphere
```

**Subtitle** (30) — "Scientific wallpapers, generated" is 31, too long. Use:
```
Wallpapers from real science
```

**Promotional Text** (170, editable anytime without review):
```
Thirteen generative patterns rendered natively up to 16K. Atomic orbitals, mitosis, viral capsids, neutrophils, Feynman diagrams — and eight more. No AI. No tracking.
```

**Description** (4000):
```
Cytosphere generates large-format wallpapers from real scientific imagery.

Thirteen generative patterns drawn from biology, chemistry, and physics. Every wallpaper is a unique procedural composition — rendered natively at up to 16K, no two ever the same.

PATTERNS
• Blood elements — full hematopoietic lineage from CC-BY-SA Wikipedia sources
• Mitosis — cell division through every phase (prophase to cytokinesis)
• Atomic orbitals — hybrid clouds and clean textbook schematics
• Viral capsids — eight morphologies including T4 bacteriophages
• Electric & magnetic fields — actual field-line integration via Runge-Kutta
• Bohr atoms — the iconic nucleus + orbital electron diagram
• Feynman diagrams — particle physics interaction vertices
• Molecular structures — benzene, cyclohexane, naphthalene, and more
• Bacterial morphology — cocci, bacilli, spirilla
• Cell organelles — sketch + textbook styles
• Parasites — protozoa and helminth eggs

CONTROLS
Fine-grained sliders for color, density, depth-of-field, element scale, opacity, and per-cell hue. Every change re-renders the preview instantly. Pinch to zoom in and inspect detail. Save your favorite configurations as presets.

EXPORTS
Pick your aspect (square, iPhone portrait, iPad portrait, custom) and resolution (Standard 6K, High 10K, Ultra 16K). Saves directly to Photos on iPhone/iPad, with full save-panel control on Mac.

PRIVACY
No accounts. No ads. No analytics. The app runs entirely on your device and makes no outbound network connections of its own — the only thing that touches Apple's servers is the standard in-app-purchase verification, handled by iOS itself.

ACCESSIBILITY
Full Dynamic Type support. VoiceOver labels on every control. High-contrast aware. Built natively in SwiftUI for the Apple platform.

Made with care for people who love science.
```
*(Note: I added a "Pinch to zoom" line to CONTROLS to match the new feature.)*

**Keywords** (100, no spaces after commas):
```
wallpaper,science,generative,biology,physics,chemistry,4K,16K,microscopy,cell,orbital,molecule
```

**What's New** (release notes for 1.0):
```
Initial release. Thirteen generative patterns from biology, chemistry, and physics. Rendered natively up to 16K.

If you love it, leaving a review helps a lot. Thank you for trying Cytosphere.
```

**Support URL**: `https://aintmer.github.io/cytosphere/support`
**Marketing URL**: `https://aintmer.github.io/cytosphere`
**Privacy Policy URL**: `https://aintmer.github.io/cytosphere/privacy`

**Category** — Primary: **Graphics & Design** · Secondary: **Education**
**Age Rating** — answer every question "None/No" → **4+**

---

## 3 · App Privacy

ASC → **App Privacy → Get Started / Edit**:
- "Do you collect data from this app?" → **No, we do not collect data**.
- Result label: **Data Not Collected**. Leave every category unchecked.
- (TelemetryDeck was removed from the build, so this is accurate.)

---

## 4 · Pricing & In-App Purchase

- **Pricing**: ASC → **Pricing and Availability** → Price = **Free** (€0). Availability = all territories (or your choice).
- **IAP**: ASC → **In-App Purchases** → confirm `com.aintmer.cytosphere.unlock_all` is **Ready to Submit** (paywall screenshot already uploaded ✅).
- **CRITICAL — attach it to the version**: on the **1.0 version page**, scroll to **In-App Purchases** section → **+** → add `unlock_all`. A new app's first IAP only gets reviewed if it's attached to the version being submitted.

---

## 5 · Build → upload → select

Per platform (iOS, then macOS). In **Xcode** on the `ui/liquid-glass-editor` branch (or after merging to `main`):

**iOS build:**
1. Toolbar destination → **Any iOS Device (arm64)**.
2. **Product → Archive**. (If "Archive" is greyed, you're on a sim/device destination — switch to "Any iOS Device".)
3. Organizer opens → select the archive → **Distribute App → App Store Connect → Upload** → keep defaults → Upload.
4. Wait ~5–15 min for "Processing" to finish (you'll get an email).

**macOS build:** same, with destination **Any Mac** → Archive → Distribute → App Store Connect.

**Select the build:** on the 1.0 version page → **Build** section → **+** → pick the processed build (one for iOS, one for macOS under their platform tabs).

> Encryption prompt on upload: Cytosphere uses no non-exempt encryption (no custom crypto, no network). Answer **No** — or it's already handled if `ITSAppUsesNonExemptEncryption = NO` is in Info.plist.

---

## 6 · Submit

On the version page, top right → **Add for Review / Submit for Review**. You'll answer:
- **Export Compliance**: No (per above).
- **Content Rights**: the blood-cell artwork is CC-BY-SA Wikipedia — you have the right to use it *with attribution*. Attribution lives in the app (About) and the JSON `_attribution`. Answer that you have the rights. (Keep the attribution visible in-app — it's there.)
- **Advertising Identifier (IDFA)**: No.

Then **Submit**. Status → "Waiting for Review" (typically 24–48h).

---

## One-glance final checklist

- [ ] Screenshots: iPhone 6.9″ + iPad 13″ (iOS tab), Mac (macOS tab)
- [ ] Name / Subtitle / Promo / Description / Keywords / What's New
- [ ] Support + Marketing + **Privacy Policy (live!)** URLs
- [ ] Category (Graphics & Design) · Age 4+
- [ ] App Privacy = Data Not Collected
- [ ] Price = Free · IAP `unlock_all` **attached to the version**
- [ ] iOS build + macOS build uploaded, processed, **selected**
- [ ] Export compliance / content rights / IDFA answered
- [ ] Pattern count made consistent (§0)
- [ ] **Submit for Review**
