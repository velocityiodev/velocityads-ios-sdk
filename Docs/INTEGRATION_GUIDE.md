# Velocity Ads SDK Integration Guide

**Version:** 0.7.0
**Last Updated:** June 2026  
**Platform:** iOS 13.0+  
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
9. [Collapsing Large Ads](#collapsing-large-ads)
10. [Ad Theming and Customization](#ad-theming-and-customization)
11. [Regulations](#regulations)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)
14. [API Reference](#api-reference)

---

## Overview

Velocity Ads is an iOS SDK that provides AI-powered contextual advertising.

---

## Prerequisites

### System Requirements

- **Minimum iOS:** 13.0
- **Xcode:** 16.0+
- **Swift:** 5.5+

### Advertising Identifiers

The Velocity Ads SDK uses **IDFA** (Identifier for Advertisers) and **IDFV** (Identifier for Vendor) when available to improve ad performance and relevance. These identifiers enable:

- 🎯 **Better ad targeting** - More relevant ads for your users
- 📊 **Improved analytics** - Better campaign performance measurement
- 💰 **Higher revenue** - Increased eCPM through better targeting

On iOS, access to IDFA is controlled by **App Tracking Transparency (ATT)**. Your app must request tracking authorization when appropriate; the SDK uses the advertising identifier only when the user has granted permission. The SDK does not perform cross-app tracking; the host app controls ATT and the SDK uses identifiers for ad delivery and analytics within your app.

---

## Installation

The Velocity Ads SDK can be installed via **Swift Package Manager (SPM)** or **CocoaPods**.

> **Current version: `0.7.0`**  

### Swift Package Manager (SPM)

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:  
   **`https://github.com/velocityiodev/velocityads-ios-sdk`**
3. Set the version rule to **"Exact"** and enter **`0.7.0`**, then click **Add Package**.
4. Add the **VelocityAdsSDK** library to your app target.

The package uses a binary target hosted on GitHub Releases. Each release provides a pre-built XCFramework; Xcode resolves the correct asset automatically when you select a version.

---

### CocoaPods

1. Add the following to your `Podfile`:

```ruby
pod 'VelocityAdsSDK', '0.7.0'
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
- **`VelocityNativeAd`** — The ad object. Create one from a request and call `loadAd(delegate:)` to trigger loading. Ad properties (`title`, `description`, etc.) are populated when `onAdLoaded` is called.

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
        nativeAd.loadAd(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        guard let data = nativeAd.data else { return }

        // Ad properties are now available
        // Display ad manually
        titleLabel.text = data.title
        descriptionLabel.text = data.description
        ctaButton.setTitle(data.callToAction, for: .normal)

        // Load image (e.g. with URLSession or a library like SDWebImage)
        if let imageUrl = data.largeImageUrl ?? data.squareImageUrl {
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
}
```

> **Note:** `onAdImpression` and `onAdClicked` have default no-op implementations via a protocol extension, so you can omit them if you don't need impression/click tracking in your delegate implementation.

### Automatic Impression and Click Tracking

The SDK uses a **50% viewability threshold** for impression tracking: an impression fires once at least 50% of the registered ad view is visible on screen. The SDK fires the impression exactly once, and then stops polling.

For UIKit apps using manual rendering, call `registerViewForInteraction` after loading the ad to enable automatic impression and click tracking:

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let data = nativeAd.data else { return }

    // Set up your ad views...
    titleLabel.text = data.title
    descriptionLabel.text = data.description

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
- **Before `destroyAd()`** — unregister first if you are explicitly destroying the ad instance; `destroyAd()` itself is safe to call without it, but unregistering first is good practice.

```swift
// Example: tearing down an ad when a view controller disappears
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    nativeAd?.unregisterViewForInteraction()
}
```

> **Recycling containers:** In a `UITableView` or `UICollectionView`, call `unregisterViewForInteraction()` in `prepareForReuse` (or `didEndDisplayingCell`) so the outgoing ad is cleaned up before the cell is reused. See [Recycling Container Integration](#recycling-container-integration) for full patterns.

**For SwiftUI apps**, use the `.velocityAdTracking(_:)` modifier instead:

```swift
struct AdCardView: View {
    let nativeAd: VelocityNativeAd

    var body: some View {
        VStack {
            Text(nativeAd.data?.title ?? "")
            Text(nativeAd.data?.description ?? "")
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
nativeAd1.loadAd(delegate: self)

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
nativeAd2.loadAd(delegate: self)
```

**Note:** The `withConversationHistory` parameter accepts an array of dictionaries (`[[String: Any]]?`). Each dictionary should have `"role"` (`"user"` or `"assistant"`) and `"content"` (message text). Update it with the full conversation history for best targeting.

### Preliminary Text

When `.includePreliminaryText(true)` is set on the request, the server returns a short contextual sentence in `nativeAd.data?.preliminaryText`. Display it directly above the ad — outside the ad view's frame — so it does not affect the ad's layout or height.

```swift
// Request with preliminary text enabled
let adRequest = VelocityNativeAdRequest.Builder(adUnitId: "ad_unit_123")
    .withPrompt("Which running shoes are best for marathons?")
    .withAIResponse("For marathons, I recommend ...")
    .includePreliminaryText(true)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: self)
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

    // Render ad content...
    titleLabel.text = data.title
    descriptionLabel.text = data.description
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
Created → loadAd() → Loading → success → Loaded → destroyAd() → Destroyed (terminal)
                                ↓
                              failure (retry allowed)
```

- **Load once:** After a successful load, calling `loadAd()` again on the same instance returns `VelocityAdsErrorCode.adAlreadyLoaded` (`2008`). Create a new `VelocityNativeAd` instance for each ad placement.
- **Retry on failure:** If a load fails, you may call `loadAd()` again on the same instance.
- **Terminal after destroy:** After `destroyAd()`, the instance is inert. `loadAd()` returns `adAlreadyLoaded`; `createAdView()` / `createAdSwiftUIView()` return `nil`; `configureAdView()` / `registerViewForInteraction()` are no-ops.
- **`adRequest` remains readable** after destroy (it is a `let` constant), but **`data` is set to `nil`** by `destroyAd()`. The instance should not be used further.

---

## Loading Native Ad Views

The SDK can render ad views for you — no custom UI needed. To use this path, load with `VelocityNativeAdViewRequest` instead of the base `VelocityNativeAdRequest`. The view request adds two parameters:

- **`adViewSize`** (required) — tells the server which layout template to select (`.S`, `.M`, or `.L`).
- **`configuration`** (optional) — controls theming (colors, typography, dark mode). See [Ad Theming and Customization](#ad-theming-and-customization).

After a successful load, call `createAdView()` or `createAdSwiftUIView()` to get a self-contained view with built-in impression and click tracking.

### `VelocityNativeAdViewRequest`

Build the request using the fluent builder. Both `adUnitId` and `adViewSize` are required; all other parameters are optional and inherited from `VelocityNativeAdRequest`.

```swift
let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: "ad_unit_123", adViewSize: .M)
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
nativeAd.loadAd(delegate: self)
```

| Size | Constant | Height |
|------|----------|--------|
| Extra Small | `.XS` | 64 pt |
| Small | `.S` | 100 pt |
| Medium | `.M` | 158 pt |
| Large | `.L` | 280 pt |

> **Choosing a size:** Pick the size that best fits your layout. The server uses the size to select the right creative template; changing the size after load requires a new `VelocityNativeAd` instance.

### Creating Ad Views

After a successful `loadAd(delegate:)` call, create SDK-rendered views on demand. This separates the expensive network load from the cheap view creation — the key to efficient cell recycling.

Views return `nil` if the request was a plain `VelocityNativeAdRequest`, if `loadAd` has not yet succeeded, or if the instance has been destroyed via `destroyAd()`.

#### `createAdView() -> VelocityNativeAdView?`

Creates a pre-built UIKit ad view. Impression and click tracking are handled automatically inside the returned view.

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let adView = nativeAd.createAdView() else { return }
    adContainer.addSubview(adView)
    NSLayoutConstraint.activate([
        adView.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor),
        adView.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor),
        adView.topAnchor.constraint(equalTo: adContainer.topAnchor),
        adView.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor),
    ])
}
```

#### `createAdSwiftUIView() -> AnyView?`

Creates a pre-built SwiftUI ad view. No `UIViewRepresentable` bridging needed — embed it directly.

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    self.adView = nativeAd.createAdSwiftUIView()
}
```

**Return value:** Both `createAdView()` and `createAdSwiftUIView()` return `nil` if:
- The ad data has not been loaded yet (before `onAdLoaded`).
- The `adRequest` was a plain `VelocityNativeAdRequest` instead of `VelocityNativeAdViewRequest`.
- The instance has been destroyed via `destroyAd()`.

> **Note:** Publishers using the manual rendering path (`VelocityNativeAdRequest`) do not call `createAdView` or `createAdSwiftUIView`. Use `registerViewForInteraction(adView:clickableViews:)` instead to wire impression and click tracking.

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

Internally, `configureAdView` updates all displayed fields, resets the impression tracker when the ad identity changes, and re-wires the click URL. No `prepareForReuse` cleanup is needed — teardown is handled automatically.

---

### Pattern 1: Manual Rendering (UIKit Recycling Container)

Use `VelocityNativeAdRequest` to load ad data. The publisher builds custom UI from `nativeAd.data`. Pre-load ads before binding to cells. Call `registerViewForInteraction` in `cellForRowAt` and `unregisterViewForInteraction` in `prepareForReuse`.

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
        nativeAd.loadAd(delegate: self)
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
        currentAd?.unregisterViewForInteraction()
        currentAd = nativeAd
        titleLabel.text = nativeAd.data?.title
        ctaButton.setTitle(nativeAd.data?.callToAction, for: .normal)
        nativeAd.registerViewForInteraction(adView: contentView, clickableViews: [ctaButton])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentAd?.unregisterViewForInteraction()
        currentAd = nil
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
        ad.loadAd(delegate: self)
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
            Text(data?.title ?? "")
                .font(.headline)
            Text(data?.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
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

Use `VelocityNativeAdViewRequest` to load ad data. Pre-load ads before binding to cells. Create the `VelocityNativeAdView` once per cell with `createAdView()`; call `configureAdView` on reuse to swap the ad data without recreating the view hierarchy. The view is retained in the cell across `prepareForReuse`.

```swift
import UIKit
import VelocityAdsSDK

@MainActor
class FeedViewController: UIViewController, UITableViewDataSource, VelocityNativeAdDelegate {
    private var nativeAds: [UUID: VelocityNativeAd] = [:]

    private func loadAd(for messageId: UUID, prompt: String) {
        let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: adUnitId, adViewSize: .M)
            .withPrompt(prompt)
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        nativeAds[messageId] = nativeAd
        nativeAd.loadAd(delegate: self)
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
}
```

---

### Pattern 4: SDK-Rendered UIView (SwiftUI Lazy Container)

Use `VelocityNativeAdViewRequest` to load ad data. Cache the `VelocityNativeAdView` in `@State` so it is created once per `ForEach` identity. Wrap it in a publisher-written `UIViewRepresentable`. No `configureAdView` is needed — each ad identity keeps its own cached view.

Create the view in `onAppear` rather than in `init`. Swift eagerly evaluates `State(initialValue:)` arguments on every `body` re-evaluation, producing a throwaway `VelocityNativeAdView` on each re-render that overwrites the ad's internal `currentAdView` reference before being immediately discarded. The `onAppear` guard (`guard cachedAdView == nil`) ensures creation happens exactly once per `ForEach` identity.

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
                    .frame(height: adView.intrinsicContentSize.height)
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

    // iOS 16+: use sizeThatFits for automatic height
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

> **iOS 13–15 note:** `sizeThatFits` is iOS 16+. On older versions, provide an explicit `.frame(height:)` using `adView.intrinsicContentSize.height`.

---

### Pattern 5: SDK-Rendered SwiftUI (UIKit Recycling Container)

Use `VelocityNativeAdViewRequest` to load ad data. Call `createAdSwiftUIView()` to get an `AnyView` and host it inside the cell. The recommended hosting strategy depends on the minimum iOS version you support:

- **iOS 16+:** Use `UIHostingConfiguration` assigned to `cell.contentConfiguration`. This is Apple's purpose-built, lightweight API for SwiftUI content in `UITableViewCell` / `UICollectionViewCell`. No view-controller lifecycle, no manual Auto Layout — each recycle simply reassigns `contentConfiguration`.
- **iOS 13–15 fallback:** Retain a `UIHostingController<AnyView>` as a child view controller and replace `hostingController.rootView` on reuse.

```swift
import UIKit
import SwiftUI
import VelocityAdsSDK

@MainActor
class SwiftUIAdCell: UITableViewCell {
    static let reuseId = "SwiftUIAdCell"

    // iOS 13-15 fallback only
    private var hostingController: UIHostingController<AnyView>?
    private var hostingHeightConstraint: NSLayoutConstraint?

    func configure(nativeAd: VelocityNativeAd) {
        guard let swiftUIView = nativeAd.createAdSwiftUIView() else { return }
        let adHeight: CGFloat = (nativeAd.adRequest as? VelocityNativeAdViewRequest)?.adViewSize.heightPt ?? 100

        if #available(iOS 16.0, *) {
            contentConfiguration = UIHostingConfiguration {
                swiftUIView
            }
            .margins(.all, 16)
            .minSize(width: 0, height: adHeight)
        } else {
            if let hc = hostingController {
                hc.rootView = swiftUIView
                hostingHeightConstraint?.constant = adHeight
            } else {
                let hc = UIHostingController(rootView: swiftUIView)
                hc.view.backgroundColor = .clear
                hc.view.translatesAutoresizingMaskIntoConstraints = false
                hostingController = hc

                contentView.addSubview(hc.view)
                let p: CGFloat = 16
                let heightC = hc.view.heightAnchor.constraint(equalToConstant: adHeight)
                hostingHeightConstraint = heightC
                NSLayoutConstraint.activate([
                    hc.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: p),
                    hc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p),
                    hc.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
                    hc.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
                    heightC,
                ])
            }
        }
    }
    // prepareForReuse: nothing required —
    // iOS 16+: contentConfiguration reassignment handles teardown.
    // iOS 13-15: hostingController is retained; rootView is replaced in the next configure call.
}
```

> **Note:** Unlike the UIView recycling path (Pattern 3), there is no `configureAdView` equivalent for this path. Each `createAdSwiftUIView()` call creates a new internal `VelocityNativeAdView`, so the view is replaced entirely on every recycle. On iOS 16+, `UIHostingConfiguration` avoids the view-controller lifecycle overhead, reducing per-cell cost compared to the `UIHostingController` fallback. For performance-sensitive lists with high scroll velocity, prefer Pattern 3 (SDK UIView in UIKit recycling container). Pattern 5 is best suited when you need SwiftUI rendering inside a UIKit collection and the list size is moderate.

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
| `cellForRowAt` — first use | Populate UI from `nativeAd.data`, then `registerViewForInteraction(adView:clickableViews:)` | `createAdView()` → add to cell | `createAdSwiftUIView()` → assign `UIHostingConfiguration` (iOS 16+) or create `UIHostingController` → add to cell (iOS 13-15) |
| `cellForRowAt` — reused cell | Populate UI from `nativeAd.data`, then `registerViewForInteraction(adView:clickableViews:)` | `configureAdView(existingAdView)` | `createAdSwiftUIView()` → reassign `contentConfiguration` (iOS 16+) or replace `hostingController.rootView` (iOS 13-15) |
| `prepareForReuse` | `unregisterViewForInteraction()` | Nothing required | Nothing required |
| `didEndDisplaying` | `unregisterViewForInteraction()` (alternative to `prepareForReuse`) | Nothing required | Nothing required |

#### SwiftUI Lazy Containers (`LazyVStack` / `List` / etc.)

| Lifecycle Event | Pattern 2: Manual | Pattern 4: SDK UIView | Pattern 6: SDK SwiftUI |
|---|---|---|---|
| View appears | `.velocityAdTracking()` auto-registers via `didMoveToWindow` | `@State` preserves cached `VelocityNativeAdView` | `@State` preserves cached `AnyView` |
| View disappears | `.velocityAdTracking()` auto-unregisters via `willMove(toWindow: nil)` | Automatic via `didMoveToWindow` | Automatic via `didMoveToWindow` |
| View identity changes | SwiftUI recreates the view; modifier wires the new ad | `onAppear` fires for the new identity; `guard == nil` creates a new view | `onAppear` fires for the new identity; `guard == nil` creates a new view |

> **When to call `prepareForReuse` vs `unregisterViewForInteraction`:**
> `prepareForReuse` is called by UIKit just before a cell is dequeued and handed to the next `cellForRowAt` call. For **manual rendering** (Pattern 1), call `unregisterViewForInteraction()` there to stop the visibility timer and remove gesture recognizers from the old ad. For **SDK-rendered views** (Patterns 3 and 5), teardown is handled internally — no publisher action needed in `prepareForReuse`.

---

## Collapsing Large Ads

Large (`L`) ad views support an expand/collapse animation. When collapsed, the ad card shrinks to Medium height (158pt) and displays a "See more" bar with a gradient overlay at the bottom. The user can tap "See more" to expand the ad back to full height (280pt).

This is useful when you want to reduce the visual footprint of an ad after it has been shown (e.g. after the user scrolls past it).

### Usage

Call `collapse()` on the `VelocityNativeAd` instance after the ad view has been created and attached:

```swift
nativeAd.loadAd(delegate: self)

// In VelocityNativeAdDelegate.onAdLoaded:
func onAdLoaded(nativeAd: VelocityNativeAd) {
    guard let adView = nativeAd.createAdView() else { return }
    container.addSubview(adView)

    // Later, when you want to collapse (e.g. after the user scrolls past):
    nativeAd.collapse()
}
```

You can also call `collapse()` directly on the `VelocityNativeAdView`:

```swift
guard let adView = nativeAd.createAdView() else { return }
container.addSubview(adView)

// Later:
adView.collapse()
```

> **Threading:** Both `VelocityNativeAd.collapse()` and `VelocityNativeAdView.collapse()` must be called on the main thread. `VelocityNativeAd.collapse()` is annotated `@MainActor`. Calling it from `onAdLoaded` or a UIKit action handler (e.g. an `@objc` button tap) is safe because those already run on the main thread. From a non-isolated context, dispatch via `DispatchQueue.main.async { nativeAd.collapse() }`.

### Behavior

| Action | Result |
|--------|--------|
| `nativeAd.collapse()` or `adView.collapse()` | Animates the card from full height (280pt) to compact height (158pt) with a fade-in "See more" bar |
| User taps "See more" | Animates back to full height; the publisher cannot programmatically expand — only the user can |
| Calling `collapse()` on a Small or Medium ad | No-op (logs a warning) |
| Calling `collapse()` before `createAdView()` / `configureAdView(_:)` | No-op (logs a warning) |

### RecyclerView / UITableView Support

The collapse state is persisted on the `VelocityNativeAd` instance. When a `UITableView` or `UICollectionView` recycles and rebinds the view via `configureAdView(_:)`, the view is restored to the correct collapsed or expanded state without animation. This means:

- If the user expanded the ad, scrolled away, and scrolled back — the ad remains expanded.
- If the publisher collapsed the ad, the user scrolled away, and scrolled back — the ad remains collapsed.

### Responding to Height Changes

When the ad collapses or expands, the SDK fires a callback so you can animate your container's height in sync with the card's internal animation. Two equivalent observation points are provided — choose the one that fits your rendering path.

#### UIKit (and SwiftUI publishers who hold the `VelocityNativeAdView`)

If you have a direct reference to a `VelocityNativeAdView` — i.e. you called `createAdView()` and kept the result, or you're inside a `UITableViewCell` that owns the view — assign `view.onCollapseStateChanged`:

```swift
adView.onCollapseStateChanged = { [weak self] isCollapsed in
    guard let self else { return }
    let newHeight = isCollapsed
        ? VelocityNativeAdViewSize.largeCollapsedHeightPt
        : VelocityNativeAdViewSize.largeExpandedHeightPt
    UIView.animate(withDuration: 0.15) {
        self.adViewHeightConstraint?.constant = newHeight
        self.containerHeightConstraint?.constant = newHeight
        self.view.layoutIfNeeded()
    }
}
```

#### SwiftUI (when you called `createAdSwiftUIView()`)

`createAdSwiftUIView()` returns an opaque `AnyView`, so you don't have a `VelocityNativeAdView` reference to attach a callback to. In that case, observe the same state change on the `VelocityNativeAd` instance you already hold:

```swift
@State private var adViewHeight: CGFloat = VelocityNativeAdViewSize.largeExpandedHeightPt

// inside body:
adSwiftUIView
    .frame(height: adViewHeight)
    .onAppear {
        nativeAd.onCollapseStateChanged = { isCollapsed in
            withAnimation(.easeInOut(duration: 0.15)) {
                adViewHeight = isCollapsed
                    ? VelocityNativeAdViewSize.largeCollapsedHeightPt
                    : VelocityNativeAdViewSize.largeExpandedHeightPt
            }
        }
    }
```

> **Avoid retain cycles.** The closure is held strongly by `nativeAd` until replaced or `destroyAd()` is called. Do not capture `nativeAd` or any object that holds a strong reference back to `nativeAd` (such as a `VelocityNativeAdView` returned by `createAdView()`) inside the closure — doing so creates a cycle that leaks both objects. Capture only lightweight values such as SwiftUI `@State` bindings and height constants, as shown above.

Both callbacks fire on the main thread immediately before the card's internal height animation begins, so your constraint or `@State` update animates in parallel with the card. They are equivalent in behavior — pick whichever matches your call site. Setting both is supported but unnecessary.

---

## Ad Theming and Customization

When using `VelocityNativeAdViewRequest`, you can fully customize the ad card appearance via `AdViewConfiguration`.


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

let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: "ad_unit_123", adViewSize: .M)
    .withPrompt("...")
    .withAdViewConfiguration(config)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: self)
```

#### Available Color Tokens

| Token | Description |
|-------|-------------|
| `cardBackground` | Ad card surface color |
| `titleText` | Title text color |
| `descriptionText` | Description text color |
| `brandText` | Advertiser brand name color |
| `brandIconBorder` | Advertiser brand icon border color |
| `cardBorder` | Ad card outer border color |
| `sponsoredLabelText` | "Sponsored" label text color |
| `sponsoredBadgeBackground` | Badge background (e.g. "ad" pill) |
| `sponsoredBadgeText` | Badge text color |
| `ctaBackground` | CTA button background |
| `ctaText` | CTA button text color |
| `ctaBorder` | CTA button border color |
| `chevronIconTint` | Chevron icon tint |

### Custom Typography

```swift
let config = AdViewConfiguration(
    typography: AdTypography.Builder(selectedSize: .M)
        .title { $0.copy(fontSize: 18, fontWeight: .bold) }
        .description { $0.copy(fontSize: 14) }
        .ctaButton { $0.copy(fontWeight: .semibold) }
        .build()
)
```

#### Available Typography Tokens

| Token | Description |
|-------|-------------|
| `brandName` | Advertiser brand name |
| `sponsoredLabel` | "Sponsored" label |
| `sponsoredBadgeText` | "ad" badge label |
| `title` | Ad title |
| `description` | Ad body text |
| `ctaButton` | CTA button text |

### Dark Theme Override

By default the SDK follows the system dark mode setting. Override it explicitly:

```swift
let config = AdViewConfiguration(
    darkTheme: false      // Force light mode
    // darkTheme: true    // Force dark mode
    // darkTheme: nil     // Follow system (default)
)
```

### Combining All Options

```swift
let config = AdViewConfiguration(
    colorScheme: AdColorScheme.Builder()
        .light { $0.copy(ctaBackground: UIColor(red: 0.38, green: 0.0, blue: 0.93, alpha: 1.0)) }
        .build(),
    typography: AdTypography.Builder(selectedSize: .M)
        .title { $0.copy(fontSize: 18) }
        .build(),
    darkTheme: nil
)

let adRequest = VelocityNativeAdViewRequest.Builder(adUnitId: "ad_unit_123", adViewSize: .M)
    .withPrompt("Best running shoes")
    .withAdViewConfiguration(config)
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: self)
```

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

**Problem:** Calling `loadNativeAd` before `initSDK`, or loading ads before initialization has completed.


**Solution 1 — Use VelocityAdsInitDelegate:** 
Initialize at startup and only load ads after initialization succeeds. This avoids calling `loadNativeAd` before the SDK is ready.

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
nativeAd.loadAd(delegate: self)
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
        retryAttempt = 0
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

#### 3. No Ads Returned

**Possible causes:**
- No ads available for the given context
- Network issues
- Ad unit not configured

**Solution:** Handle `onAdFailedToLoad` gracefully (e.g. hide ad space or show fallback). The SDK continues to function even when no ads are available.

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

✅ **DO:**
- Provide meaningful context (prompt, ai response, conversation history)
- Handle errors gracefully (e.g. hide ad view or show fallback)
- Track impressions and clicks for analytics
- Use dimensions in **points** that match your ad container

❌ **DON'T:**
- Use empty or placeholder context when you have real content
- Block the main thread
- Ignore error callbacks
- Use incorrect or zero dimensions

### 3. Memory Management

✅ **DO:**
- Clear or release ad-related views when they are no longer visible
- Use weak references where appropriate (e.g. in delegates)
- Clean up in `deinit` or when the view controller is dismissed

❌ **DON'T:**
- Keep strong references to ad views after the screen is dismissed

### 4. Error Handling

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

Supplies a `UIViewController` root that the SDK uses to present in-app StoreKit sheets (`SKStoreProductViewController`) when a user taps an ad.

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
nativeAd.loadAd(delegate: VelocityNativeAdDelegate)
```

