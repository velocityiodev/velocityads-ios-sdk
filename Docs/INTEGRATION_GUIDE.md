# Velocity Ads SDK Integration Guide

**Version:** 0.12.0
**Last Updated:** November 2026
**Platform:** iOS 15.0+  
**Language:** Swift 5.5+

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [SDK Initialization](#sdk-initialization)
5. [Loading Native Ads](#loading-native-ads)
6. [Load-Once Semantics and Ad Lifecycle](#load-once-semantics-and-ad-lifecycle)
7. [Loading Native Ad Views](#loading-native-ad-views)
8. [Recycling Container Integration](#recycling-container-integration)
9. [Ad Theming and Customization](#ad-theming-and-customization)
10. [Interstitial Ads](#interstitial-ads)
11. [Rewarded Ads](#rewarded-ads)
12. [Banner Ads](#banner-ads)
13. [Regulations](#regulations)
14. [Troubleshooting](#troubleshooting)
15. [Best Practices](#best-practices)
16. [Migrating to 0.12.0 (Native Ads)](#migrating-to-0120-native-ads)
17. [API Reference](#api-reference)

---

## Overview

Velocity Ads is an iOS SDK that provides AI-powered contextual advertising.

---

## Prerequisites

### System Requirements

- **Minimum iOS:** 15.0
- **Xcode:** 26.0+
- **Swift:** 5.5+

### Apple Ad Attribution

To support Apple app-install attribution, add Velocity's ad network identifier
to both attribution arrays in the host app target's `Info.plist`. Apple permits
the same `.adattributionkit` identifier in `AdNetworkIdentifiers` and
`SKAdNetworkItems`:

```xml
<key>AdNetworkIdentifiers</key>
<array>
    <string>rwn33vua23.adattributionkit</string>
</array>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>rwn33vua23.adattributionkit</string>
    </dict>
</array>
```


### Advertising Identifiers

The Velocity Ads SDK uses **IDFA** (Identifier for Advertisers) and **IDFV** (Identifier for Vendor) when available to improve ad performance and relevance. These identifiers enable:

- 🎯 **Better ad targeting** - More relevant ads for your users
- 📊 **Improved analytics** - Better campaign performance measurement
- 💰 **Higher revenue** - Increased eCPM through better targeting

On iOS, access to IDFA is controlled by **App Tracking Transparency (ATT)**. Your app must request tracking authorization when appropriate; the SDK uses the advertising identifier only when the user has granted permission. The SDK does not perform cross-app tracking; the host app controls ATT and the SDK uses identifiers for ad delivery and analytics within your app.

---

## Installation

The Velocity Ads SDK can be installed via **Swift Package Manager (SPM)** or **CocoaPods**.

> **Current version: `0.12.0`**  

### Swift Package Manager (SPM)

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:  
   **`https://github.com/velocityiodev/velocityads-ios-sdk`**
3. Set the version rule to **"Exact"** and enter **`0.12.0`**, then click **Add Package**.
4. Add the **VelocityAdsSDK** library to your app target.

The package uses a binary target hosted on GitHub Releases. Each release provides a pre-built XCFramework; Xcode resolves the correct asset automatically when you select a version.

---

### CocoaPods

1. Add the following to your `Podfile`:

```ruby
pod 'VelocityAdsSDK', '0.12.0'
```

2. Run:

```bash
pod install
```

3. Open the generated `.xcworkspace` file and import the SDK where needed:

```swift
import VelocityAdsSDK
```

---

## SDK Initialization

Initialize the SDK once at app startup and always provide a `VelocityAdsInitDelegate`.

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        VelocityAds.setUserId("USER_ID")  // Optional: User identifier
        
        let initRequest = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY").build()
        VelocityAds.initSDK(initRequest, delegate: MyInitDelegate())

        return true
    }
}

@MainActor
class MyInitDelegate: VelocityAdsInitDelegate {
    func onInitSuccess() {
        print("SDK initialized successfully")
    }

    func onInitFailure(error: VelocityAdsError) {
        print("Initialization failed: \(error)")
        // Handle initialization failure
    }
}
```

Or with SwiftUI:

```swift
import SwiftUI
import VelocityAdsSDK

@main
struct MyApp: App {
    init() {
        let initRequest = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY").build()
        VelocityAds.initSDK(initRequest, delegate: MyInitDelegate())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **Threading:** All `VelocityAdsInitDelegate` callbacks are delivered on the **main thread**. The protocol is annotated `@MainActor` to express this guarantee to the Swift type system. Conform your delegate class with `@MainActor` so you can update your UI directly from callbacks. `UIViewController` and `UIApplicationDelegate` are already `@MainActor`-isolated by default.

For best performance, call `VelocityAds.setUserId(_:)` before `VelocityAds.initSDK(...)` when a user identifier is available.

**Important:**
- ⚠️ Initialize once during app startup
- ⚠️ Must be called before loading any ads

## Loading Native Ads

The SDK provides a method for loading native ads:

- **`VelocityNativeAdRequest`** — Immutable request object built via a fluent builder. Holds all targeting context.
- **`VelocityNativeAd`** — The ad object. Create one from a request and call `load(delegate:)` to trigger loading. The creative data (`nativeAd.data`, a `NativeAd` with `title`, `description`, etc.) is populated when `onAdLoaded` is called.

> **Threading:** All `VelocityNativeAdDelegate` callbacks are always delivered on the **main thread** — you can update your UI directly without dispatching. The protocol is annotated `@MainActor` to express this guarantee to the Swift type system. If you build with **Swift 6** or with `SWIFT_STRICT_CONCURRENCY = complete`, your conforming type must be `@MainActor`-isolated (e.g. `UIViewController` already is); otherwise the compiler will emit an error. Under Swift 5 without strict concurrency, no annotation is required, but adding it is recommended.

```swift
@MainActor
class MyViewController: UIViewController, VelocityNativeAdDelegate {

    func loadAd() {
        // 1. Build the request
        let adRequest = VelocityNativeAdRequest.Builder(adUnitId: "ad_unit_123") // Ad unit identifier
            .withPrompt("What's the weather today?")              // Optional: Provide for context
            .withAIResponse("The weather is sunny with 72°F...")  // Optional: Provide for better targeting
            .withConversationHistory(nil)                         // Optional: Previous conversation
            .withAdditionalContext(nil)                           // Optional: Extra context
            .build()

        // 2. Create the ad object and load
        let nativeAd = VelocityNativeAd(adRequest)
        nativeAd.load(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        guard let data = nativeAd.data else { return }

        // Display the ad. Every creative field is optional — show each view only when the
        // ad has a value for it (see `show(_:in:)` below).
        show(data.advertiserName, in: advertiserNameLabel)
        show(data.badgeLabel, in: badgeLabel)               // ad disclosure badge, e.g. "Ad"
        show(data.title, in: titleLabel)
        show(data.description, in: descriptionLabel)
        if let callToAction = data.callToAction {
            ctaButton.setTitle(callToAction, for: .normal)
            ctaButton.isHidden = false
        } else {
            ctaButton.isHidden = true
        }

        // Load an image (e.g. with URLSession or a library like SDWebImage).
        // `imagesByAspectRatio` holds every image, keyed by aspect-ratio string;
        // `images(for:)` returns every image of one ratio (an empty array when absent).
        let landscapeImages = data.images(for: "1.9:1")
        let squareImages = data.images(for: "1:1")
        if let imageUrl = landscapeImages.first ?? squareImages.first {
            loadImage(from: imageUrl, into: adImageView)
        }

        // Register for automatic impression tracking and click handling.
        // The SDK tracks an impression once ≥ 50 % of the ad view is visible
        // on screen, and opens the click URL when the user taps a clickable view.
        nativeAd.registerViewForInteraction(
            adView: adContainerView,
            clickableViews: [ctaButton, adImageView]
        )
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        print("Failed to load ad: \(error)")
    }

    func onAdImpression(nativeAd: VelocityNativeAd) {
        // Fires once when ≥ 50 % of the ad view is visible on screen
    }

    func onAdClicked(nativeAd: VelocityNativeAd) {
        // Fired when the user taps the ad (SDK handles opening the click URL)
    }

    /// Shows `text` in `label`, or hides the label when the ad has no value for it.
    private func show(_ text: String?, in label: UILabel) {
        guard let text else {
            label.isHidden = true
            return
        }
        label.text = text
        label.isHidden = false
    }
}
```

> **Note:** `onAdImpression` and `onAdClicked` have default no-op implementations via a protocol extension.

### Automatic Impression and Click Tracking

The SDK uses a **50% viewability threshold** for impression tracking: an impression fires once at least 50% of the registered ad view is visible on screen. The SDK fires the impression exactly once, and then stops polling.

For UIKit apps using manual rendering, call `registerViewForInteraction` after loading the ad to enable automatic impression and click tracking:

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let data = nativeAd.data else { return }

    // Set up your ad views (`show(_:in:)` is the helper from the example above)...
    show(data.title, in: titleLabel)
    show(data.description, in: descriptionLabel)

    // Register the container view for automatic impression tracking
    // (impression fires when ≥ 50 % of adContainerView is visible)
    // and specify which views are clickable
    nativeAd.registerViewForInteraction(
        adView: adContainerView,                  // View to track for impressions
        clickableViews: [ctaButton, adImageView]  // Tappable views
    )
}

// When the delegate callbacks fire:
func onAdImpression(nativeAd: VelocityNativeAd) {
    print("Ad impression tracked automatically — ≥ 50 % of the ad view was visible")
}

func onAdClicked(nativeAd: VelocityNativeAd) {
    print("User clicked the ad - SDK opens click URL automatically")
}
```

Call `unregisterViewForInteraction()` when the ad view is no longer in use to stop the visibility timer and remove click gesture recognizers:

- **View controller teardown** — call it in `viewDidDisappear` or `deinit` if the ad is tied to a single screen.
- **Ad replaced** — call it before calling `registerViewForInteraction` again with a different ad on the same view.
- **Before `destroy()`** — unregister first if you are explicitly destroying the ad instance; `destroy()` itself is safe to call without it, but unregistering first is good practice.

```swift
// Example: tearing down an ad when a view controller disappears
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    nativeAd?.unregisterViewForInteraction()
}
```

> **Recycling containers:** In a `UITableView` or `UICollectionView`, call `unregisterViewForInteraction()` in **both** `prepareForReuse` and at the **start of the configure method** (identity-guarded: `if let previous = currentAd, previous !== nativeAd`). `prepareForReuse` cleans up on normal dequeue; the configure guard covers `reconfigureRows(at:)` (iOS 15+), which refreshes a visible cell in place without calling `prepareForReuse`. See [Recycling Container Integration](#recycling-container-integration) for full patterns.

**For SwiftUI apps**, use the `.velocityAdTracking(_:)` modifier instead:

```swift
struct AdCardView: View {
    let nativeAd: VelocityNativeAd

    var body: some View {
        VStack {
            // Every creative field is optional — render each only when present
            if let title = nativeAd.data?.title { Text(title) }
            if let description = nativeAd.data?.description { Text(description) }
            // ... render ad content
        }
        .velocityAdTracking(nativeAd)  // Enables automatic tracking
    }
}
```

### Conversation History

For better ad targeting in chat applications, you can provide conversation history:

```swift
// First call — no conversation history
let adRequest1 = VelocityNativeAdRequest.Builder(adUnitId: "ad_unit_123") // Ad unit identifier
    .withPrompt("What's the weather today?")    // Optional: provide for context
    .withAIResponse("The weather is sunny...")  // Optional: provide AI response for better targeting
    .build()
let nativeAd1 = VelocityNativeAd(adRequest1)
nativeAd1.load(delegate: self)

// Subsequent calls — with conversation history
let conversationHistory: [[String: Any]] = [
    ["role": "user", "content": "What's the weather today?"],
    ["role": "assistant", "content": "The weather is sunny..."]
]

let adRequest2 = VelocityNativeAdRequest.Builder(adUnitId: "ad_unit_123") // Ad unit identifier
    .withPrompt("What about tomorrow?")            // Optional: provide for context
    .withAIResponse("Tomorrow will be cloudy...")  // Optional: provide AI response for better targeting
    .withConversationHistory(conversationHistory)  // Previous conversation
    .build()
let nativeAd2 = VelocityNativeAd(adRequest2)
nativeAd2.load(delegate: self)
```

**Note:** The `withConversationHistory` parameter accepts an array of dictionaries (`[[String: Any]]?`). Each dictionary should have `"role"` (`"user"` or `"assistant"`) and `"content"` (message text). Update it with the full conversation history for best targeting.

### Preliminary Text

When `.includePreliminaryText(true)` is set on the request, the ad may include a short contextual sentence in `nativeAd.data?.preliminaryText`. Display it directly above the ad — outside the ad view's frame — so it does not affect the ad's layout or height.

```swift
// Request with preliminary text enabled
let adRequest = VelocityNativeAdRequest.Builder(adUnitId: "ad_unit_123")
    .withPrompt("Which running shoes are best for marathons?")
    .withAIResponse("For marathons, I recommend ...")
    .includePreliminaryText(true)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

After the ad loads, read and display the text above your ad UI:

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let data = nativeAd.data else { return }

    // Display preliminary text above the ad (if available)
    if let preliminaryText = data.preliminaryText, !preliminaryText.isEmpty {
        preliminaryLabel.text = preliminaryText
        preliminaryLabel.isHidden = false
    } else {
        preliminaryLabel.isHidden = true
    }

    // Render ad content (`show(_:in:)` is the helper from the example above)...
    show(data.title, in: titleLabel)
    show(data.description, in: descriptionLabel)
}
```

For SwiftUI:

```swift
VStack(alignment: .leading, spacing: 4) {
    if let text = nativeAd.data?.preliminaryText, !text.isEmpty {
        Text(text)
            .font(.system(size: 14).italic())
            .foregroundColor(.secondary)
    }
    // Your ad view...
}
```

For SDK-rendered ads (`VelocityNativeAdViewRequest`), place the preliminary text above the view returned by `createAdView()` or `createAdSwiftUIView()`. The text is not rendered by the SDK — publishers are responsible for displaying it.


---

## Load-Once Semantics and Ad Lifecycle

A `VelocityNativeAd` instance has a **one-way lifecycle**: create → load once → use → destroy.

```
Created → load() → Loading → success → Loaded → destroy() → Destroyed (terminal)
                                ↓
                              failure (retry allowed)
```

- **Load once:** After a successful load, calling `load()` again on the same instance returns `VelocityAdsErrorCode.adAlreadyLoaded` (`2008`). Create a new `VelocityNativeAd` instance for each ad placement.
- **Retry on failure:** If a load fails, you may call `load()` again on the same instance.
- **Terminal after destroy:** After `destroy()`, the instance is inert. `load()` returns `VelocityAdsErrorCode.adDestroyed` (`2010`); `createAdView()` / `createAdSwiftUIView()` return `nil`; `configureAdView()` / `registerViewForInteraction()` are no-ops.
- **`adRequest` remains readable** after destroy (it is a `let` constant), but **`data` is set to `nil`** by `destroy()`. The instance should not be used further.

---

## Loading Native Ad Views

The SDK can render ad views for you — no custom UI needed. The card is rendered by the SDK inside a `VelocityNativeAdView`. To use this path, load with `VelocityNativeAdViewRequest` instead of the base `VelocityNativeAdRequest`. The view request adds two parameters:

- **`adViewHeights`** (optional) — the card heights your placement can host (`.height120`, `.height254`). Omitted or empty means every height this SDK supports. The ad is rendered at one of them.
- **`configuration`** (optional) — controls theming (colors, typography, dark mode, corner radius). See [Ad Theming and Customization](#ad-theming-and-customization).

After a successful load, call `createAdView()` or `createAdSwiftUIView()` to get a self-contained view with built-in impression and click tracking. The view sizes itself — place it in your layout as it is, with no height constraint (see [The view owns its height](#the-view-owns-its-height)).

### `VelocityNativeAdViewRequest`

Build the request using the fluent builder. Only `adUnitId` is required; all other parameters are optional and inherited from `VelocityNativeAdRequest`.

```swift
let adRequest = VelocityNativeAdViewRequest.Builder(
    adUnitId: "ad_unit_123",
    adViewHeights: [.height254]            // Optional — omit to allow every height (120 pt and 254 pt)
)
    .withPrompt("Best noise-cancelling headphones")                 // Optional: Provide for context
    .withAIResponse("The Sony WH-1000XM5 offers excellent ANC...")  // Optional: Provide for better targeting
    .withConversationHistory(conversationHistory)                   // Optional: Previous conversation
    .withAdditionalContext("electronics, audio")                    // Optional: Extra context
    .withAdViewConfiguration(AdViewConfiguration(
        colorScheme: AdColorScheme.Builder()
            .light { $0.copy(ctaBackground: .systemBlue) }
            .build()
    ))
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

### Ad View Heights

`VelocityNativeAdViewHeight` lists the card heights an SDK-rendered ad can take. The request declares which ones the placement allows; the ad is rendered at one of them.

| Height | Points |
|--------|--------|
| `.height120` | 120 pt |
| `.height254` | 254 pt |

Passing `adViewHeights` is optional: omit it, or pass an empty array, to allow every supported height. Duplicates are ignored and order carries no preference. The ad is rendered at one of the heights you allow. Only heights defined in this SDK version are served.

### The view owns its height

`VelocityNativeAdView` sizes itself — it does what `wrap_content` does on Android:

1. When the view is created or configured, it takes its height — one of the heights the request allows — and in normal operation keeps it. Until the ad is displayed it draws a placeholder (card background and media frame, following Light/Dark mode, the configured corner radius and `cardBackground`) at that size, so the slot is never a transparent gap.
2. If the loaded ad cannot be rendered, the view collapses to 0 pt and stays empty until an ad is configured into it again; nothing is reported to the delegate.

The view reports its height through `intrinsicContentSize` / `sizeThatFits`; a `UITableView` / `UICollectionView` row hosting it is re-measured automatically when its height changes (for example the collapse). Pin the view's leading, trailing, top and bottom edges — **not its height** — and do not derive a height from `adViewHeights`: the view owns its height, including the collapse, and a pinned height would hide it. Width follows the superview. The rendered height and media are not exposed as an API. In SwiftUI, use `createAdSwiftUIView()` rather than wrapping the view in your own `UIViewRepresentable`: the SDK's SwiftUI view follows the view's height, including the collapse to 0, on every supported iOS version.

### Creating Ad Views

After a successful `load(delegate:)` call, create SDK-rendered views on demand. This separates the expensive network load from the cheap view creation — the key to efficient cell recycling.

Views return `nil` if the request was a plain `VelocityNativeAdRequest`, if `load` has not yet succeeded, or if the instance has been destroyed via `destroy()`.

#### `createAdView() -> VelocityNativeAdView?`

Creates a pre-built UIKit ad view. Impression and click tracking are handled automatically inside the returned view. Pin its edges only — the view owns its height, and a container without a fixed height follows it.

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let adView = nativeAd.createAdView() else { return }
    adView.translatesAutoresizingMaskIntoConstraints = false
    adContainer.addSubview(adView)
    // No height constraint: the view owns its height (one of the allowed
    // heights, or 0 if the ad cannot be rendered).
    NSLayoutConstraint.activate([
        adView.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor),
        adView.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor),
        adView.topAnchor.constraint(equalTo: adContainer.topAnchor),
        adView.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor),
    ])
}
```

#### `createAdSwiftUIView() -> AnyView?`

Creates a pre-built SwiftUI ad view. No `UIViewRepresentable` bridging needed — embed it directly. The view applies the card's height itself and follows it, including the collapse to 0 if the ad cannot be rendered; do not wrap it in `.frame(height:)`.

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    self.adView = nativeAd.createAdSwiftUIView()
}

// In body:
if let adView { adView.frame(maxWidth: .infinity) }   // no fixed height
```

**Return value:** Both `createAdView()` and `createAdSwiftUIView()` return `nil` if:
- The ad data has not been loaded yet (before `onAdLoaded`).
- The `adRequest` was a plain `VelocityNativeAdRequest` instead of `VelocityNativeAdViewRequest`.
- The instance has been destroyed via `destroy()`.

> **Note:** Publishers using the manual rendering path (`VelocityNativeAdRequest`) do not call `createAdView` or `createAdSwiftUIView`. Use `registerViewForInteraction(adView:clickableViews:)` instead to enable impression and click tracking.

---

## Recycling Container Integration

Loading ad data once and reusing a single view across recycled cells dramatically reduces memory usage. The SDK supports six integration patterns — two rendering paths (manual vs SDK-rendered) crossed with three host environments. This section documents the expected publisher behavior for each.

### Supported Containers

| Container Type | Recycling Mechanism |
|---|---|
| `UITableView` | `dequeueReusableCell(_:for:)` + `prepareForReuse` |
| `UICollectionView` | `dequeueReusableCell(withReuseIdentifier:for:)` + `prepareForReuse` |
| SwiftUI `LazyVStack`, `LazyHStack`, `LazyVGrid`, `LazyHGrid`, `List` | SwiftUI view identity via `ForEach` + `.id()` |

UIKit examples apply to both `UITableView` and `UICollectionView` — the cell lifecycle is identical. SwiftUI examples apply to all lazy containers.

### `configureAdView(_ adView: VelocityNativeAdView)`

Reconfigures an existing SDK-rendered `VelocityNativeAdView` with new ad data. The view's layout is reused — only the ad content is swapped. This is the key to efficient UIKit cell recycling with SDK-rendered views (Pattern 3).

```swift
if let existingAdView = cell.adView {
    nativeAd.configureAdView(existingAdView)
}
```

`configureAdView` swaps in the new ad (the view takes one of the heights the request allows, restoring normal sizing after a collapse; a hosting row is re-measured automatically if the height changes), resets impression tracking when the ad identity changes, and updates the click destination. It returns `false` (and does nothing) if the ad is not loaded, was destroyed, was not loaded with a `VelocityNativeAdViewRequest`, or is called off the main thread. No `prepareForReuse` cleanup is needed — teardown is handled automatically.

---

### Pattern 1: Manual Rendering (UIKit Recycling Container)

Use `VelocityNativeAdRequest` to load ad data. The publisher builds custom UI from `nativeAd.data`. Pre-load ads before binding to cells. Call `unregisterViewForInteraction` in **both** `prepareForReuse` and at the start of the configure method (identity-guarded), then call `registerViewForInteraction` for the incoming ad. `prepareForReuse` handles normal cell dequeue; the identity guard in configure covers `reconfigureRows(at:)`, which refreshes a visible cell in place without calling `prepareForReuse`.

```swift
import UIKit
import VelocityAdsSDK

@MainActor
class ChatViewController: UIViewController, UITableViewDataSource, VelocityNativeAdDelegate {
    private var messages: [ChatItem] = []
    private var nativeAds: [UUID: VelocityNativeAd] = [:]

    private func loadAdForMessage(_ messageId: UUID, prompt: String, aiResponse: String?) {
        let adRequest = VelocityNativeAdRequest.Builder(adUnitId: adUnitId)
            .withPrompt(prompt)
            .withAIResponse(aiResponse)
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        nativeAds[messageId] = nativeAd
        nativeAd.load(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        tableView.reloadData()
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        print("Ad load failed: \(error)")
    }

    func onAdImpression(nativeAd: VelocityNativeAd) {}
    func onAdClicked(nativeAd: VelocityNativeAd) {}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = messages[indexPath.row]
        guard case .ad(let messageId) = item,
              let nativeAd = nativeAds[messageId],
              nativeAd.data != nil else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ManualAdCell.reuseId, for: indexPath
        ) as! ManualAdCell
        cell.configure(with: nativeAd)
        return cell
    }
}

class ManualAdCell: UITableViewCell {
    static let reuseId = "ManualAdCell"
    private let titleLabel = UILabel()
    private let ctaButton = UIButton()
    private var currentAd: VelocityNativeAd?

    func configure(with nativeAd: VelocityNativeAd) {
        // Unregister the previous ad if it differs from the incoming one. This
        // covers reconfigureRows(at:), which refreshes a visible cell without
        // calling prepareForReuse.
        if let previous = currentAd, previous !== nativeAd {
            previous.unregisterViewForInteraction()
        }
        currentAd = nativeAd
        // Every creative field is optional — show each view only when the ad has a value for it.
        if let title = nativeAd.data?.title {
            titleLabel.text = title
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }
        if let callToAction = nativeAd.data?.callToAction {
            ctaButton.setTitle(callToAction, for: .normal)
            ctaButton.isHidden = false
        } else {
            ctaButton.isHidden = true
        }
        nativeAd.registerViewForInteraction(adView: contentView, clickableViews: [ctaButton])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Unregister and clear on normal cell dequeue so the cell is clean when
        // it returns to the pool. configure() handles reconfigureRows independently.
        currentAd?.unregisterViewForInteraction()
        currentAd = nil
        titleLabel.text = nil
        ctaButton.setTitle(nil, for: .normal)
    }
}
```

---

### Pattern 2: Manual Rendering (SwiftUI Lazy Container)

Use `VelocityNativeAdRequest` to load ad data. The publisher builds custom SwiftUI views from `nativeAd.data` and attaches the `.velocityAdTracking(_:)` modifier for automatic impression and click tracking. The modifier handles register/unregister automatically as views enter and leave the screen.

```swift
import SwiftUI
import VelocityAdsSDK

@MainActor
class ManualAdViewModel: ObservableObject, VelocityNativeAdDelegate {
    @Published var nativeAd: VelocityNativeAd?

    func loadAd(prompt: String, aiResponse: String?) {
        let adRequest = VelocityNativeAdRequest.Builder(adUnitId: adUnitId)
            .withPrompt(prompt)
            .withAIResponse(aiResponse)
            .build()

        let ad = VelocityNativeAd(adRequest)
        ad.load(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        self.nativeAd = nativeAd
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        print("Ad load failed: \(error)")
    }
}

struct ManualAdCardView: View {
    let nativeAd: VelocityNativeAd

    var body: some View {
        let data = nativeAd.data
        VStack(alignment: .leading, spacing: 8) {
            // Every creative field is optional — render each one only when present.
            if let title = data?.title {
                Text(title)
                    .font(.headline)
            }
            if let description = data?.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let cta = data?.callToAction {
                Text(cta)
                    .font(.callout.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .velocityAdTracking(nativeAd)
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ManualAdViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    switch item {
                    case .ad(let nativeAd):
                        ManualAdCardView(nativeAd: nativeAd)
                            .padding(.horizontal)
                    case .message(let text):
                        Text(text)
                    }
                }
            }
        }
    }
}
```

---

### Pattern 3: SDK-Rendered UIView (UIKit Recycling Container)

Use `VelocityNativeAdViewRequest` to load ad data. Pre-load ads before binding to cells. Create the `VelocityNativeAdView` once per cell with `createAdView()`; call `configureAdView` on reuse to swap the ad data without recreating the view hierarchy. The view is retained in the cell across `prepareForReuse`. Use self-sizing rows (`UITableView.automaticDimension`) and pin the view's edges only: the view owns its height and the row follows it, including the collapse to 0 if the ad cannot be rendered.

```swift
import UIKit
import VelocityAdsSDK

@MainActor
class FeedViewController: UIViewController, UITableViewDataSource, VelocityNativeAdDelegate {
    private var nativeAds: [UUID: VelocityNativeAd] = [:]

    private func loadAd(for messageId: UUID, prompt: String) {
        let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: adUnitId)   // every height this SDK supports
            .withPrompt(prompt)
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        nativeAds[messageId] = nativeAd
        nativeAd.load(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        tableView.reloadData()
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        print("Failed to load ad: \(error)")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = messages[indexPath.row]
        guard case .ad(let messageId) = item,
              let nativeAd = nativeAds[messageId] else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SDKAdCell.reuseId, for: indexPath
        ) as! SDKAdCell
        cell.configure(with: nativeAd)
        return cell
    }
}

@MainActor
class SDKAdCell: UITableViewCell {
    static let reuseId = "SDKAdCell"
    private var adView: VelocityNativeAdView?

    func configure(with nativeAd: VelocityNativeAd) {
        if adView == nil {
            adView = nativeAd.createAdView()
            if let adView {
                contentView.addSubview(adView)
                adView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    adView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    adView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    adView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    adView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                ])
            }
        } else if let adView {
            nativeAd.configureAdView(adView)
        }
    }
    // prepareForReuse: nothing required — configureAdView handles teardown internally
    // No height constraint on adView: the row is self-sizing and follows the view.
}
```

---

### Pattern 4: SDK-Rendered UIView (SwiftUI Lazy Container)

> **Prefer Pattern 6 in SwiftUI.** `createAdSwiftUIView()` follows the card's height, including the collapse to 0 after a render failure, on every supported iOS version. Use this pattern only if you need the `UIView` itself, and only on iOS 16+ (see the iOS 15 note below).

Use `VelocityNativeAdViewRequest` to load ad data. Cache the `VelocityNativeAdView` in `@State` so it is created once per `ForEach` identity. Wrap it in a publisher-written `UIViewRepresentable`. No `configureAdView` is needed — each ad identity keeps its own cached view.

Create the view in `onAppear` rather than in `init`. Swift eagerly evaluates `State(initialValue:)` arguments on every `body` re-evaluation, producing a throwaway `VelocityNativeAdView` on each re-render that displaces the view in use before being immediately discarded. The `onAppear` guard (`guard cachedAdView == nil`) ensures creation happens exactly once per `ForEach` identity.

```swift
import SwiftUI
import VelocityAdsSDK

struct AdRowView: View {
    let nativeAd: VelocityNativeAd
    @State private var cachedAdView: VelocityNativeAdView?

    var body: some View {
        Group {
            if let adView = cachedAdView {
                SDKAdViewRepresentable(adView: adView)
                    .frame(maxWidth: .infinity)
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .onAppear {
            guard cachedAdView == nil else { return }
            cachedAdView = nativeAd.createAdView()
        }
    }
}

struct SDKAdViewRepresentable: UIViewRepresentable {
    let adView: VelocityNativeAdView

    func makeUIView(context: Context) -> VelocityNativeAdView {
        return adView
    }

    func updateUIView(_ uiView: VelocityNativeAdView, context: Context) {
        uiView.setNeedsLayout()
    }

    // iOS 16+: size from the view's current intrinsic height
    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: VelocityNativeAdView,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        return CGSize(width: width, height: adView.intrinsicContentSize.height)
    }
}

// Usage in a LazyVStack:
LazyVStack {
    ForEach(items) { item in
        switch item {
        case .ad(let nativeAd):
            AdRowView(nativeAd: nativeAd)
        case .content(let text):
            Text(text)
        }
    }
}
```

> **iOS 15 note:** `UIViewRepresentable.sizeThatFits` is iOS 16+, and on iOS 15 a publisher-written representable cannot follow the card's height: a `.frame(height: adView.intrinsicContentSize.height)` is a one-time snapshot that misses the collapse to 0 after a render failure. On iOS 15, host the ad with `createAdSwiftUIView()` ([Pattern 6](#pattern-6-sdk-rendered-swiftui-swiftui-lazy-container)) instead.

---

### Pattern 5: SDK-Rendered SwiftUI (UIKit Recycling Container)

Use `VelocityNativeAdViewRequest` to load ad data. Call `createAdSwiftUIView()` to get an `AnyView` and host it inside the cell. The SwiftUI view carries the card's height itself, so the cell must not pin one — use self-sizing rows. The recommended hosting strategy depends on the minimum iOS version you support:

- **iOS 16+:** Use `UIHostingConfiguration` assigned to `cell.contentConfiguration`. This is Apple's purpose-built, lightweight API for SwiftUI content in `UITableViewCell` / `UICollectionViewCell`. No view-controller lifecycle, no manual Auto Layout — each recycle simply reassigns `contentConfiguration`, and the row follows the hosted view's height.
- **iOS 15 fallback:** Retain a `UIHostingController<AnyView>` as a child view controller, pin its view's edges (no height constraint) and replace `hostingController.rootView` on reuse. The row is re-measured automatically when the card's height changes (for example the collapse to 0).

```swift
import UIKit
import SwiftUI
import VelocityAdsSDK

@MainActor
class SwiftUIAdCell: UITableViewCell {
    static let reuseId = "SwiftUIAdCell"

    // iOS 15 fallback only
    private var hostingController: UIHostingController<AnyView>?

    func configure(nativeAd: VelocityNativeAd) {
        guard let swiftUIView = nativeAd.createAdSwiftUIView() else { return }

        if #available(iOS 16.0, *) {
            contentConfiguration = UIHostingConfiguration {
                swiftUIView
            }
            .margins(.all, 16)
            // No minSize / fixed height: the ad view sizes itself.
        } else {
            if let hc = hostingController {
                hc.rootView = swiftUIView
            } else {
                let hc = UIHostingController(rootView: swiftUIView)
                hc.view.backgroundColor = .clear
                hc.view.translatesAutoresizingMaskIntoConstraints = false
                hostingController = hc

                contentView.addSubview(hc.view)
                let p: CGFloat = 16
                // Edges only — the hosted ad view owns its height.
                NSLayoutConstraint.activate([
                    hc.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: p),
                    hc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p),
                    hc.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
                    hc.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
                ])
            }
        }
    }
    // prepareForReuse: nothing required —
    // iOS 16+: contentConfiguration reassignment handles teardown.
    // iOS 15: hostingController is retained; rootView is replaced in the next configure call.
}
```

> **Note:** Unlike the UIView recycling path (Pattern 3), there is no `configureAdView` equivalent for this path. Each `createAdSwiftUIView()` call creates a new ad view, so the view is replaced entirely on every recycle. On iOS 16+, `UIHostingConfiguration` avoids the view-controller lifecycle overhead, reducing per-cell cost compared to the `UIHostingController` fallback. For performance-sensitive lists with high scroll velocity, prefer Pattern 3 (SDK UIView in UIKit recycling container). Pattern 5 is best suited when you need SwiftUI rendering inside a UIKit collection and the list size is moderate.

---

### Pattern 6: SDK-Rendered SwiftUI (SwiftUI Lazy Container)

Use `VelocityNativeAdViewRequest` to load ad data. Cache the `AnyView` in `@State` so `createAdSwiftUIView()` is called once per `ForEach` identity. Render it directly — no bridging needed.

As with Pattern 4, create the view in `onAppear` rather than in `init` to avoid Swift's eager `State(initialValue:)` evaluation producing throwaway views on re-renders.

```swift
import SwiftUI
import VelocityAdsSDK

struct SDKSwiftUIAdRow: View {
    let nativeAd: VelocityNativeAd
    @State private var cachedSwiftUIView: AnyView?

    var body: some View {
        Group {
            if let adView = cachedSwiftUIView {
                adView
                    .frame(maxWidth: .infinity)
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .onAppear {
            guard cachedSwiftUIView == nil else { return }
            cachedSwiftUIView = nativeAd.createAdSwiftUIView()
        }
    }
}

// Usage in a LazyVStack:
LazyVStack {
    ForEach(items) { item in
        switch item {
        case .ad(let nativeAd):
            SDKSwiftUIAdRow(nativeAd: nativeAd)
        case .content(let text):
            Text(text)
        }
    }
}
```

---

### Cell Lifecycle Summary

#### UIKit Recycling Containers (`UITableView` / `UICollectionView`)

| Lifecycle Event | Pattern 1: Manual | Pattern 3: SDK UIView | Pattern 5: SDK SwiftUI |
|---|---|---|---|
| `cellForRowAt` — first use | Populate UI from `nativeAd.data`, then `registerViewForInteraction(adView:clickableViews:)` | `createAdView()` → add to cell | `createAdSwiftUIView()` → assign `UIHostingConfiguration` (iOS 16+) or create `UIHostingController` → add to cell (iOS 15) |
| `cellForRowAt` — reused cell | Identity-guarded `unregisterViewForInteraction()` at start of configure, populate UI, then `registerViewForInteraction(adView:clickableViews:)` | `configureAdView(existingAdView)` — the view keeps owning its height | `createAdSwiftUIView()` → reassign `contentConfiguration` (iOS 16+) or replace `hostingController.rootView` (iOS 15) |
| Row height | Your layout | Self-sizing — pin edges only; the row is re-measured automatically when the height changes (e.g. the collapse) | Self-sizing — no `minSize` / height constraint |
| `prepareForReuse` | `unregisterViewForInteraction()` + clear visual content | Nothing required | Nothing required |
| `didEndDisplaying` | Nothing required | Nothing required | Nothing required |

#### SwiftUI Lazy Containers (`LazyVStack` / `List` / etc.)

| Lifecycle Event | Pattern 2: Manual | Pattern 4: SDK UIView | Pattern 6: SDK SwiftUI |
|---|---|---|---|
| View appears | `.velocityAdTracking()` auto-registers via `didMoveToWindow` | `@State` preserves cached `VelocityNativeAdView` | `@State` preserves cached `AnyView` |
| View disappears | `.velocityAdTracking()` auto-unregisters via `willMove(toWindow: nil)` | Automatic via `didMoveToWindow` | Automatic via `didMoveToWindow` |
| View identity changes | SwiftUI recreates the view; modifier wires the new ad | `onAppear` fires for the new identity; `guard == nil` creates a new view | `onAppear` fires for the new identity; `guard == nil` creates a new view |

> **`prepareForReuse` and configure both call `unregisterViewForInteraction` (defense-in-depth):**
> These two call sites cover different code paths. `prepareForReuse` fires on normal cell dequeue and keeps the pool clean; the identity-guarded call at the start of configure covers `reconfigureRows(at:)` (iOS 15+), which refreshes a visible cell in place without calling `prepareForReuse`. Both are needed. Do **not** remove either one. For **SDK-rendered views** (Patterns 3 and 5), teardown is handled internally — no publisher action needed in either method.

---

## Ad Theming and Customization

When using `VelocityNativeAdViewRequest`, you can customize the ad card's appearance via `AdViewConfiguration`. The configuration is intentionally narrow: colors for eight tokens, a font family and text size for the title, the description and the CTA, a Light/Dark override, the card's corner radius. Everything else — brand-name color, the Ad badge, the scrim and on-image chrome, card heights, image sizes and crops, layout, spacing, line clamps and click behavior — is locked by Velocity.

Everything left unset (`nil`) keeps the Velocity default. Set only what you need. An invalid value for a supported property (a radius outside 0–24 or a non-positive text size) is ignored with a warning log and the default stays.

### Custom Colors

```swift
let config = AdViewConfiguration(
    colorScheme: AdColorScheme.Builder()
        .light { $0.copy(
            ctaBackground: UIColor(red: 0.38, green: 0.0, blue: 0.93, alpha: 1.0),
            ctaText: .white,
            cardBackground: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        )}
        .dark { $0.copy(
            ctaBackground: UIColor(red: 0.62, green: 0.31, blue: 0.93, alpha: 1.0),
            ctaText: .white,
            cardBackground: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        )}
        .build()
)

let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: "ad_unit_123")
    .withPrompt("...")
    .withAdViewConfiguration(config)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

A single mode can be customized on its own — `AdColorScheme(dark: AdColors(ctaBackground: brand))` keeps every light default. A border-only CTA is a clear fill with a border and a label readable on the card:

```swift
AdColors(ctaBackground: .clear, ctaBorder: brand, ctaText: brand)
```

#### Available Color Tokens

Every token is `UIColor?`; `nil` keeps the Velocity default.

| Token | Description |
|-------|-------------|
| `cardBackground` | Card surface |
| `cardBackgroundPressed` | Card surface while pressed |
| `cardBorder` | Card outer border |
| `titleText` | Title text |
| `descriptionText` | Description text |
| `ctaBackground` | CTA button fill; `.clear` leaves a border-only button |
| `ctaBorder` | CTA button border |
| `ctaText` | CTA button label |

The brand name (always the card's primary text color, white on photos), the Ad badge, the scrim and everything drawn on photos are locked.

### Custom Typography

`AdTypography` takes a separate `AdTextStyle` — an `AdFontFamily` (Inter `.regular`, `.medium` or `.semiBold`, bundled with the SDK) and a text size in points — for the title, the description and the CTA label. An omitted role, or an omitted field, keeps the Velocity default.

```swift
let config = AdViewConfiguration(
    adTypography: AdTypography(
        title: AdTextStyle(fontFamily: .semiBold, textSize: 16),
        description: AdTextStyle(textSize: 13),
        cta: AdTextStyle(fontFamily: .medium, textSize: 15)
    )
)
```

### Dark Theme Override

By default the SDK follows the host's `userInterfaceStyle`. Override it explicitly:

```swift
let config = AdViewConfiguration(
    darkTheme: false      // Force light mode
    // darkTheme: true    // Force dark mode
    // darkTheme: nil     // Follow system (default)
)
```

### Corner Radius

```swift
let config = AdViewConfiguration(
    cornerRadius: 12   // 0 … AdViewConfiguration.maxCornerRadius (24); nil = Velocity default
)
```

A radius outside 0–24 is ignored with a warning.

### Combining All Options

```swift
let config = AdViewConfiguration(
    colorScheme: AdColorScheme.Builder()
        .light { $0.copy(ctaBackground: UIColor(red: 0.38, green: 0.0, blue: 0.93, alpha: 1.0)) }
        .build(),
    adTypography: AdTypography(
        title: AdTextStyle(fontFamily: .semiBold, textSize: 16),
        description: AdTextStyle(textSize: 13)
    ),
    darkTheme: nil,
    cornerRadius: 12
)

let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: "ad_unit_123", adViewHeights: [.height120, .height254])
    .withPrompt("Best running shoes")
    .withAdViewConfiguration(config)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

---

## Interstitial Ads

Interstitial ads are fullscreen video or MRAID creatives shown at natural transition points in your app flow (e.g. between game levels, after completing a task). The SDK handles the fullscreen presentation surface, player chrome, skip/close controls, and ad tracking automatically.

### Lifecycle

```
Created → load(delegate:) → Loading → onAdLoaded → Ready
                                 ↓
                         onAdFailedToLoad (retry allowed)

Ready → show() → onAdShown → Presenting → onAdDismissed → Spent (terminal)
          ↓
    onAdFailedToShow (ad stays Ready — retry allowed unless expired or destroyed)
```

An interstitial instance is **single-use**: after the user dismisses the ad the instance transitions to *spent* and can neither be reloaded nor shown again. Create a new `VelocityInterstitialAd` for every impression.

### Basic Integration

```swift
@MainActor
class MyViewController: UIViewController, VelocityInterstitialAdDelegate {

    private var interstitialAd: VelocityInterstitialAd?

    // MARK: - Load

    func loadInterstitial() {
        let request = VelocityInterstitialAdRequest.Builder(adUnitId: "your-ad-unit-id")
            .withAdditionalContext(nil) // Optional: extra context for targeting
            .build()
        let ad = VelocityInterstitialAd(request)
        interstitialAd = ad
        ad.load(delegate: self)
    }

    // MARK: - Show

    func showInterstitialIfReady() {
        guard let ad = interstitialAd, ad.isReady else { return }
        ad.show()
    }

    // MARK: - VelocityInterstitialAdDelegate

    func onAdLoaded(interstitialAd: VelocityInterstitialAd) {
        // Ad is ready — show immediately or defer to a natural break point.
        interstitialAd.show()
    }

    func onAdFailedToLoad(interstitialAd: VelocityInterstitialAd, error: VelocityAdsError) {
        print("Interstitial failed to load: \(error)")
        self.interstitialAd = nil
    }

    func onAdShown(interstitialAd: VelocityInterstitialAd) {
        // Fullscreen surface is visible. Pause game audio, timers, etc.
    }

    func onAdImpression(interstitialAd: VelocityInterstitialAd) {
        // Ad impression recorded — align your own impression tracking here if needed.
    }

    func onAdFailedToShow(interstitialAd: VelocityInterstitialAd, error: VelocityAdsError) {
        // Show was rejected. The ad is still ready unless it expired or was destroyed.
        print("Interstitial failed to show: \(error)")
    }

    func onAdClicked(interstitialAd: VelocityInterstitialAd) {
        // User tapped the ad. The SDK opens the click-through URL automatically.
    }

    func onAdDismissed(interstitialAd: VelocityInterstitialAd) {
        // Fullscreen surface dismissed. Resume game, timers, etc.
        // The instance is now spent — release it and pre-load the next one.
        interstitialAd.destroy()
        self.interstitialAd = nil
        loadInterstitial()   // Pre-load for the next break point
    }
}
```

> **Threading:** `show()` is annotated `@MainActor` and must be called on the main thread. All `VelocityInterstitialAdDelegate` callbacks are delivered on the main thread. The protocol is annotated `@MainActor` — conform your delegate with `@MainActor` to update UI directly from callbacks.

### Pre-loading

Load the interstitial ahead of time so it is ready at the natural break point:

```swift
// Load on app launch or after the previous ad is dismissed
func applicationDidFinishLaunching() {
    loadInterstitial()
}

// At the break point, show only if already ready
func levelCompleted() {
    if let ad = interstitialAd, ad.isReady {
        ad.show()
    } else {
        // Ad not ready — skip this break point or show after load
    }
}
```

### Cleanup

Call `destroy()` whenever the hosting view controller or object is deallocated, to cancel any in-flight load and silence callbacks:

```swift
deinit {
    interstitialAd?.destroy()
}
```

`destroy()` is idempotent and safe to call on a spent instance.

### Concurrent Shows

At most one fullscreen interstitial can be on screen process-wide. If `show()` is called while another ad is presenting, it is immediately rejected via `onAdFailedToShow` with error code `2007` (`internalError`). No user-visible action is taken and the instance remains ready.

### Presenter Resolution

The SDK automatically resolves the topmost `UIViewController` across the active scene's window hierarchy to present the fullscreen surface. If your app uses a non-standard container hierarchy or overlay windows that confuse auto-resolution, supply a custom presenter:

```swift
// In AppDelegate or SceneDelegate — call once, before or after initSDK
VelocityAds.setPresenterProvider { [weak self] in
    self?.window?.rootViewController
}
```

See [`setPresenterProvider(_:)`](#setpresenterprovider-advanced) in the API Reference for full details.

---

## Rewarded Ads

Rewarded ads are fullscreen ads — typically video — where the user engages with the ad in exchange for an in-app reward (e.g. currency, lives, or premium content). The SDK handles the fullscreen presentation surface, player chrome, skip/close controls, and ad tracking automatically. When the user completes the ad, `onUserRewarded` fires before `onAdDismissed` — grant the reward when you receive that callback.

### 1. Create an ad request

```swift
let adRequest = VelocityRewardedAdRequest.Builder(adUnitId: "your-ad-unit-id")
    .withAdditionalContext(nil) // Optional: extra context for targeting
    .build()
```

### 2. Create and load the ad

```swift
let rewardedAd = VelocityRewardedAd(adRequest)
rewardedAd.load(delegate: self)
```

### 3. Implement VelocityRewardedAdDelegate

```swift
extension YourViewController: VelocityRewardedAdDelegate {

    // Required
    func onAdLoaded(rewardedAd: VelocityRewardedAd) {
        // Ad is ready — show when appropriate
        rewardedAd.show()
    }

    func onAdFailedToLoad(rewardedAd: VelocityRewardedAd, error: VelocityAdsError) {
        print("Rewarded ad failed to load: \(error)")
    }

    func onUserRewarded(rewardedAd: VelocityRewardedAd) {
        // Grant reward to user
    }

    // Optional
    func onAdShown(rewardedAd: VelocityRewardedAd) { }
    func onAdImpression(rewardedAd: VelocityRewardedAd) { }
    func onAdDismissed(rewardedAd: VelocityRewardedAd) {
        // Create a new VelocityRewardedAd for the next ad
        rewardedAd.destroy()
    }
}
```

### Callback reference

| Callback | Required | Description |
|---|---|---|
| `onAdLoaded(rewardedAd:)` | Yes | Ad loaded and ready to show |
| `onAdFailedToLoad(rewardedAd:error:)` | Yes | Ad failed to load |
| `onUserRewarded(rewardedAd:)` | Yes | User completed the video; grant the reward |
| `onAdShown(rewardedAd:)` | No | Fullscreen surface became visible |
| `onAdImpression(rewardedAd:)` | No | Ad impression recorded |
| `onAdFailedToShow(rewardedAd:error:)` | No | `show()` was rejected or failed |
| `onAdClicked(rewardedAd:)` | No | User opened the click-through |
| `onAdDismissed(rewardedAd:)` | No | Fullscreen surface dismissed (terminal callback) |

---

## Banner Ads

Banner ads are compact HTML creatives rendered inline in your own layout — anchored at the bottom of the screen, embedded in a feed, or placed anywhere else a `UIView` fits. Unlike interstitial and rewarded ads there is no fullscreen presentation and no `show()` step: the SDK renders the creative directly inside a `VelocityBannerAdView` that you create, size, and place. The banner is visible as soon as the view is in your view hierarchy and stays rendered until you call `destroy()`. The SDK does not auto-refresh banners — load a new instance when you want a new creative.

### Lifecycle

```
Created → load(bannerView:delegate:) → Loading → onAdLoaded → Rendering (continuous)
                                          ↓
                                  onAdFailedToLoad

Any state → destroy() → Destroyed (terminal)
```

A banner instance is **single-use**: exactly one `load(bannerView:delegate:)` call per instance, and exactly one of `onAdLoaded` / `onAdFailedToLoad` fires per call. A second `load` on the same instance fails with `adAlreadyLoaded` (2008); calling `load` while a load is in flight fails with `loadAlreadyInProgress` (2003); calling `load` after `destroy()` fails with `adDestroyed` (2010). Create a new `VelocityBannerAd` for every creative you want to display.

### Banner Sizes

Every request carries a `VelocityBannerAdSize` that determines the size of the ad that is served:

| Size | Dimensions | Use |
|------|-----------|-----|
| `.banner` | 320 × 50 pt | Standard mobile banner |
| `.mrec` | 300 × 250 pt | Medium rectangle (MREC), typical in feeds |
| `.leaderboard` | 728 × 90 pt | Wide banner, typical on iPad |
| `.adaptiveBanner(width:)` | your width × computed height | Full-width banner whose height is anchored to the 320:50 aspect ratio, clamped to [32, 90] pt |

For adaptive banners, read the computed size back from the value to size your container:

```swift
let adaptive = VelocityBannerAdSize.adaptiveBanner(width: view.bounds.width)
// adaptive.width and adaptive.height are the resolved slot dimensions in points
```

### Basic Integration (UIKit)

```swift
@MainActor
class MyViewController: UIViewController, VelocityBannerAdDelegate {

    private var bannerAd: VelocityBannerAd?
    private let bannerView = VelocityBannerAdView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Place and size the banner view. intrinsicContentSize is .zero until the
        // ad loads, then reports the bound ad size — so with only position
        // constraints the view expands automatically on load.
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        loadBanner()
    }

    private func loadBanner() {
        let request = VelocityBannerAdRequest.Builder(adUnitId: "your-ad-unit-id", adSize: .banner)
            .build()
        let ad = VelocityBannerAd(request)
        bannerAd = ad
        ad.load(bannerView: bannerView, delegate: self)
    }

    // MARK: - VelocityBannerAdDelegate

    func onAdLoaded(ad: VelocityBannerAd) {
        // The creative is rendering inside bannerView.
    }

    func onAdFailedToLoad(ad: VelocityBannerAd, error: VelocityAdsError) {
        print("Banner failed to load: \(error)")
        bannerAd = nil
    }

    func onAdImpression(ad: VelocityBannerAd) {
        // Viewability impression recorded — see "Impression Semantics" below.
    }

    func onAdFailedToShow(ad: VelocityBannerAd, error: VelocityAdsError) {
        // Rendering failed after a successful load — release and load a new instance.
        ad.destroy()
        bannerAd = nil
    }

    func onAdClicked(ad: VelocityBannerAd) {
        // User tapped the banner. The SDK opens the click-through URL automatically.
    }

    deinit {
        bannerAd?.destroy()
    }
}
```

The banner view can be added to your hierarchy before or after calling `load` — the SDK attaches its player when the ad loads and the view acquires a window.

> **Threading:** `load(bannerView:delegate:)` is annotated `@MainActor` and must be called on the main thread. All `VelocityBannerAdDelegate` callbacks are delivered on the main thread; the protocol is `@MainActor`-annotated. `destroy()` is safe from any thread. The delegate is held weakly — retain it for as long as callbacks are expected.

### SwiftUI Integration

`VelocityBannerAdView` is a `UIView`, so SwiftUI hosts it through a small `UIViewRepresentable` wrapper. Forward the size proposed by the enclosing `.frame()` modifier to `handleContainerSizeChange(_:)` so the SDK can keep the creative's viewport in sync when the frame changes (e.g. on device rotation):

```swift
struct BannerAdRepresentable: UIViewRepresentable {
    let bannerView: VelocityBannerAdView
    let proposedSize: CGSize

    func makeUIView(context: Context) -> VelocityBannerAdView { bannerView }

    func updateUIView(_ uiView: VelocityBannerAdView, context: Context) {
        uiView.handleContainerSizeChange(proposedSize)
    }
}
```

Own the ad object, the banner view, and the delegate conformance in an `ObservableObject` so they outlive body re-evaluations:

```swift
@MainActor
final class BannerViewModel: ObservableObject, VelocityBannerAdDelegate {

    let bannerView = VelocityBannerAdView()
    let adSize = VelocityBannerAdSize.banner
    @Published private(set) var isLoaded = false

    private var bannerAd: VelocityBannerAd?

    func load() {
        let request = VelocityBannerAdRequest.Builder(adUnitId: "your-ad-unit-id", adSize: adSize)
            .build()
        let ad = VelocityBannerAd(request)
        bannerAd = ad
        ad.load(bannerView: bannerView, delegate: self)
    }

    func onAdLoaded(ad: VelocityBannerAd) {
        isLoaded = true
    }

    func onAdFailedToLoad(ad: VelocityBannerAd, error: VelocityAdsError) {
        print("Banner failed to load: \(error)")
    }

    deinit {
        bannerAd?.destroy()
    }
}

struct BannerSection: View {
    @StateObject private var viewModel = BannerViewModel()

    var body: some View {
        Group {
            if viewModel.isLoaded {
                BannerAdRepresentable(
                    bannerView: viewModel.bannerView,
                    proposedSize: CGSize(width: viewModel.adSize.width, height: viewModel.adSize.height)
                )
                .frame(width: viewModel.adSize.width, height: viewModel.adSize.height)
            }
        }
        .onAppear { viewModel.load() }
    }
}
```

SwiftUI calls `updateUIView` whenever the proposed size changes, so rotation is handled automatically by this recipe. See `BannerDemoView.swift` in the SampleApp for a complete working example, including adaptive sizing against the container width.

### Impression Semantics

`onAdImpression` fires when the banner records a **viewability impression**: as soon as at least 50 % of the banner view's area is visible on screen. A banner that is hidden, fully transparent, outside the window, not yet in a window, or shown while the app is not active (in the background, or behind the app switcher, Control Center, Notification Center or a system alert) does not count. The impression fires **at most once per instance**.

`onAdImpression` is where the impression is billed; align your own impression analytics with this callback rather than with `onAdLoaded`.

### Rotation and Resizing

- **UIKit:** nothing to do — the banner view observes its own `layoutSubviews` and applies size changes automatically.
- **SwiftUI:** call `handleContainerSizeChange(_:)` from `updateUIView(_:context:)` as shown above. SwiftUI does not trigger a UIKit layout pass for every frame-modifier change, so the explicit forward keeps the creative's viewport in sync.

The rendered creative always fills the banner view's current bounds; the requested `VelocityBannerAdSize` determines which ad size is served, not a runtime constraint on the view's size.

### Cleanup

Call `destroy()` when you are done with the banner — when its hosting screen is dismissed, or before replacing it with a new instance:

```swift
deinit {
    bannerAd?.destroy()
}
```

`destroy()` cancels any in-flight load, removes the rendered content from the banner view, and silences all further callbacks. It is idempotent and safe to call from any thread. The `VelocityBannerAdView` itself remains yours — remove it from your hierarchy or reuse it with a **new** `VelocityBannerAd` instance.

---

## Regulations

### CCPA "Do Not Sell" Implementation

If your app serves users in regions where CCPA applies, you must provide a way for users to opt out of the sale of their personal information.

#### API Details

**Method:** `VelocityAds.setDoNotSell(_:)`

**Parameters:**
- `doNotSell` (`Bool`) - `true` if the user opts out of the sale of personal information, `false` if the user allows data sharing

**Example:**

```swift
// User opts out of data sale (CCPA)
VelocityAds.setDoNotSell(true)

// User allows data sharing
VelocityAds.setDoNotSell(false)
```

- ⚠️ **Geography-Specific:** Only call this API in regions where CCPA regulations apply.

### GDPR Consent Implementation

If your app serves users in the European Economic Area (EEA), UK, or other regions where GDPR applies, you must obtain user consent before processing their personal data.

#### API Details

**Method:** `VelocityAds.setConsent(_:)`

**Parameters:**
- `consent` (`Bool`) - `true` if the user gives consent for data processing, `false` if the user denies consent

**Example:**

```swift
// User gives consent (GDPR)
VelocityAds.setConsent(true)

// User denies consent
VelocityAds.setConsent(false)
```

- ⚠️ **Geography-Specific:** Only call this API in regions where GDPR regulations apply.

---

## Troubleshooting

### Common Issues

#### 1. "SDK not initialized" Error

**Problem:** Loading an ad (native, interstitial, rewarded, or banner) before `initSDK`, or before initialization has completed.


**Solution 1 — Use VelocityAdsInitDelegate:** 
Initialize at startup and only load ads after initialization succeeds. This avoids loading before the SDK is ready.

```swift
let initRequest = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY").build()
VelocityAds.initSDK(initRequest, delegate: MyInitDelegate())

@MainActor
class MyInitDelegate: VelocityAdsInitDelegate {
    func onInitSuccess() {
        // SDK is ready — enable ad loading in your UI or trigger first ad load
        enableAdLoading()
    }
    
    func onInitFailure(error: VelocityAdsError) {
        // Handle failure (e.g. show message, disable ad features)
        print("SDK init failed: \(error)")
    }
}
```

**Solution 2 - Check before loading:**
Before ad loading, ensure the SDK is initialized and init if needed.

```swift
// When you're about to load an ad (e.g. in response to user action):
guard VelocityAds.isInitialized() else {
    // SDK not ready — init was not called, failed, or hasn't completed yet.
    return  // Skip this ad load, or retry later when initialized
}

let adRequest = VelocityNativeAdRequest.Builder(adUnitId: adUnitId)
    .withPrompt(prompt)
    .withAIResponse(aiResponse)
    .withConversationHistory(conversationHistory)
    .withAdditionalContext(additionalContext)
    .build()
let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

#### Init Failure Handling (Connectivity + Retry)

Initialization can fail due to transient network conditions (offline, weak signal, DNS timeout, captive portals, temporary server errors). A resilient integration should:

- Check connectivity before retrying
- Retry with exponential backoff (and jitter)
- Stop retrying after a max attempt count
- Keep app UX responsive (do not block startup forever)

Example strategy:

```swift
import Network
import VelocityAdsSDK

@MainActor
final class SDKInitCoordinator: VelocityAdsInitDelegate {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "sdk.init.network.monitor")
    private var isOnline = true

    private var retryAttempt = 0
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0   // 1s
    private let maxDelay: TimeInterval = 30.0   // cap

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = (path.status == .satisfied)
        }
        monitor.start(queue: monitorQueue)
        initSDK()
    }

    private func initSDK() {
        let request = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY").build()
        VelocityAds.initSDK(initRequest, delegate: self)
    }

    func onInitSuccess() {
        print("VelocityAds init success")
    }

    func onInitFailure(error: VelocityAdsError) {
        print("VelocityAds init failed: \(error)")

        guard retryAttempt < maxRetries else {
            print("Max retries reached. Continue app flow without ads for now.")
            return
        }

        guard isOnline else {
            print("Offline detected. Wait for connectivity before retrying.")
            return
        }

        // Exponential backoff with jitter:
        // delay = min(maxDelay, baseDelay * 2^attempt) + random(0...0.5)
        let exponential = min(maxDelay, baseDelay * pow(2.0, Double(retryAttempt)))
        let jitter = Double.random(in: 0...0.5)
        let delay = exponential + jitter

        retryAttempt += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.initSDK()
        }
    }

    deinit {
        monitor.cancel()
    }
}
```

Best practices:

- Retry only transient failures (network/timeouts/5xx). Avoid aggressive retries for configuration errors.
- Add jitter to avoid synchronized retry spikes across devices.
- Cap retry delay and max attempts to protect battery/data usage.
- Reset retry counter after any successful init.
- Re-attempt init when app becomes active and network is restored.
- Log failures and retry metadata (`attempt`, `delay`, `error.code`) for observability.

#### 2. Memory / Lifecycle

**Problem:** Using a callback that is deallocated before the callback runs (e.g. a cell that is reused).

**Solution:** Retain the callback (e.g. in a dedicated object or via the view controller) until `onAdLoaded` or `onAdFailedToLoad` is called. Avoid using `self` from a short-lived object (e.g. table view cell) as the callback without retaining it.

Call `destroy()` on every ad instance — native, interstitial, rewarded, or banner — when the hosting screen is dismissed, typically in `deinit`.

#### 3. Ad Fails to Show (Fullscreen)

**Problem:** `onAdFailedToShow` fires when you call `show()` on an interstitial or rewarded ad.

**Common causes:**

- **The ad wasn't ready.** `show()` was called before `onAdLoaded`, or after the loaded ad expired, was already shown, or was destroyed. Always gate `show()` behind `isReady`.
- **Another fullscreen ad is already on screen.** At most one fullscreen ad can present process-wide. Don't call `show()` while another interstitial or rewarded ad is still visible — wait for its `onAdDismissed`.
- **No presenter available.** The SDK couldn't find a view controller to present from — e.g. the app is backgrounded, mid-transition, or uses a non-standard window setup. Only call `show()` while the UI is foregrounded and idle, or provide `VelocityAds.setPresenterProvider` for unusual window hierarchies.
- **The creative failed to render.** A rare playback/render error inside the ad itself.

**Recovery:** The `error` tells you which case you hit. For the first three, the ad usually remains ready and `show()` can be retried once the blocking condition clears. For a render failure the instance is spent — destroy it and load a new one. When in doubt, destroying and reloading is always safe.

#### 4. No Ads Returned

**Possible causes:**
- No ads available for the given context
- Network issues
- Ad unit not configured

**Solution:** Handle `onAdFailedToLoad` gracefully (e.g. hide ad space or show fallback). The SDK continues to function even when no ads are available. This applies to every ad format.

A native load that fails with `VelocityAdsErrorCode.missingImpressionTracker` (`2014`) means the ad cannot be tracked and is not served. Treat it like no fill.

#### 5. SDK-Rendered Native Ad View Is Empty or 0 pt High

**Problem:** The ad loaded (`onAdLoaded` fired) but the `VelocityNativeAdView` shows nothing and reports a height of 0.

**Cause:** The loaded ad could not be rendered. The view collapses to 0 pt and stays empty; nothing is reported to the delegate. Hosting rows follow the collapse, so no gap is left.

**Solution:** Nothing is required — the slot disappears. Configuring another ad (or the same ad again) into the view via `configureAdView(_:)` restores normal sizing. If the view is 120 pt or 254 pt but blank, the ad has not been rendered yet; the placeholder is drawn until it is.

#### 6. SDK-Rendered Native Ad View Has the Wrong Height

**Problem:** The card is cut off or letterboxed, or an ad that cannot be rendered leaves an empty gap instead of collapsing.

**Cause:** A height constraint, `.frame(height:)`, `minSize` or a row-height derived from `adViewHeights` pins the view. The request lists the heights the placement *allows*; the view takes one of them when it is created or configured, and collapses to 0 if the ad cannot be rendered. A pinned height that differs from the view's clips or letterboxes the card, and any pinned height hides the collapse.

**Solution:** Pin the view's edges only and use self-sizing rows. In SwiftUI, host the ad with `createAdSwiftUIView()` rather than a hand-written `UIViewRepresentable` (see [The view owns its height](#the-view-owns-its-height)).

---

## Best Practices

### 1. Initialization

✅ **DO:**
- Initialize in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or in your `@main` App's `init()`
- Handle initialization callbacks

❌ **DON'T:**
- Initialize inside a view controller or view
- Initialize multiple times unnecessarily

### 2. Ad Loading

Applies to every ad format — native, interstitial, rewarded, and banner.

✅ **DO:**
- Handle errors gracefully (e.g. hide ad view or show fallback)
- Wait for `onAdLoaded` before showing (fullscreen) or displaying (native / banner) the ad
- Pre-load fullscreen ads ahead of the moment you want to show them, and guard `show()` with `isReady`
- Provide meaningful context for native ads (prompt, ai response, conversation history)
- Track impressions and clicks for analytics

❌ **DON'T:**
- Use empty or placeholder context when you have real content
- Block the main thread
- Ignore error callbacks
- Call `load()` again on an already-loaded instance — create a new one instead

### 3. Showing Fullscreen Ads

✅ **DO:**
- Show interstitials at natural break points (between screens, after completing a task)
- Show rewarded ads only at explicit opt-in moments and grant the reward in `onUserRewarded`
- On `onAdFailedToShow`, destroy the instance and load a fresh one — the simplest reliable recovery

❌ **DON'T:**
- Show a fullscreen ad mid-interaction or over active content
- Reuse a spent instance — after `onAdDismissed` following a successful show, create a new ad object

### 4. Memory Management

✅ **DO:**
- Call `destroy()` on every ad instance — native, interstitial, rewarded, or banner — when it is no longer needed
- Clear or release ad-related views when they are no longer visible
- Use weak references where appropriate (e.g. in delegates)
- Clean up in `deinit` or when the view controller is dismissed

❌ **DON'T:**
- Keep strong references to ad views after the screen is dismissed

### 5. Error Handling

✅ **DO:**

```swift
func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
    print("Ad error: \(error)")
    // Show fallback content or hide ad space
    hideAdView()
}
```

❌ **DON'T:**
- Ignore errors or crash the app on ad failure

---

## Migrating to 0.12.0 (Native Ads)

0.12.0 replaces the native-ad stack. SDK-rendered native ads come in two card heights — 120 pt and 254 pt — with image carousels, inline video and RTL layouts built in. Update your code as follows.

### API mapping

| Before (0.11.x) | 0.12.0 |
|---|---|
| `VelocityNativeAdViewRequest.Builder(adUnitId:, adViewSize: .M)` | `VelocityNativeAdViewRequest.Builder(adUnitId:, adViewHeights: [.height120])` — `adViewHeights` is optional; omitted = every height |
| `VelocityNativeAdViewSize` (`.XS` / `.S` / `.M` / `.L`), `.heightPt` | `VelocityNativeAdViewHeight` (`.height120`, `.height254`), `.height` |
| `request.adViewSize` | `request.adViewHeights` |
| Height constraints, `.frame(height:)`, `minSize` or row heights from `adViewSize.heightPt`, `largeExpandedHeightPt`, `largeCollapsedHeightPt` | Remove them — the view owns its height (including the collapse to 0); pin edges only (see [The view owns its height](#the-view-owns-its-height)) |
| `nativeAd.collapse()`, `adView.collapse()`, `nativeAd.onCollapseStateChanged`, `adView.onCollapseStateChanged` | Removed — no replacement |
| `data.getLargeImageUrl(width:height:)`, `data.largeImageUrl`, `data.squareImageUrl` | `data.imagesByAspectRatio` (every image, keyed by aspect-ratio string) / `data.images(for: "1.9:1")` (landscape images) / `data.images(for: "1:1")` (square images) |
| `data.sponsoredLabel` | Removed — no replacement |
| `data.title`, `description`, `callToAction`, `advertiserName`, `badgeLabel`, `advertiserIconUrl` (`String`) | `String?` — render each only when present |
| `NativeAd(...)` with non-optional creative fields (tests, mocks) | Every creative field (`title`, `description`, `callToAction`, `advertiserName`, `badgeLabel`, `advertiserIconUrl`) is `String?` with a `nil` default; `imagesByAspectRatio` replaces the image URL parameters |
| `AdColors` (13 non-optional tokens) | 8 optional tokens: `cardBackground`, `cardBackgroundPressed`, `cardBorder`, `titleText`, `descriptionText`, `ctaBackground` (`.clear` → border-only CTA), `ctaBorder`, `ctaText`. `nil` = Velocity default |
| `AdColors.light` / `AdColors.dark` (SDK default palettes), `AdColorScheme(light: .light, dark: .dark)`, `AdColorScheme.Builder()` seeded from them | Removed — `AdColors()` / `AdColorScheme()` start with every token `nil` (the Velocity default); build `AdColors(...)` with only the tokens you want to pin. `AdColorScheme.Builder().light { $0.copy(...) }` / `.dark { ... }` keep working |
| `AdColors.brandText`, `brandIconBorder` | Removed — locked by design; no replacement |
| `AdColors.sponsoredLabelText`, `sponsoredBadgeBackground`, `sponsoredBadgeText`, `chevronIconTint` | Removed — no replacement |
| `AdTypography.Builder(selectedSize:)` with `brandName` / `sponsoredLabel` / `sponsoredBadgeText` / `title` / `description` / `ctaButton` blocks, `FontStyle(fontSize:fontWeight:)` | `AdTypography(title:, description:, cta:)` — each an `AdTextStyle(fontFamily:, textSize:)` with `AdFontFamily` `.regular`, `.medium` or `.semiBold`; `FontStyle` and `UIFont.Weight` are gone; colors live in `AdColors` |
| `AdViewConfiguration.typography` / `AdViewConfiguration(typography:)` | Renamed to `adTypography` — `AdViewConfiguration(adTypography:)`, `config.adTypography`. The value type changed too (see the `AdTypography` row above) |
| `AdViewConfiguration.create(size:)` | Removed — use `AdViewConfiguration()` (or `AdViewConfiguration(colorScheme:adTypography:darkTheme:cornerRadius:)`); there is no per-size default any more |
| Hand-written `UIViewRepresentable` around `createAdView()` with a fixed frame | Prefer `createAdSwiftUIView()`; a representable can follow the height only via `sizeThatFits` on iOS 16+ |
| — | `AdViewConfiguration.cornerRadius` (0–24 pt; `nil` = Velocity default) |
| — | `VelocityAdsErrorCode.missingImpressionTracker` (`2014`) |

### Choosing a height

The four 0.11.x sizes collapse into two heights. Suggested mapping:

| Before (0.11.x) | Move to (0.12.0) |
|---|---|
| `.XS`, `.S` or `.M` | `.height120` (120 pt) |
| `.L` | `.height254` (254 pt) |

Pass only the height you migrated to in the request. Omit the heights to allow every height.

### Behavior changes

- **The view owns its height.** When it is created or configured, the view takes one of the heights the request allows and, in normal operation, keeps it; it collapses to 0 if the ad cannot be rendered. Do not pin a height around it. `UITableView` / `UICollectionView` rows hosting it are re-measured automatically when its height changes (e.g. the collapse).
- **Placeholder.** From creation (or `configureAdView`) until the ad is rendered, the view draws a card background and media frame at the card's size, following Light/Dark mode, the configured corner radius and `cardBackground` — the slot is never a transparent gap.
- **Video.** Video ads loop or stop on their poster with a Replay button, depending on the ad. A video whose media cannot be played shows its poster. Playback is not reported to the delegate, and video is never exposed through `NativeAd`.
- **Images.** `imagesByAspectRatio` keeps every aspect ratio included with the ad, including ratios the SDK-rendered card does not use — read any of them with `images(for: "<ratio>")`.
- **Load failures.** An ad that cannot be tracked fails `onAdFailedToLoad` with code `2014` (`missingImpressionTracker`). Treat it like no fill.
- **Render failures.** If an ad that already loaded cannot be rendered, the view collapses to 0 pt and stays empty; nothing is reported to the delegate. Configuring another ad into the view restores normal sizing.
- **Configuration.** Invalid values (radius outside 0–24 or a non-positive text size) are ignored with a warning log and the default is kept. Dynamic Type is not applied to the configured text size.

---

## API Reference

### VelocityAds

#### `setUserId(_:)`

```swift
VelocityAds.setUserId(_ userId: String?)
```

**Parameters:**
- `userId` - Publisher user identifier (optional)

For best performance, set user ID before calling `initSDK`.

#### `initSDK(_:delegate:)`

```swift
let request = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY").build()
VelocityAds.initSDK(request, delegate: MyInitDelegate())
```

**Parameters:**
- `request` - Initialization request object containing required `appKey`
- `delegate` - Initialization delegate (required)

#### `setPresenterProvider(_:)` *(Advanced)*

```swift
VelocityAds.setPresenterProvider(_ provider: (() -> UIViewController?)?)
```

Supplies a `UIViewController` root that the SDK uses to present store destinations when a user taps an ad.

**Most apps do not need to call this method.** The SDK automatically discovers the correct presenter by scanning the active `UIWindowScene` and walking the `presentedViewController` chain. Call this only when auto-discovery produces the wrong result:

- **Custom container view controllers** that are not `UITabBarController` or `UINavigationController` — the auto-discovery walk does not know how to descend into them, so it stops at the wrong level.
- **Overlay windows** from debug tools, consent managers, or other SDKs that sit on top of your content and are incorrectly identified as the topmost presenter.
- **Non-standard root VC patterns** such as dynamic root swapping at launch, or multi-scene edge cases where `activationState` alone is not a reliable signal.

**Usage:**

```swift
// In your AppDelegate or SceneDelegate — call once before or after initSDK.
VelocityAds.setPresenterProvider { [weak self] in
    self?.window?.rootViewController
}

// To restore auto-discovery:
VelocityAds.setPresenterProvider(nil)
```

**Parameters:**
- `provider` - A closure returning the `UIViewController` the SDK should use as the starting point for presenter resolution. The SDK walks `presentedViewController` forward from this VC, so native modals pushed on top are handled automatically. Pass `nil` to clear any override and restore auto-discovery.

> **Important:** The SDK retains the closure for the lifetime of the process (or until you call `setPresenterProvider(nil)`). Capture `self` **weakly** unless the providing object lives for the entire process lifetime (e.g. `UIApplicationDelegate`). For `UISceneDelegate` or any object that may be deallocated, always use `[weak self]`.

#### `VelocityNativeAdRequest` / `VelocityNativeAd`

```swift
let adRequest = VelocityNativeAdRequest.Builder(adUnitId: String)
    .withPrompt(_ prompt: String?)
    .withAIResponse(_ aiResponse: String?)
    .withConversationHistory(_ history: [[String: Any]]?)
    .withAdditionalContext(_ context: String?)
    .includePreliminaryText(_ include: Bool)
    .build() -> VelocityNativeAdRequest

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: VelocityNativeAdDelegate)
```

**`VelocityNativeAdRequest` builder parameters:**
- `adUnitId` - Ad unit identifier (required)
- `prompt` - User's prompt (optional, but recommended for context)
- `aiResponse` - AI-generated response content (optional, but recommended for targeting)
- `conversationHistory` - Conversation history for ad targeting — array of `["role": "user"/"assistant", "content": "..."]` dictionaries (optional)
- `additionalContext` - Extra context string to improve ad relevance (optional)
- `includePreliminaryText` - When `true`, requests a short contextual snippet ("preliminary text") that could be displayed above the ad creative. Defaults to `false`. (optional)

**`VelocityNativeAd` properties (available after `onAdLoaded`):**

Ad creative data is accessed via `nativeAd.data` (type `NativeAd?`, non-nil after a successful load). Every creative field is optional; only `adId`, `clickUrl` and `impressionUrl` are always present:

- `nativeAd.data?.adId` (`String`) - Unique ad identifier
- `nativeAd.data?.title` (`String?`) - Ad headline
- `nativeAd.data?.description` (`String?`) - Ad body text
- `nativeAd.data?.callToAction` (`String?`) - CTA button text (e.g., "Learn More")
- `nativeAd.data?.advertiserName` (`String?`) - Advertiser/brand name
- `nativeAd.data?.badgeLabel` (`String?`) - Short badge label (e.g., "Ad")
- `nativeAd.data?.advertiserIconUrl` (`String?`) - Brand logo URL
- `nativeAd.data?.imagesByAspectRatio` (`[String: [String]]`) - Every image included with the ad, keyed by its aspect-ratio string (today `"1:1"` and `"1.9:1"`; other ratios may appear)
- `nativeAd.data?.images(for:)` (`[String]`) - The images for an aspect-ratio string (for example `images(for: "1.9:1")`); an empty array when absent. See [Image aspect ratios](#image-aspect-ratios)
- `nativeAd.data?.clickUrl` (`String`) - Destination URL when ad is clicked (opened by the SDK for registered views — do not open it yourself). May be empty when the ad leads to a store page — the SDK handles it; never open it yourself
- `nativeAd.data?.impressionUrl` (`String`) - URL to track ad impressions (fired by the SDK for registered views)
- `nativeAd.data?.preliminaryText` (`String?`) - Short contextual text intended to be displayed between the AI response and the ad creative. (optional)

#### `VelocityNativeAdViewRequest`

Extends `VelocityNativeAdRequest` with the allowed card heights and theming for SDK-rendered ad views. Required to use `createAdView()` and `createAdSwiftUIView()`. Only `adUnitId` is required; `adViewHeights` omitted or empty allows every height this SDK supports.

```swift
VelocityNativeAdViewRequest.Builder(adUnitId: String, adViewHeights: [VelocityNativeAdViewHeight] = [])
    .withPrompt(_ prompt: String?)                           // Optional: Provide for context
    .withAIResponse(_ aiResponse: String?)                   // Optional: Provide for better targeting
    .withConversationHistory(_ history: [[String: Any]]?)    // Optional: Previous conversation
    .withAdditionalContext(_ context: String?)               // Optional: Extra context
    .includePreliminaryText(_ include: Bool)                 // Optional: Request preliminary text
    .withAdViewConfiguration(_ config: AdViewConfiguration)  // Optional: See Ad Theming
    .build() -> VelocityNativeAdViewRequest

request.adViewHeights   // [VelocityNativeAdViewHeight] — the heights this request allows
request.configuration   // AdViewConfiguration — AdViewConfiguration() when not set
```

#### `VelocityNativeAd` — View Lifecycle Methods

```swift
// Create SDK-rendered views (requires VelocityNativeAdViewRequest and a successful load).
// The returned view owns its height: one of the allowed heights, or 0 if the ad cannot be rendered.
@MainActor nativeAd.createAdView() -> VelocityNativeAdView?
@MainActor nativeAd.createAdSwiftUIView() -> AnyView?

// Reconfigure an existing SDK-rendered view for cell recycling.
// Returns false if the ad is not loaded, destroyed, not a view request, or called off the main thread.
@discardableResult @MainActor nativeAd.configureAdView(_ adView: VelocityNativeAdView) -> Bool

// Manual rendering interaction tracking
@MainActor nativeAd.registerViewForInteraction(adView: UIView, clickableViews: [UIView])
@MainActor nativeAd.unregisterViewForInteraction()

// Teardown (terminal — instance cannot be reloaded after this call)
@MainActor nativeAd.destroy()
```

> **Note:** `createAdView()`, `createAdSwiftUIView()`, `configureAdView(_:)`, `registerViewForInteraction(adView:clickableViews:)`, `unregisterViewForInteraction()`, and `destroy()` are annotated `@MainActor`. Calling them from a delegate callback is safe (delegate callbacks are already delivered on the main thread). From a non-isolated context, wrap the call in `DispatchQueue.main.async { }` or `await MainActor.run { }`.

#### `VelocityNativeAd` — Interaction Tracking

```swift
// Manual rendering: register impression and click tracking
@MainActor nativeAd.registerViewForInteraction(adView: UIView, clickableViews: [UIView])
@MainActor nativeAd.unregisterViewForInteraction()
```

> **Note:** `registerViewForInteraction(adView:clickableViews:)` and `unregisterViewForInteraction()` are annotated `@MainActor`. Calling them from a delegate callback is safe (delegate callbacks are already delivered on the main thread). From a non-isolated context, wrap the call in `DispatchQueue.main.async { }` or `await MainActor.run { }`.

#### `VelocityNativeAdView`

```swift
public final class VelocityNativeAdView: UIView
```

The host of an SDK-rendered card, returned by `createAdView()`. Publishers never instantiate it. It owns its height (`intrinsicContentSize` / `sizeThatFits`): one of the heights the request allows, taken when the view is created or configured and unchanged in normal operation; 0 pt if the bound ad cannot be rendered. Pin its edges, not its height. A hosting `UITableView` / `UICollectionView` row is re-measured automatically when the height changes (e.g. the collapse). Width follows the superview. The rendered height and media are not exposed.

### Models

#### `NativeAd` (ad creative data)

Accessed via `VelocityNativeAd.data` after a successful load with `VelocityNativeAdDelegate`.

| Field | Type | Description |
|-------|------|-------------|
| `adId` | `String` | Ad identifier used for impression/click tracking |
| `title` | `String?` | Ad headline |
| `description` | `String?` | Ad body text |
| `callToAction` | `String?` | CTA button text (e.g. "Learn More") |
| `advertiserName` | `String?` | Advertiser/brand name |
| `badgeLabel` | `String?` | Badge text (e.g. "Ad") |
| `advertiserIconUrl` | `String?` | Advertiser logo/icon URL |
| `imagesByAspectRatio` | `[String: [String]]` | Every image included with the ad, keyed by its aspect-ratio string (today `"1:1"` and `"1.9:1"`; other ratios may appear) |
| `images(for:)` | `[String]` | The images for an aspect-ratio string (for example `images(for: "1.9:1")`); an empty array when absent. See [Image aspect ratios](#image-aspect-ratios) |
| `clickUrl` | `String` | URL opened on ad click (by the SDK, for registered views — do not open it yourself). Always present but may be empty when the ad leads to a store page — the SDK handles it; never open it yourself |
| `impressionUrl` | `String` | Impression tracking URL (fired by the SDK, for registered views) |
| `preliminaryText` | `String?` | Short contextual text to display above the ad (optional — requires `includePreliminaryText(true)` on the request) |

Every creative field except `adId`, `clickUrl` and `impressionUrl` may be missing — render each only when present. Video is never exposed here: a video ad renders through the SDK-rendered view only.

#### `VelocityNativeAdViewHeight`

```swift
public enum VelocityNativeAdViewHeight: String, CaseIterable {
    case height120 = "HEIGHT_120"   // 120 pt
    case height254 = "HEIGHT_254"   // 254 pt

    public var height: CGFloat       // 120 / 254
    public var wireValue: String     // "HEIGHT_120" / "HEIGHT_254"

    public static func normalize(_ requested: [VelocityNativeAdViewHeight]?) -> [VelocityNativeAdViewHeight]
    public static func fromWireValue(_ value: String?) -> VelocityNativeAdViewHeight?
    public static func fromHeight(_ height: CGFloat) -> VelocityNativeAdViewHeight?
}
```

| Value | Height |
|-------|--------|
| `.height120` | 120 pt |
| `.height254` | 254 pt |

`normalize` turns an omitted or empty array into every supported height and removes duplicates. `fromWireValue` / `fromHeight` return `nil` for a value this SDK version does not define — unknown heights are never mapped to a default.

#### Image aspect ratios

`NativeAd` images are keyed by their aspect-ratio string. Today an ad can include:

| Key | Images |
|-----|--------|
| `"1:1"` | Square images |
| `"1.9:1"` | Landscape images |

Other ratios may be added in future and are read the same way: iterate `data.imagesByAspectRatio`, or call `data.images(for: "<ratio>")` — for example `data.images(for: "1.9:1").first`. `images(for:)` returns an empty array when the ad has no images for that ratio.

#### `AdViewConfiguration`

```swift
public struct AdViewConfiguration {
    public static let maxCornerRadius: CGFloat = 24

    public var colorScheme: AdColorScheme?   // nil = Velocity default colors
    public var adTypography: AdTypography?   // nil = Velocity typography
    public var darkTheme: Bool?              // nil = follow the host's userInterfaceStyle
    public var cornerRadius: CGFloat?        // 0 … 24 pt; nil = Velocity default

    public init(
        colorScheme: AdColorScheme? = nil,
        adTypography: AdTypography? = nil,
        darkTheme: Bool? = nil,
        cornerRadius: CGFloat? = nil
    )
}
```

A radius outside 0–24 is ignored with a warning log; the default stays.

#### `AdColorScheme`

```swift
public struct AdColorScheme {
    public let light: AdColors
    public let dark: AdColors

    // An omitted palette is AdColors() — every token at the Velocity default.
    public init(light: AdColors = AdColors(), dark: AdColors = AdColors())

    public final class Builder {
        public init(base: AdColorScheme = AdColorScheme())

        // Configure via transform block (receives current palette, return modified copy):
        @discardableResult public func light(_ block: (AdColors) -> AdColors) -> Builder
        @discardableResult public func dark(_ block: (AdColors) -> AdColors) -> Builder

        // Or replace entire palette:
        @discardableResult public func light(_ colors: AdColors) -> Builder
        @discardableResult public func dark(_ colors: AdColors) -> Builder

        public func build() -> AdColorScheme
    }
}
```

#### `AdColors`

The eight color tokens of the card for one appearance. Every token is optional: `nil` keeps the Velocity default. `AdColors()` keeps every default.

```swift
public struct AdColors: Equatable {
    public let cardBackground: UIColor?
    public let cardBackgroundPressed: UIColor?
    public let cardBorder: UIColor?
    public let titleText: UIColor?
    public let descriptionText: UIColor?
    public let ctaBackground: UIColor?   // .clear = border-only CTA
    public let ctaBorder: UIColor?
    public let ctaText: UIColor?

    // Every parameter defaults to nil — the Velocity default.
    public init(
        cardBackground: UIColor? = nil,
        cardBackgroundPressed: UIColor? = nil,
        cardBorder: UIColor? = nil,
        titleText: UIColor? = nil,
        descriptionText: UIColor? = nil,
        ctaBackground: UIColor? = nil,
        ctaBorder: UIColor? = nil,
        ctaText: UIColor? = nil
    )

    // Returns a copy with only the specified tokens replaced (nil = keep):
    public func copy(
        cardBackground: UIColor? = nil,
        cardBackgroundPressed: UIColor? = nil,
        cardBorder: UIColor? = nil,
        titleText: UIColor? = nil,
        descriptionText: UIColor? = nil,
        ctaBackground: UIColor? = nil,
        ctaBorder: UIColor? = nil,
        ctaText: UIColor? = nil
    ) -> AdColors
}
```

#### `AdTypography`

A separate font family and text size for the title, the description and the CTA label. An omitted role keeps the Velocity default. The brand name and the Ad badge always keep Velocity's typography.

```swift
public struct AdTypography: Equatable {
    public let title: AdTextStyle?
    public let description: AdTextStyle?
    public let cta: AdTextStyle?

    public init(title: AdTextStyle? = nil, description: AdTextStyle? = nil, cta: AdTextStyle? = nil)
}
```

#### `AdTextStyle`

The font family and text size of one text role.

```swift
public struct AdTextStyle: Equatable {
    public let fontFamily: AdFontFamily?   // nil = the role's Velocity default family
    public let textSize: CGFloat?          // points; nil = Velocity default. Dynamic Type is not applied

    public init(fontFamily: AdFontFamily? = nil, textSize: CGFloat? = nil)
}
```

A non-finite or non-positive size is ignored with a warning log and the Velocity default stays. Text never grows the card — the title clamps to one line, the description to two.

#### `AdFontFamily`

```swift
public enum AdFontFamily: String, CaseIterable {
    case regular    // Inter Regular (weight 400)
    case medium     // Inter Medium (weight 500)
    case semiBold   // Inter SemiBold (weight 600)
}
```

#### `VelocityAdsInitRequest`

```swift
public final class VelocityAdsInitRequest {
    public final class Builder {
        public init(_ appKey: String)
        public func build() -> VelocityAdsInitRequest
    }
}
```

#### `VelocityAdsError`

```swift
public struct VelocityAdsError: Error, CustomStringConvertible {
    public let code: Int
    public let message: String
}
```

`code` is the category to branch on. `message` is human-readable detail — log it and include it in
support requests, but do not parse it.

`VelocityAdsError` conforms to `CustomStringConvertible`, so `print(error)` includes both code and message.

```swift
public enum VelocityAdsErrorCode {
    // Server / network errors (1xxx)
    public static let invalidURL: Int                  // 1000
    public static let networkError: Int                // 1001
    public static let jsonParseError: Int              // 1002
    public static let invalidResponse: Int             // 1003
    public static let emptyResponseBody: Int           // 1004
    public static let serverErrorField: Int            // 1005
    public static let httpFailure: Int                 // 1006

    // SDK state errors (2xxx)
    public static let invalidAppKey: Int               // 2000
    public static let sdkNotInitialized: Int           // 2001
    public static let sdkInitializationInProgress: Int // 2002
    public static let loadAlreadyInProgress: Int       // 2003
    public static let loadServiceUnavailable: Int      // 2004
    public static let invalidAdResponse: Int           // 2005
    public static let noFill: Int                      // 2006
    public static let internalError: Int               // 2007
    public static let adAlreadyLoaded: Int             // 2008
    public static let waterfallLoadFailed: Int         // 2009
    public static let adDestroyed: Int                 // 2010
    public static let invalidAdUnitId: Int             // 2011
    public static let adSpent: Int                     // 2012
    public static let missingImpressionTracker: Int    // 2014
}
```

Error code behavior:
- HTTP failures use `VelocityAdsErrorCode.httpFailure` (`1006`)
- HTTP status details are included in `VelocityAdsError.message`
- SDK-defined constants are centralized in `VelocityAdsErrorCode`:

**Server / network errors (1xxx):**
  - `VelocityAdsErrorCode.invalidURL` (`1000`) — Malformed URL
  - `VelocityAdsErrorCode.networkError` (`1001`) — Network request failed
  - `VelocityAdsErrorCode.jsonParseError` (`1002`) — Response JSON could not be parsed
  - `VelocityAdsErrorCode.invalidResponse` (`1003`) — Response structure is invalid
  - `VelocityAdsErrorCode.emptyResponseBody` (`1004`) — Server returned an empty body
  - `VelocityAdsErrorCode.serverErrorField` (`1005`) — Server returned an error field in the response
  - `VelocityAdsErrorCode.httpFailure` (`1006`) — HTTP status code indicates failure

**SDK state errors (2xxx):**
  - `VelocityAdsErrorCode.invalidAppKey` (`2000`) — `appKey` is empty or blank
  - `VelocityAdsErrorCode.sdkNotInitialized` (`2001`) — `load` called before `initSDK`
  - `VelocityAdsErrorCode.sdkInitializationInProgress` (`2002`) — `load` called while initialization is still in progress
  - `VelocityAdsErrorCode.loadAlreadyInProgress` (`2003`) — `load` called on an ad instance that is already loading
  - `VelocityAdsErrorCode.loadServiceUnavailable` (`2004`) — Internal load service is not available
  - `VelocityAdsErrorCode.invalidAdResponse` (`2005`) — Ad response is missing required data
  - `VelocityAdsErrorCode.noFill` (`2006`) — No ad available for the given context
  - `VelocityAdsErrorCode.internalError` (`2007`) — Unexpected internal SDK error
  - `VelocityAdsErrorCode.adAlreadyLoaded` (`2008`) — `load` called on an instance that has already loaded successfully. Create a new `VelocityNativeAd` for a new ad placement.
  - `VelocityAdsErrorCode.waterfallLoadFailed` (`2009`) — Waterfall load failed
  - `VelocityAdsErrorCode.adDestroyed` (`2010`) — `load` called on a destroyed instance. Create a new `VelocityNativeAd` for a new ad placement.
  - `VelocityAdsErrorCode.invalidAdUnitId` (`2011`) — `adUnitId` is empty or blank
  - `VelocityAdsErrorCode.adSpent` (`2012`) — `show` called on a fullscreen ad instance that was already shown. Load a new instance.
  - `VelocityAdsErrorCode.missingImpressionTracker` (`2014`) — Native only: the ad cannot be tracked and is not served. Treat it like no fill.

### Delegates

#### `VelocityAdsInitDelegate`

```swift
protocol VelocityAdsInitDelegate: AnyObject {
    func onInitSuccess()
    func onInitFailure(error: VelocityAdsError)
}
```

#### `VelocityNativeAdDelegate`

Single unified delegate for all ad loading paths (data-only and SDK-rendered views).

```swift
@MainActor
protocol VelocityNativeAdDelegate: AnyObject {
    func onAdLoaded(nativeAd: VelocityNativeAd)                                  // required
    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError)   // required
    func onAdImpression(nativeAd: VelocityNativeAd)                              // optional (default no-op)
    func onAdClicked(nativeAd: VelocityNativeAd)                                 // optional (default no-op)
}
```

All methods are delivered on the **main thread**. The protocol is `@MainActor`-annotated. Exactly one of `onAdLoaded` / `onAdFailedToLoad` fires per `load(delegate:)` call.

| Method | Required | Description |
|--------|----------|-------------|
| `onAdLoaded` | ✅ | Ad data is loaded. Call `createAdView()` or `createAdSwiftUIView()` for SDK-rendered views, or read `nativeAd.data` for manual rendering. |
| `onAdFailedToLoad` | ✅ | Ad failed to load. `error.code` identifies the reason; the original request remains readable via `nativeAd.adRequest`. |
| `onAdImpression` | Optional | Fires once when ≥ 50 % of the ad view is visible on screen. Default implementation is a no-op. |
| `onAdClicked` | Optional | User tapped the ad (SDK handles opening the click URL). Default implementation is a no-op. |

Video playback inside an SDK-rendered card is not reported to the delegate.

#### `VelocityInterstitialAdDelegate`

```swift
@MainActor
protocol VelocityInterstitialAdDelegate: AnyObject {
    func onAdLoaded(interstitialAd: VelocityInterstitialAd)
    func onAdFailedToLoad(interstitialAd: VelocityInterstitialAd, error: VelocityAdsError)
    func onAdShown(interstitialAd: VelocityInterstitialAd)
    func onAdImpression(interstitialAd: VelocityInterstitialAd)
    func onAdFailedToShow(interstitialAd: VelocityInterstitialAd, error: VelocityAdsError)
    func onAdClicked(interstitialAd: VelocityInterstitialAd)
    func onAdDismissed(interstitialAd: VelocityInterstitialAd)
}
```

All methods are delivered on the **main thread**. The protocol is `@MainActor`-annotated.

| Method | Required | Description |
|--------|----------|-------------|
| `onAdLoaded` | ✅ | Ad loaded and ready. Call `show()` now or at a later break point. |
| `onAdFailedToLoad` | ✅ | Load failed. `error.code` identifies the reason. Retry by calling `load(delegate:)` again. |
| `onAdShown` | Optional | Fullscreen surface is visible. Pause game audio/timers. Default is a no-op. |
| `onAdImpression` | Optional | Ad impression recorded. Fires after `onAdShown`, once the impression has been counted. Default is a no-op. |
| `onAdFailedToShow` | Optional | `show()` was rejected. Ad remains ready unless expired/destroyed. Default is a no-op. |
| `onAdClicked` | Optional | User tapped through. SDK opens click URL automatically. Default is a no-op. |
| `onAdDismissed` | Optional | Surface dismissed — terminal callback. Release the instance and pre-load the next one. Default is a no-op. |

#### `VelocityInterstitialAdRequest` / `VelocityInterstitialAd`

```swift
let adRequest = VelocityInterstitialAdRequest.Builder(adUnitId: String).build()

