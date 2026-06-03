# Resubmitting Cytosphere iOS 1.0 after the Guideline 4 rejection

**Context:** App Review rejected **iOS 1.0 (build 1)** under **Guideline 4 (Design)** —
on iPad the inspector was clipped off-screen and text truncated. Fixed in commit
`715d303` (gated the macOS `minWidth: 920` window-floor to macOS only; made `MenuRow`
adapt to Dynamic Type). Build number bumped to **1.0 (2)**. Verified clean on iPad Air 11"
and iPad mini, portrait + landscape, default + accessibility text sizes.

**macOS 1.0 is NOT affected** — it's still "Waiting for Review." Leave it alone.

---

## Step 1 — Open the project & confirm version
1. Open `~/Developer/TrajectoryWallpaper/TrajectoryWallpaper.xcodeproj` in Xcode.
2. Select the **TrajectoryWallpaper** scheme (top bar).
3. Confirm version: target → General → Identity shows **Version 1.0**, **Build 2**.
   (Already set in the project — `CURRENT_PROJECT_VERSION = 2`.)

## Step 2 — Archive (iOS)
1. Set the run destination to **Any iOS Device (arm64)** — NOT a simulator.
   (Archiving for the App Store requires a device/generic destination.)
2. Menu: **Product → Archive**. Wait for the build + archive to finish.
3. The **Organizer** opens. Confirm the new archive reads **1.0 (2)** and platform **iOS**.

## Step 3 — Upload to App Store Connect
1. In Organizer, select the **1.0 (2)** archive → **Distribute App**.
2. Choose **App Store Connect → Upload**.
3. Keep the defaults (automatic signing, symbols on) → **Upload**.
4. Wait ~10–30 min for processing. You'll get an email when build 2 finishes processing
   (or watch ASC → app → TestFlight/Build activity).

## Step 4 — Attach build 2 & resubmit (iOS only)
1. App Store Connect → **Apps → Cytosphere → iOS App 1.0** (it shows **Rejected**).
2. In the **Build** section, click the build and **select 1.0 (2)** (replaces build 1).
   It appears once processing is done. **Save**.
3. Click **Add for Review** / **Resubmit to App Review** (top-right) → confirm the
   export-compliance / IDFA prompts as before (No to IDFA) → **Submit**.
4. *(Recommended)* In the **Resolution Center** message thread, reply to the reviewer —
   it speeds re-review:

   > Thank you for the feedback. We resolved the iPad layout issue in build 2: the
   > inspector panel no longer extends off-screen and text is no longer truncated. We
   > verified on iPad Air 11" and iPad mini in both portrait and landscape, including
   > large Dynamic Type sizes. Thank you for re-reviewing.

## Step 5 — Wait for re-review
- Re-review for a design fix is typically **~24–48h**.
- On approval, since release is set to **Automatically release**, the iOS app goes live
  on its own. macOS will release independently when its review completes.
- If anything else is flagged, it'll appear in the Resolution Center — fix and resubmit.

---

## Notes / gotchas
- **Don't re-archive macOS.** Its build is already in review and unaffected by this fix.
- **No metadata changes needed** — screenshots, description, keywords, privacy, pricing,
  IAP, age rating, category are all unchanged and still valid.
- The **IAP "Unlock All Patterns"** is already attached and was "Waiting for Review"; it
  rides along with the version resubmission.
- If the upload errors with "build number already used," the build wasn't bumped — confirm
  Build = 2 in Step 1 and re-archive.