**`VelocityNativeAdRequest` builder parameters:**
- `adUnitId` - Ad unit identifier (required)
- `prompt` - User's prompt (optional, but recommended for context)
- `aiResponse` - AI-generated response content (optional, but recommended for targeting)
- `conversationHistory` - Conversation history for ad targeting — array of `["role": "user"/"assistant", "content": "..."]` dictionaries (optional)
- `additionalContext` - Extra context string to improve ad relevance (optional)
- `adUnitId` - Ad unit identifier (required)
- `includePreliminaryText` - When `true`, requests the server to generate a short contextual snippet ("preliminary text") that could be displayed above the ad creative. Defaults to `false`. (optional)

**`VelocityNativeAd` properties (available after `onAdLoaded`):**

Ad creative data is accessed via `nativeAd.data` (type `NativeAd?`, non-nil after a successful load):

- `nativeAd.data?.adId` (`String`) - Unique ad identifier
- `nativeAd.data?.title` (`String`) - Ad title/headline
- `nativeAd.data?.description` (`String`) - Ad body text
- `nativeAd.data?.callToAction` (`String`) - CTA button text (e.g., "Learn More")
- `nativeAd.data?.advertiserName` (`String`) - Advertiser/brand name
- `nativeAd.data?.sponsoredLabel` (`String`) - Sponsorship label (e.g., "Sponsored")
- `nativeAd.data?.badgeLabel` (`String`) - Badge text (e.g., "ad")
- `nativeAd.data?.advertiserIconUrl` (`String`) - Advertiser logo/icon URL
- `nativeAd.data?.largeImageUrl` (`String?`) - Landscape hero image URL (optional). Resolved at the default 1920×640 size. For manual rendering at a specific size, call `nativeAd.data?.getLargeImageUrl(width:height:)` to obtain a URL sized to your image view's pixel dimensions.
- `nativeAd.data?.getLargeImageUrl(width:height:)` (`String?`) - Returns the landscape hero image URL with dimension placeholders substituted for the supplied pixel values. Use this when manually rendering the image at a known size (e.g. after a `UIImageView` has been laid out) to request a Cloudinary-optimised resolution. When `width` or `height` is ≤ 0 the default 1920×640 dimensions are used.
- `nativeAd.data?.squareImageUrl` (`String?`) - Square (1:1) image URL (optional)
- `nativeAd.data?.clickUrl` (`String`) - Destination URL when ad is clicked
- `nativeAd.data?.impressionUrl` (`String`) - URL to track ad impressions
- `nativeAd.data?.preliminaryText` (`String?`) - Short server-generated contextual text intended to be displayed between the AI response and the ad creative. (optional)