let interstitialAd = VelocityInterstitialAd(adRequest)

// Load
interstitialAd.load(delegate: VelocityInterstitialAdDelegate)

// Query state (safe from any thread)
var isReady: Bool { get }

// Show (main thread only)
@MainActor func show()

// Teardown (any thread, idempotent)
func destroy()
```

**`VelocityInterstitialAdRequest.Builder` parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `adUnitId` | ✅ | Ad unit identifier. Leading/trailing whitespace is trimmed. Blank value fails immediately with `invalidAdUnitId` (2011). |

**`VelocityInterstitialAd` properties and methods:**

| Symbol | Description |
|--------|-------------|
| `adRequest` | The request used to create this instance. |
| `isReady` | `true` when a creative is loaded, unexpired, and the instance is not showing or destroyed. Safe to read from any thread. |
| `load(delegate:)` | Starts loading. Exactly one of `onAdLoaded` / `onAdFailedToLoad` fires per call. Fails with `loadAlreadyInProgress` (2003), `adAlreadyLoaded` (2008), or `adDestroyed` (2010) for invalid calls. |
| `show()` | Presents the fullscreen surface. Must be called on the main thread. Rejections are delivered via `onAdFailedToShow`. |
| `destroy()` | Releases all resources and silences callbacks. Idempotent. Safe from any thread. |

---

#### `VelocityFullscreenAdDelegate`

Base delegate protocol shared by all fullscreen ad formats. Do not conform to this protocol directly — use `VelocityInterstitialAdDelegate` or `VelocityRewardedAdDelegate` instead.

```swift
@MainActor
public protocol VelocityFullscreenAdDelegate: AnyObject {
    func onAdLoaded(ad: any VelocityFullscreenAd)                                    // required
    func onAdFailedToLoad(ad: any VelocityFullscreenAd, error: VelocityAdsError)     // required
    func onAdShown(ad: any VelocityFullscreenAd)                                     // optional (default no-op)
    func onAdImpression(ad: any VelocityFullscreenAd)                                // optional (default no-op)
    func onAdFailedToShow(ad: any VelocityFullscreenAd, error: VelocityAdsError)     // optional (default no-op)
    func onAdClicked(ad: any VelocityFullscreenAd)                                   // optional (default no-op)
    func onAdDismissed(ad: any VelocityFullscreenAd)                                 // optional (default no-op)
}
```

All callbacks are delivered on the **main thread**. The protocol is `@MainActor`-annotated.

**Delegate hierarchy:**

```
VelocityFullscreenAdDelegate
├─ VelocityInterstitialAdDelegate   (ad parameter typed as VelocityInterstitialAd)
└─ VelocityRewardedAdDelegate       (ad parameter typed as VelocityRewardedAd; adds onUserRewarded)
```

---

#### `VelocityRewardedAdDelegate`

```swift
@MainActor
public protocol VelocityRewardedAdDelegate: VelocityFullscreenAdDelegate {
    func onUserRewarded(ad: any VelocityFullscreenAd)   // required
}
```

All methods are delivered on the **main thread**. The protocol is `@MainActor`-annotated.

| Method | Required | Description |
|--------|----------|-------------|
| `onAdLoaded` | ✅ | Ad loaded and ready. Call `show()` now or at a later break point. |
| `onAdFailedToLoad` | ✅ | Load failed. `error.code` identifies the reason. |
| `onUserRewarded` | ✅ | User completed the video — grant the in-app reward. Fires before `onAdDismissed`. Not fired if the user skips before completion. |
| `onAdShown` | Optional | Fullscreen surface is visible. Pause game audio/timers. Default is a no-op. |
| `onAdImpression` | Optional | Ad impression recorded. Fires after `onAdShown`. Default is a no-op. |
| `onAdFailedToShow` | Optional | `show()` was rejected. Ad remains ready unless expired/destroyed. Default is a no-op. |
| `onAdClicked` | Optional | User tapped through. SDK opens click URL automatically. Default is a no-op. |
| `onAdDismissed` | Optional | Surface dismissed — terminal callback. Release the instance and pre-load the next one. Default is a no-op. |

#### `VelocityRewardedAdRequest` / `VelocityRewardedAd`

```swift
let adRequest = VelocityRewardedAdRequest.Builder(adUnitId: String).build()

