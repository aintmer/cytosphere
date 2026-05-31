# Cytosphere — App Store Listing Copy

Drafts for every field App Store Connect asks for. Edit freely, this is a
starting point, not a final spec. Character limits noted next to each field.

---

## App Name (30 chars max)
**Cytosphere**

*(11/30 — short, memorable, available)*

## Subtitle (30 chars max)
**Scientific wallpapers, generated**

*(31/30 — one too long, pick one of these alternatives)*

Alternates within limit:
- **Generative science wallpapers** (30/30)
- **Wallpapers from biology + physics** (32/30 — also over)
- **Wallpapers from real science** (29/30) ✓
- **Generate science wallpapers** (27/30) ✓
- **Science wallpapers, no AI** (24/30) ✓ — playful, anti-trend
- **Biology + physics wallpapers** (27/30) ✓

Recommended: **Wallpapers from real science**

## Promotional Text (170 chars max — editable any time without re-review)
**Thirteen generative patterns rendered natively up to 16K. Atomic orbitals, mitosis, viral capsids, neutrophils, Feynman diagrams — and eight more. No AI. No tracking.**

*(~166/170)*

## Description (4000 chars max)

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
Fine-grained sliders for color, density, depth-of-field, element scale, opacity, and per-cell hue. Every change re-renders the preview instantly. Pinch to zoom in and inspect any detail. Save your favorite configurations as presets.

EXPORTS
Pick your aspect (square, iPhone portrait, iPad portrait, custom) and resolution (Standard 6K, High 10K, Ultra 16K). Saves directly to Photos on iPhone/iPad, with full save-panel control on Mac.

PRIVACY
No accounts. No ads. No analytics. The app runs entirely on your device and makes no outbound network connections of its own — the only thing that touches Apple's servers is the standard in-app-purchase verification, handled by iOS itself.

ACCESSIBILITY
Full Dynamic Type support. VoiceOver labels on every control. High-contrast aware. Built natively in SwiftUI for the Apple platform.

Made with care for people who love science.
```

*(~1750 chars — well under 4000, leaves room to grow)*

## Keywords (100 chars max — comma-separated, no spaces after commas)
```
wallpaper,science,generative,biology,physics,chemistry,4K,16K,microscopy,cell,orbital,molecule
```
*(99/100)*

These are chosen for App Store SEO. Notes on the choices:
- "wallpaper" — primary intent
- "science", "biology", "physics", "chemistry" — subject matter searches
- "generative" — differentiator (no stock photos)
- "4K", "16K" — resolution-conscious users
- "microscopy", "cell", "orbital", "molecule" — long-tail by pattern type

## What's New (in release notes — 4000 char max, per release)

**1.0**
```
Initial release. Thirteen generative patterns from biology, chemistry, and physics. Rendered natively up to 16K.

If you love it, leaving a review helps a lot. Thank you for trying Cytosphere.
```

## Support URL (required)
Will be the GitHub Pages site we set up next. Placeholder: `https://aintmer.github.io/cytosphere/support`

## Marketing URL (optional but recommended)
Same site, root: `https://aintmer.github.io/cytosphere`

## Privacy Policy URL (required)
Same site: `https://aintmer.github.io/cytosphere/privacy`

## Category
- Primary: **Graphics & Design**
- Secondary: **Education** (or Lifestyle)

## Age Rating
**4+** — no objectionable content. The wallpaper rendering is purely abstract scientific imagery.

## Pricing Tier
**Free** download. One non-consumable IAP — `com.aintmer.cytosphere.unlock_all` (€9.99) — unlocks all patterns. Two patterns ship free (Mitosis, Sketch Organelles) so first-time users get a real taste.

## Privacy Nutrition Label

Cytosphere collects **no data**. The Privacy label is the cleanest possible:

> **Data Not Collected** — The developer does not collect any data from this app.

Specifically:
- ❌ No personal data, no usage data, no analytics
- ❌ No advertising, no tracking
- ❌ No third-party SDKs that collect data
- ❌ No outbound network connections from app code (only Apple's standard
  IAP receipt verification, handled by iOS itself)

In App Store Connect → App Privacy → Data Collection, answer "No data
collected" / leave every category unchecked.

## Screenshots — required device sizes

Apple now requires only 6.9" iPhone screenshots (iPhone 16 Pro Max) for new submissions, plus a Mac set. Each set is 3-10 screenshots, 6.9" iPhone size is 1290 × 2796 (portrait) or 2796 × 1290 (landscape).

We'll generate these in the next step (the Marketing Screenshots task), choosing 4-6 hand-picked patterns/configurations that best showcase the variety.

## App Preview Video (optional)
A 15-30 second video showing pattern-switching + slider tweaks would help a lot. Can be screen-captured from the Mac app and the iPhone simulator. Lower priority for v1; add for v1.1.

---

## Quick checklist when you actually submit

- [ ] Name + subtitle filled
- [ ] Description + promotional text filled
- [ ] Keywords filled (100 chars exactly)
- [ ] Category set (Graphics & Design)
- [ ] Age rating answered (all "no" → 4+)
- [ ] Pricing tier picked (Free recommended)
- [ ] Screenshots uploaded (1 set per platform, iPhone 6.9" + iPad 13" + Mac)
- [ ] App Preview video uploaded (optional)
- [ ] Privacy nutrition label completed (per table above)
- [ ] Support URL filled
- [ ] Marketing URL filled
- [ ] Privacy Policy URL filled
- [ ] Test Build uploaded via Xcode + selected in TestFlight
- [ ] Submitted for review