#### `VelocityNativeAdViewRequest`

Extends `VelocityNativeAdRequest` with size and theming for SDK-rendered ad views. Required to use `createAdView()` and `createAdSwiftUIView()`. Both `adUnitId` and `adViewSize` are required; the size is sent to the server at load time so it can select the correct template.

```swift
VelocityNativeAdViewRequest.Builder(adUnitId: String, adViewSize: VelocityNativeAdViewSize)
    .withPrompt(_ prompt: String?)                           // Optional: Provide for context
    .withAIResponse(_ aiResponse: String?)                   // Optional: Provide for better targeting
    .withConversationHistory(_ history: [[String: Any]]?)    // Optional: Previous conversation
    .withAdditionalContext(_ context: String?)               // Optional: Extra context
    .includePreliminaryText(_ include: Bool)                 // Optional: Request preliminary text
    .withAdViewConfiguration(_ config: AdViewConfiguration)  // Optional: See Ad Theming
    .build() -> VelocityNativeAdViewRequest
```

#### `VelocityNativeAd` — View Lifecycle Methods

```swift
// Create SDK-rendered views (requires VelocityNativeAdViewRequest and a successful load)
@MainActor nativeAd.createAdView() -> VelocityNativeAdView?
@MainActor nativeAd.createAdSwiftUIView() -> AnyView?

// Reconfigure an existing SDK-rendered view for cell recycling
@MainActor nativeAd.configureAdView(_ adView: VelocityNativeAdView)

// Collapse the Large ad card to compact height (no-op for Small/Medium)
@MainActor nativeAd.collapse()

// Manual rendering interaction tracking
@MainActor nativeAd.registerViewForInteraction(adView: UIView, clickableViews: [UIView])
@MainActor nativeAd.unregisterViewForInteraction()

// Teardown (terminal — instance cannot be reloaded after this call)
@MainActor nativeAd.destroyAd()
```