let rewardedAd = VelocityRewardedAd(adRequest)

// Load
rewardedAd.load(delegate: VelocityRewardedAdDelegate)

// Query state (safe from any thread)
var isReady: Bool { get }

// Show (main thread only)
@MainActor func show()

// Teardown (any thread, idempotent)
func destroy()
```

**`VelocityRewardedAdRequest.Builder` parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `adUnitId` | ✅ | Ad unit identifier. Leading/trailing whitespace is trimmed. Blank value fails immediately with `invalidAdUnitId` (2011). |

**`VelocityRewardedAd` properties and methods:**

| Symbol | Description |
|--------|-------------|
| `adRequest` | The request used to create this instance. |
| `isReady` | `true` when a creative is loaded, unexpired, and the instance is not showing or destroyed. Safe to read from any thread. |
| `load(delegate:)` | Starts loading. Exactly one of `onAdLoaded` / `onAdFailedToLoad` fires per call. |
| `show()` | Presents the fullscreen surface. Must be called on the main thread. Rejections are delivered via `onAdFailedToShow`. |
| `destroy()` | Releases all resources and silences callbacks. Idempotent. Safe from any thread. |

---

#### `VelocityBannerAdDelegate`

Standalone protocol — banners do not share the `VelocityFullscreenAdDelegate` hierarchy (there is no `show()` / dismiss lifecycle).

```swift
@MainActor
public protocol VelocityBannerAdDelegate: AnyObject {
    func onAdLoaded(ad: VelocityBannerAd)                                    // required
    func onAdFailedToLoad(ad: VelocityBannerAd, error: VelocityAdsError)     // required
    func onAdImpression(ad: VelocityBannerAd)                                // optional (default no-op)
    func onAdFailedToShow(ad: VelocityBannerAd, error: VelocityAdsError)     // optional (default no-op)
    func onAdClicked(ad: VelocityBannerAd)                                   // optional (default no-op)
}
```

All callbacks are delivered on the **main thread**. The protocol is `@MainActor`-annotated.

| Method | Required | Description |
|--------|----------|-------------|
| `onAdLoaded` | ✅ | Ad loaded and rendering in the banner view. `intrinsicContentSize` now reports the ad size. |
| `onAdFailedToLoad` | ✅ | Load failed. `error.code` identifies the reason. |
| `onAdImpression` | Optional | Viewability impression recorded (≥ 50 % of the banner visible on screen). Fires at most once per instance; impression tracking URLs fire at the same moment. Default is a no-op. |
| `onAdFailedToShow` | Optional | Rendering failed after a successful load (e.g. player crash or stall). Destroy the instance and load a new one. Default is a no-op. |
| `onAdClicked` | Optional | User tapped through. SDK opens click URL automatically. Default is a no-op. |

#### `VelocityBannerAdRequest` / `VelocityBannerAd` / `VelocityBannerAdView`

```swift
let adRequest = VelocityBannerAdRequest.Builder(adUnitId: String, adSize: VelocityBannerAdSize)
    .withAdditionalContext(String?)   // optional
    .build()

