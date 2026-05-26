# In-App Purchase setup

The code-side is done. To actually sell + test the IAP you still need to:

1. **(Now)** Wire the local StoreKit Configuration file into Xcode so you can
   test the entire purchase + paywall + restore flow without App Store Connect
2. **(After Apple Developer enrollment activates)** Create the IAP in App Store
   Connect with the matching product ID, so production builds can sell it

---

## 1. Local testing — wire `Cytosphere.storekit` into Xcode

This file simulates Apple's StoreKit servers so you can hit "Unlock for
$9.99", confirm the purchase, and see the entitlement update — all without
ever publishing to App Store Connect.

1. **Add the file to the Xcode project**:
   - In Xcode, drag `Cytosphere.storekit` (at the project root) into the
     project navigator under the TrajectoryWallpaper target
   - When prompted, check "Copy items if needed" off, and make sure the
     TrajectoryWallpaper target is checked
2. **Tell the scheme to use it**:
   - Xcode → Product → Scheme → Edit Scheme… (⌘<)
   - Select **Run** in the left sidebar → **Options** tab
   - Under "StoreKit Configuration", pick **Cytosphere.storekit**
3. **Run the app** (⌘R).

You should now be able to:
- Pick any paid pattern in the picker → see 🔒 in the menu
- Tap **Unlock to export** → paywall appears with "Unlock for $9.99"
- Hit Unlock → a synthetic Apple ID confirmation appears → tap confirm
- Watch all 🔒 disappear, Export button now exports
- Quit + relaunch → entitlement persists

To reset the test purchase: Xcode → Debug → StoreKit → Manage Transactions
→ delete the transaction.

---

## 2. Production setup — create the IAP in App Store Connect

After your Apple Developer enrollment activates and you've created the app
in App Store Connect, do this once:

1. App Store Connect → your app → **Monetization** → **In-App Purchases**
2. **+** → choose **Non-Consumable**
3. Reference Name: `Unlock All Patterns`
4. Product ID: `com.aintmer.cytosphere.unlock_all` (must match
   `ProductID.unlockAll` in `Sources/Purchases/PurchaseStore.swift`)
5. **Pricing**:
   - Click **Add Pricing**, pick the equivalent of $9.99 USD
   - Use the price-tier matrix to confirm what that is in each region (€9.99,
     £9.99 etc — Apple will auto-fill)
6. **Localization** (English):
   - Display Name: `Unlock All Patterns`
   - Description: `Unlocks all twelve generative patterns and the full export resolution range.`
7. **Review** screenshot — required by Apple. Upload a screenshot of the
   paywall (we can grab one from the running app or the marketing-shots task).
8. **Save**

The IAP submission is reviewed *together* with the app binary on first
release. Subsequent IAP edits go through Apple's separate IAP review (~1 day).

---

## 3. Small Business Program (if not already)

If you haven't already, apply for the **App Store Small Business Program**.
This drops Apple's cut from 30% → 15% on every sale (so on a $9.99 IAP you
keep ~$8.49 vs ~$6.99). Eligibility: < $1M revenue/year, which you very
much qualify for.

App Store Connect → Agreements, Tax, and Banking → look for the Small
Business Program enrollment link. Approval is ~24 hours and the lower rate
applies from the date you enroll.

---

## What's gated in code

| File | What it does |
|---|---|
| `Sources/Models/Pattern.swift` | `Pattern.isFree` — only `mitosis` and `organellesSketch` return true |
| `Sources/Purchases/PurchaseStore.swift` | StoreKit 2 manager — loads products, handles purchase + restore, tracks entitlement |
| `Sources/UI/PaywallView.swift` | Sheet shown when a gated action is taken |
| `Sources/UI/SidebarView.swift` | Lock icons in the pattern picker, paywall trigger on Export, "Unlock to export" button label |
| `Sources/UI/AboutView.swift` | "Restore purchases" button (Apple requires this) |
| `Sources/App/TrajectoryWallpaperApp.swift` | Injects `PurchaseStore` via `.environment(…)` |
| `Cytosphere.storekit` | Local StoreKit config for testing without App Store Connect |

## To change what's free vs paid

Edit `Pattern.isFree` in `Sources/Models/Pattern.swift`. Currently:

```swift
var isFree: Bool {
    switch self {
    case .mitosis, .organellesSketch: return true
    default:                          return false
    }
}
```

Want to add `orbitalsSchematic` to the free tier? Add it to the case list.

## To change the price

Two places:
- `Cytosphere.storekit` (`displayPrice` field) — local testing
- App Store Connect → IAP → Pricing — production

Tip: keep them in sync so the testing UI matches what users will see.