> **Note:** `createAdView()`, `createAdSwiftUIView()`, `configureAdView(_:)`, `collapse()`, `registerViewForInteraction(adView:clickableViews:)`, `unregisterViewForInteraction()`, and `destroyAd()` are annotated `@MainActor`. Calling them from a delegate callback is safe (delegate callbacks are already delivered on the main thread). From a non-isolated context, wrap the call in `DispatchQueue.main.async { }` or `await MainActor.run { }`.

#### `VelocityNativeAd` — Interaction Tracking

```swift
// Manual rendering: register impression and click tracking
@MainActor nativeAd.registerViewForInteraction(adView: UIView, clickableViews: [UIView])
@MainActor nativeAd.unregisterViewForInteraction()
```

> **Note:** `registerViewForInteraction(adView:clickableViews:)` and `unregisterViewForInteraction()` are annotated `@MainActor`. Calling them from a delegate callback is safe (delegate callbacks are already delivered on the main thread). From a non-isolated context, wrap the call in `DispatchQueue.main.async { }` or `await MainActor.run { }`.

#### `VelocityNativeAdView.collapse()`

```swift
func collapse()
```

Collapses this ad view to a compact preview state with animation, revealing a "See more" bar at the bottom. The user can tap "See more" to restore the full ad.

Only valid for Large (`L`) ad views. Calling this on a Small or Medium view logs a warning and does nothing. If the view is already collapsed, the call is ignored.