let bannerAd = VelocityBannerAd(adRequest)
let bannerView = VelocityBannerAdView()

// Load and render (main thread only)
@MainActor func load(bannerView: VelocityBannerAdView, delegate: VelocityBannerAdDelegate)

// Teardown (any thread, idempotent)
func destroy()

// SwiftUI size forwarding (main thread — call from updateUIView)
@MainActor func handleContainerSizeChange(_ newSize: CGSize)   // on VelocityBannerAdView
```

**`VelocityBannerAdRequest.Builder` parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `adUnitId` | ✅ | Ad unit identifier. Leading/trailing whitespace is trimmed. Blank value fails immediately with `invalidAdUnitId` (2011). |
| `adSize` | ✅ | The banner slot size — see `VelocityBannerAdSize` below. |
| `withAdditionalContext(_:)` | Optional | Free-form string providing extra context for ad targeting. `nil` and blank values are treated as absent. |

**`VelocityBannerAd` properties and methods:**

| Symbol | Description |
|--------|-------------|
| `adRequest` | The request used to create this instance. |
| `load(bannerView:delegate:)` | Starts loading and, on success, renders into `bannerView`. Exactly one of `onAdLoaded` / `onAdFailedToLoad` fires per call. Fails with `loadAlreadyInProgress` (2003), `adAlreadyLoaded` (2008), or `adDestroyed` (2010) for invalid calls. Must be called on the main thread. |
| `destroy()` | Cancels any in-flight load, removes rendered content from the banner view, and silences callbacks. Idempotent. Safe from any thread. |

**`VelocityBannerAdView`:**

A passive `UIView` container that you create, size, and place. `intrinsicContentSize` returns the bound ad size after load and `.zero` before. Size it with Auto Layout constraints or a fixed frame. In SwiftUI, forward frame changes with `handleContainerSizeChange(_:)` from `updateUIView(_:context:)`.

#### `VelocityBannerAdSize`

```swift
public struct VelocityBannerAdSize: Equatable, Sendable {
    public let width: CGFloat    // points
    public let height: CGFloat   // points

    public static let banner: VelocityBannerAdSize          // 320 × 50
    public static let mrec: VelocityBannerAdSize            // 300 × 250
    public static let leaderboard: VelocityBannerAdSize     // 728 × 90
    public static func adaptiveBanner(width: CGFloat) -> VelocityBannerAdSize
}
```

`adaptiveBanner(width:)` computes a height anchored to the 320:50 aspect ratio, clamped to [32, 90] pt.
