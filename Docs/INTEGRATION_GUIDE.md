# Velocity Ads SDK Integration Guide

**Version:** 0.2.0  
**Last Updated:** March 2026  
**Platform:** iOS 13.0+  
**Language:** Swift 5.5+

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [SDK Initialization](#sdk-initialization)
5. [Loading Native Ads](#loading-native-ads)
6. [Integration Examples](#integration-examples)
7. [Troubleshooting](#troubleshooting)
8. [Regulations](#regulations)
9. [Best Practices](#best-practices)
10. [API Reference](#api-reference)

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

### Swift Package Manager (SPM)

The Velocity Ads SDK is distributed via **Swift Package Manager**.

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:  
   **`https://github.com/velocityiodev/velocityads-ios-sdk`**
3. Choose the version rule (e.g. "Up to Next Major" starting from `0.2.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

The package uses a binary target hosted on GitHub Releases. Each release (e.g. `0.2.0`) provides a pre-built XCFramework; Xcode resolves the correct asset automatically when you select a version.

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

For best performance, call `VelocityAds.setUserId(_:)` before `VelocityAds.initSDK(...)` when a user identifier is available.

**Important:**
- ⚠️ Initialize once during app startup
- ⚠️ Must be called before loading any ads

## Loading Native Ads

The SDK provides a method for loading native ads:

- **`VelocityNativeAdRequest`** — Immutable request object built via a fluent builder. Holds all targeting context.
- **`VelocityNativeAd`** — The ad object. Create one from a request and call `loadAd(delegate:)` to trigger loading. Ad properties (`title`, `description`, etc.) are populated when `onAdLoaded` is called.

```swift
// 1. Build the request
let adRequest = VelocityNativeAdRequest.Builder()
    .withPrompt("What's the weather today?")              // Optional
    .withAIResponse("The weather is sunny with 72°F...")  // Optional: improves targeting
    .withConversationHistory(nil)                         // Optional
    .withAdditionalContext(nil)                           // Optional
    .withAdUnitId("ad_unit_123")                          // Optional
    .build()

// 2. Create the ad object and load
let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: self)

// VelocityNativeAdDelegate implementation
func onAdLoaded(nativeAd: VelocityNativeAd) {
    // Ad properties are now available
    // Display ad manually
    titleLabel.text = nativeAd.title
    descriptionLabel.text = nativeAd.description
    ctaButton.setTitle(nativeAd.callToAction, for: .normal)

    // Load image (e.g. with URLSession or a library like SDWebImage)
    loadImage(from: nativeAd.imageUrl, into: adImageView)

    // Handle click
    ctaButton.addAction(UIAction { [weak self] _ in
        if let url = URL(string: nativeAd.clickUrl) {
            UIApplication.shared.open(url)
        }
    }, for: .touchUpInside)

    // Track impression
    trackImpression(nativeAd.impressionUrl)
}

func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
    print("Failed to load ad: \(error)")
}

func onAdImpression(nativeAd: VelocityNativeAd) {}

func onAdClicked(nativeAd: VelocityNativeAd) {}
```

### Conversation History

For better ad targeting in chat applications, you can provide conversation history:

```swift
// First call — no conversation history
let adRequest1 = VelocityNativeAdRequest.Builder()
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

let adRequest2 = VelocityNativeAdRequest.Builder()
    .withPrompt("What about tomorrow?")            // Optional: provide for context
    .withAIResponse("Tomorrow will be cloudy...")  // Optional: provide AI response for better targeting
    .withConversationHistory(conversationHistory)  // Previous conversation
    .build()
let nativeAd2 = VelocityNativeAd(adRequest2)
nativeAd2.loadAd(delegate: self)
```

**Note:** The `withConversationHistory` parameter accepts an array of dictionaries (`[[String: Any]]?`). Each dictionary should have `"role"` (`"user"` or `"assistant"`) and `"content"` (message text). Update it with the full conversation history for best targeting.


---

## Integration Examples

### Example 1: Chat Application

```swift
import UIKit
import VelocityAdsSDK

class ChatViewController: UIViewController, VelocityNativeAdDelegate {
    private var conversationHistory: [[String: Any]] = []

    private func onUserMessage(_ userMessage: String) {
        // Get AI response
        getAIResponse(userMessage) { [weak self] aiResponse in
            guard let self = self else { return }
            // Display AI response
            self.displayMessage(aiResponse)

            // Load contextual ad with conversation history
            self.loadContextualAd(prompt: userMessage, aiResponse: aiResponse)

            // Add to conversation history after successful ad load
            self.conversationHistory.append(["role": "user", "content": userMessage])
            self.conversationHistory.append(["role": "assistant", "content": aiResponse])
        }
    }

    private func loadContextualAd(prompt: String, aiResponse: String?) {
        // Pass conversation history (empty on first call)
        let historyToPass = conversationHistory.isEmpty ? nil : conversationHistory

        let adRequest = VelocityNativeAdRequest.Builder()
            .withPrompt(prompt)
            .withAIResponse(aiResponse)
            .withConversationHistory(historyToPass) // Optional conversation history
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        nativeAd.loadAd(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        // Display ad manually using custom UI
        displayAdManually(nativeAd)
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        // Continue without ad
        print("Ad load failed: \(error)")
    }

    func onAdImpression(nativeAd: VelocityNativeAd) {}

    func onAdClicked(nativeAd: VelocityNativeAd) {}
}
```

### Example 2: Table View / Collection View Integration

```swift
class AdTableViewCell: UITableViewCell {
    static let reuseId = "AdCell"
    private let containerView = UIView()
    private var adDelegate: AdCellDelegate?

    func configure(prompt: String, aiResponse: String? = nil) {
        containerView.subviews.forEach { $0.removeFromSuperview() }

        let adRequest = VelocityNativeAdRequest.Builder()
            .withPrompt(prompt)
            .withAIResponse(aiResponse)
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        // Retain the delegate so it is alive when the callback fires
        adDelegate = AdCellDelegate(containerView: containerView, cell: self)
        nativeAd.loadAd(delegate: adDelegate!)
    }
}

// Use a delegate object that holds the container; ensure it is retained until the callback
private class AdCellDelegate: VelocityNativeAdDelegate {
    weak var containerView: UIView?
    weak var cell: UITableViewCell?

    init(containerView: UIView, cell: UITableViewCell) {
        self.containerView = containerView
        self.cell = cell
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        guard let containerView = containerView else { return }
        // Build and add ad UI to containerView
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        // Hide ad container or show placeholder
        cell?.contentView.isHidden = true
    }

    func onAdImpression(nativeAd: VelocityNativeAd) {}

    func onAdClicked(nativeAd: VelocityNativeAd) {}
}
```

### Example 3: Article Reader

```swift
class ArticleViewController: UIViewController, VelocityNativeAdDelegate {

    private func loadArticle(_ article: Article) {
        // Display article content
        titleLabel.text = article.title
        contentLabel.text = article.content

        let adRequest = VelocityNativeAdRequest.Builder()
            .withPrompt(article.title)        // Optional
            .withAIResponse(article.content)  // Optional
            .build()

        let nativeAd = VelocityNativeAd(adRequest)
        nativeAd.loadAd(delegate: self)
    }

    func onAdLoaded(nativeAd: VelocityNativeAd) {
        // Display ad manually using custom UI
        displayAdManually(nativeAd)

        // Insert ad after first paragraph
        // (ad view would be inserted at position 1)
    }

    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {
        print("Ad load failed: \(error)")
    }

    func onAdImpression(nativeAd: VelocityNativeAd) {}

    func onAdClicked(nativeAd: VelocityNativeAd) {}
}
```

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

let adRequest = VelocityNativeAdRequest.Builder()
    .withPrompt(prompt)
    .withAIResponse(aiResponse)
    .withConversationHistory(conversationHistory)
    .withAdditionalContext(additionalContext)
    .withAdUnitId(adUnitId)
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

#### 2. Ads Not Loading

**Checklist:**
- ✅ SDK initialized at app startup (AppDelegate or App init)
- ✅ Network connectivity available
- ✅ Debug mode enabled to see logs

**Enable Debug Mode:**
```swift
let initRequest = VelocityAdsInitRequest.Builder("YOUR_APPLICATION_KEY")
    .withDebug(true)
    .build()
VelocityAds.initSDK(initRequest, delegate: MyInitDelegate())
```

#### 3. Memory / Lifecycle

**Problem:** Using a callback that is deallocated before the callback runs (e.g. a cell that is reused).

**Solution:** Retain the callback (e.g. in a dedicated object or via the view controller) until `onSuccess` or `onError` is called. Avoid using `self` from a short-lived object (e.g. table view cell) as the callback without retaining it.

#### 4. No Ads Returned

**Possible causes:**
- No ads available for the given context
- Network issues
- Ad unit not configured

**Solution:** Handle `onError` gracefully (e.g. hide ad space or show fallback). The SDK continues to function even when no ads are available.

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

## Best Practices

### 1. Initialization

✅ **DO:**
- Initialize in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or in your `@main` App's `init()`
- Enable debug mode when needed for troubleshooting (publisher's choice)
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
- `request` - Initialization request object containing required `appKey` and optional `debug`
- `delegate` - Initialization delegate (required)

#### `VelocityNativeAdRequest` / `VelocityNativeAd`

```swift
let adRequest = VelocityNativeAdRequest.Builder()
    .withPrompt(_ prompt: String?)
    .withAIResponse(_ aiResponse: String?)
    .withConversationHistory(_ history: [[String: Any]]?)
    .withAdditionalContext(_ context: String?)
    .withAdUnitId(_ adUnitId: String?)
    .build() -> VelocityNativeAdRequest

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: VelocityNativeAdDelegate)
```

**`VelocityNativeAdRequest` builder parameters:**
- `prompt` - User's prompt (optional, but recommended for context)
- `aiResponse` - AI-generated response content (optional, but recommended for targeting)
- `conversationHistory` - Conversation history for ad targeting — array of `["role": "user"/"assistant", "content": "..."]` dictionaries (optional)
- `additionalContext` - Extra context string to improve ad relevance (optional)
- `adUnitId` - Ad unit identifier (optional)

**`VelocityNativeAd` properties (available after `onAdLoaded`):**
- `adId` (`String`) - Unique ad identifier
- `title` (`String`) - Ad title/headline
- `description` (`String`) - Ad body text
- `callToAction` (`String`) - CTA button text (e.g., "Learn More")
- `sponsoredBy` (`String`) - Advertiser/sponsor name
- `imageUrl` (`String`) - Ad image URL
- `clickUrl` (`String`) - Destination URL when ad is clicked
- `impressionUrl` (`String`) - URL to track ad impressions

### Models

#### `VelocityAdsInitRequest`

```swift
public final class VelocityAdsInitRequest {
    public final class Builder {
        public init(_ appKey: String)
        public func withDebug(_ debug: Bool) -> Builder
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
    // Network / server errors (1xxx)
    public static let invalidURL: Int              // 1000
    public static let networkError: Int            // 1001
    public static let jsonParseError: Int          // 1002
    public static let invalidResponse: Int         // 1003
    public static let emptyResponseBody: Int       // 1004
    public static let requestEncodingFailed: Int   // 1005
    public static let serverErrorField: Int        // 1006
    public static let httpFailure: Int             // 1007

    // SDK errors (2xxx)
    public static let sdkNotInitialized: Int           // 2000
    public static let sdkInitializationInProgress: Int // 2001
    public static let loadAlreadyInProgress: Int       // 2002
    public static let loadServiceUnavailable: Int      // 2003
    public static let invalidAdResponse: Int           // 2004
    public static let noFill: Int                      // 2005
}
```

Error code behavior:
- HTTP failures use `VelocityAdsErrorCode.httpFailure` (`1007`)
- HTTP status details are included in `VelocityAdsError.message`
- SDK-defined constants are centralized in `VelocityAdsErrorCode`:

**Network / server errors (1xxx):**
  - `VelocityAdsErrorCode.invalidURL` (`1000`) — Malformed URL
  - `VelocityAdsErrorCode.networkError` (`1001`) — Network request failed
  - `VelocityAdsErrorCode.jsonParseError` (`1002`) — Response JSON could not be parsed
  - `VelocityAdsErrorCode.invalidResponse` (`1003`) — Response structure is invalid
  - `VelocityAdsErrorCode.emptyResponseBody` (`1004`) — Server returned an empty body
  - `VelocityAdsErrorCode.requestEncodingFailed` (`1005`) — Request body encoding failed
  - `VelocityAdsErrorCode.serverErrorField` (`1006`) — Server returned an error field in the response
  - `VelocityAdsErrorCode.httpFailure` (`1007`) — HTTP status code indicates failure

**SDK errors (2xxx):**
  - `VelocityAdsErrorCode.sdkNotInitialized` (`2000`) — `loadAd` called before `initSDK`
  - `VelocityAdsErrorCode.sdkInitializationInProgress` (`2001`) — `loadAd` called while initialization is still in progress
  - `VelocityAdsErrorCode.loadAlreadyInProgress` (`2002`) — `loadAd` called on an ad instance that is already loading
  - `VelocityAdsErrorCode.loadServiceUnavailable` (`2003`) — Internal load service is not available
  - `VelocityAdsErrorCode.invalidAdResponse` (`2004`) — Ad response is missing required data
  - `VelocityAdsErrorCode.noFill` (`2005`) — No ad available for the given context

### Delegates

#### `VelocityAdsInitDelegate`

```swift
protocol VelocityAdsInitDelegate: AnyObject {
    func onInitSuccess()
    func onInitFailure(error: VelocityAdsError)
}
```

#### `VelocityNativeAdDelegate`

```swift
protocol VelocityNativeAdDelegate: AnyObject {
    func onAdLoaded(nativeAd: VelocityNativeAd)
    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError)
    func onAdImpression(nativeAd: VelocityNativeAd)
    func onAdClicked(nativeAd: VelocityNativeAd)
}
```

---

**Last Updated:** March 2026
**SDK Version:** 0.2.0