Must be called on the main thread. If called from a background thread, the collapse is dispatched asynchronously to the main thread.

Equivalent to calling `VelocityNativeAd.collapse()` on the ad instance — use whichever reference is more convenient.

### Models

#### `NativeAd` (ad creative data)

Accessed via `VelocityNativeAd.data` after a successful load with `VelocityNativeAdDelegate`.

| Field | Type | Description |
|-------|------|-------------|
| `adId` | `String` | Unique ad load identifier |
| `title` | `String` | Ad headline |
| `description` | `String` | Ad body text |
| `callToAction` | `String` | CTA button text (e.g. "Learn More") |
| `advertiserName` | `String` | Advertiser/brand name |
| `sponsoredLabel` | `String` | Sponsorship label (e.g. "Sponsored") |
| `badgeLabel` | `String` | Badge text (e.g. "ad") |
| `advertiserIconUrl` | `String` | Advertiser logo/icon URL |
| `largeImageUrl` | `String?` | Main (landscape) ad image URL resolved at the default 1920×640 size (optional). Use `getLargeImageUrl(width:height:)` to request a size-optimised URL for your image view. |
| `squareImageUrl` | `String?` | Square ad image URL (optional) |
| `clickUrl` | `String` | URL opened on ad click |
| `impressionUrl` | `String` | Impression tracking URL |
| `preliminaryText` | `String?` | Short server-generated contextual text to display above the ad (optional — requires `includePreliminaryText(true)` on the request) |

#### `VelocityNativeAdViewSize`

```swift
public enum VelocityNativeAdViewSize {
    case S  // Small — 50pt height
    case M  // Medium — 158pt height
    case L  // Large — 280pt height
}
```

Use `VelocityNativeAdViewSize.largeExpandedHeightPt` and `VelocityNativeAdViewSize.largeCollapsedHeightPt` to size external containers around a collapsible Large ad without hard-coding numbers:

| Constant | Value | Description |
|----------|-------|-------------|
| `largeExpandedHeightPt` | 280 pt | Height of a Large ad card in its full expanded state |
| `largeCollapsedHeightPt` | 158 pt | Height of a Large ad card in its collapsed preview state |

#### `AdViewConfiguration`

```swift
public struct AdViewConfiguration {
    public var colorScheme: AdColorScheme?   // nil = SDK default
    public var typography: AdTypography?     // nil = SDK default
    public var darkTheme: Bool?              // nil = follow system

    public init(
        colorScheme: AdColorScheme? = nil,
        typography: AdTypography? = nil,
        darkTheme: Bool? = nil
    )
}
```

#### `AdColorScheme`

```swift
public struct AdColorScheme {
    public let light: AdColors
    public let dark: AdColors

    public init(light: AdColors = .light, dark: AdColors = .dark)

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

```swift
public struct AdColors {
    public let cardBackground: UIColor
    public let sponsoredLabelText: UIColor
    public let titleText: UIColor
    public let descriptionText: UIColor
    public let brandText: UIColor
    public let sponsoredBadgeBackground: UIColor
    public let sponsoredBadgeText: UIColor
    public let ctaBackground: UIColor
    public let ctaText: UIColor
    public let ctaBorder: UIColor
    public let chevronIconTint: UIColor
    public let brandIconBorder: UIColor
    public let cardBorder: UIColor

    // Returns a copy with only the specified tokens replaced:
    public func copy(
        cardBackground: UIColor? = nil,
        sponsoredLabelText: UIColor? = nil,
        titleText: UIColor? = nil,
        descriptionText: UIColor? = nil,
        brandText: UIColor? = nil,
        sponsoredBadgeBackground: UIColor? = nil,
        sponsoredBadgeText: UIColor? = nil,
        ctaBackground: UIColor? = nil,
        ctaText: UIColor? = nil,
        ctaBorder: UIColor? = nil,
        chevronIconTint: UIColor? = nil,
        brandIconBorder: UIColor? = nil,
        cardBorder: UIColor? = nil
    ) -> AdColors

    public static let light: AdColors  // SDK default light palette
    public static let dark: AdColors   // SDK default dark palette
}
```

#### `AdTypography`

```swift
public struct AdTypography {
    public final class Builder {
        // Seeds from SDK defaults for the given size:
        public init(selectedSize: VelocityNativeAdViewSize)

        // Each block receives the current default FontStyle, return a modified copy:
        @discardableResult public func brandName(_ block: (FontStyle) -> FontStyle) -> Builder
        @discardableResult public func sponsoredLabel(_ block: (FontStyle) -> FontStyle) -> Builder
        @discardableResult public func sponsoredBadgeText(_ block: (FontStyle) -> FontStyle) -> Builder
        @discardableResult public func title(_ block: (FontStyle) -> FontStyle) -> Builder
        @discardableResult public func description(_ block: (FontStyle) -> FontStyle) -> Builder
        @discardableResult public func ctaButton(_ block: (FontStyle) -> FontStyle) -> Builder

        public func build() -> AdTypography
    }
}

public struct FontStyle {
    public let fontSize: CGFloat
    public let fontWeight: UIFont.Weight

    public init(fontSize: CGFloat, fontWeight: UIFont.Weight = .regular)

    public func copy(fontSize: CGFloat? = nil, fontWeight: UIFont.Weight? = nil) -> FontStyle
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
  - `VelocityAdsErrorCode.sdkNotInitialized` (`2001`) — `loadAd` called before `initSDK`
  - `VelocityAdsErrorCode.sdkInitializationInProgress` (`2002`) — `loadAd` called while initialization is still in progress
  - `VelocityAdsErrorCode.loadAlreadyInProgress` (`2003`) — `loadAd` called on an ad instance that is already loading
  - `VelocityAdsErrorCode.loadServiceUnavailable` (`2004`) — Internal load service is not available
  - `VelocityAdsErrorCode.invalidAdResponse` (`2005`) — Ad response is missing required data
  - `VelocityAdsErrorCode.noFill` (`2006`) — No ad available for the given context
  - `VelocityAdsErrorCode.internalError` (`2007`) — Unexpected internal SDK error
  - `VelocityAdsErrorCode.adAlreadyLoaded` (`2008`) — `loadAd` called on an instance that has already loaded successfully. Create a new `VelocityNativeAd` for a new ad placement.
  - `VelocityAdsErrorCode.waterfallLoadFailed` (`2009`) — Waterfall load failed
  - `VelocityAdsErrorCode.adDestroyed` (`2010`) — `loadAd` called on a destroyed instance. Create a new `VelocityNativeAd` for a new ad placement.
  - `VelocityAdsErrorCode.invalidAdUnitId` (`2011`) — `adUnitId` is empty or blank

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
protocol VelocityNativeAdDelegate: AnyObject {
    func onAdLoaded(nativeAd: VelocityNativeAd)
    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError)
    func onAdImpression(nativeAd: VelocityNativeAd)
    func onAdClicked(nativeAd: VelocityNativeAd)
}
```

| Method | Description |
|--------|-------------|
| `onAdLoaded` | Main thread. Ad data is loaded. Call `createAdView()` or `createAdSwiftUIView()` for SDK-rendered views, or read `nativeAd.data` for manual rendering. |
| `onAdFailedToLoad` | Main thread. Ad failed to load. |
| `onAdImpression` | Fires once when ≥ 50 % of the ad view is visible on screen. Default implementation is a no-op. |
| `onAdClicked` | User tapped the ad (SDK handles opening the click URL). Default implementation is a no-op. |
