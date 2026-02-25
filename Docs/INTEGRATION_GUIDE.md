# Velocity Ads SDK Integration Guide

**Version:** 0.1.0  
**Last Updated:** February 2026  
**Platform:** iOS 15.0+  
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

- **Minimum iOS:** 15.0
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
3. Choose the version rule (e.g. "Up to Next Major" starting from `0.1.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

The package uses a binary target hosted on GitHub Releases. Each release (e.g. `0.1.0`) provides a pre-built XCFramework; Xcode resolves the correct asset automatically when you select a version.

---

## SDK Initialization

### Basic Initialization

Initialize the SDK at app startup (e.g. in your `AppDelegate` or `@main` App struct):

```swift
import UIKit
import VelocityAdsSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        VelocityAds.initSDK(appKey: "YOUR_APPLICATION_KEY")

        return true
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
        VelocityAds.initSDK(appKey: "YOUR_APPLICATION_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Important:**
- ⚠️ Initialize once during app startup
- ⚠️ Must be called before loading any ads

### Advanced Initialization with Callback

For better control and error handling:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        VelocityAds.initSDK(
            appKey: "YOUR_APPLICATION_KEY",
            publisherUserId: "USER_12345",  // Optional: User identifier
            debug = false,  // Set to true to enable debug logging for troubleshooting
            callback: MyInitCallback()
        )

        return true
    }
}

class MyInitCallback: InitCallback {
    func onInitSuccess(sessionId: String, mediationEnabled: Bool) {
        print("SDK initialized successfully")
    }

    func onInitFailure(error: String) {
        print("Initialization failed: \(error)")
        // Handle initialization failure
    }
}
```

## Loading Native Ads

The SDK provides a method for loading native ads:

1. **`loadNativeAd(prompt:aiResponse:conversationHistory:dimensions:adUnitId:callback:)`** - Returns ad data model via callback (`NativeAd`)

```swift
VelocityAds.loadNativeAd(
    prompt: "What's the weather today?",
    aiResponse: "The weather is sunny with 72°F...",  // Optional: provide AI response for better targeting
    conversationHistory: nil,  // Optional: conversation history for better targeting
    dimensions: AdDimensions(width: 320, height: 50),  // Always provide ad dimensions in points
    adUnitId: "ad_unit_123",  // Optional
    callback: self
)

// AdCallback implementation
func onSuccess(nativeAd: NativeAd) {
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

func onError(error: String) {
    print("Failed to load ad: \(error)")
}
```

### Conversation History

For better ad targeting in chat applications, you can provide conversation history:

```swift
// First call - no conversation history
VelocityAds.loadNativeAd(
    prompt: "What's the weather today?",
    aiResponse: "The weather is sunny...",  // Optional: provide AI response for better targeting
    conversationHistory: nil,  // Empty on first call
    dimensions: AdDimensions(width: 320, height: 50),  // Always provide ad dimensions in points
    callback: adCallback
)

// Subsequent calls - with conversation history
let conversationHistory: [[String: Any]] = [
    ["role": "user", "content": "What's the weather today?"],
    ["role": "assistant", "content": "The weather is sunny..."]
]

VelocityAds.loadNativeAd(
    prompt: "What about tomorrow?",
    aiResponse: "Tomorrow will be cloudy...",  // Optional: provide AI response for better targeting
    conversationHistory: conversationHistory,  // Previous conversation
    dimensions: AdDimensions(width: 320, height: 50),  // Always provide ad dimensions in points
    callback: adCallback
)
```

**Note:** The `conversationHistory` parameter accepts an array of dictionaries (`[[String: Any]]?`). Each dictionary should have `"role"` (`"user"` or `"assistant"`) and `"content"` (message text). Update it with the full conversation history for best targeting.


### Ad Dimensions

Always provide ad dimensions in **points**:

```swift
// Use view or screen dimensions
let dimensions = AdDimensions(
    width: Int(adContainerView.bounds.width),
    height: Int(adContainerView.bounds.height)
)
```

Or use fixed dimensions:

```swift
let dimensions = AdDimensions(
    width: 320,  // points
    height: 50   // points
)
```

---

## Integration Examples

### Example 1: Chat Application

```swift
import UIKit
import VelocityAdsSDK

class ChatViewController: UIViewController, AdCallback {
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
        let width = Int(view.bounds.width)
        let height = 50
        let dimensions = AdDimensions(width: width, height: height)

        // Pass conversation history (empty on first call)
        let historyToPass = conversationHistory.isEmpty ? nil : conversationHistory

        VelocityAds.loadNativeAd(
            prompt: prompt,
            aiResponse: aiResponse,  // Optional
            conversationHistory: historyToPass,  // Optional conversation history
            dimensions: dimensions,
            adUnitId: nil,  // Optional
            callback: self
        )
    }

    func onSuccess(nativeAd: NativeAd) {
        // Display ad manually using custom UI
        displayAdManually(nativeAd)
    }

    func onError(error: String) {
        // Continue without ad
        print("Ad load failed: \(error)")
    }
}
```

### Example 2: Table View / Collection View Integration

```swift
class AdTableViewCell: UITableViewCell {
    static let reuseId = "AdCell"
    private let containerView = UIView()

    func configure(prompt: String, aiResponse: String? = nil) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        let dimensions = AdDimensions(width: Int(bounds.width), height: Int(bounds.height))

        VelocityAds.loadNativeAd(
            prompt: prompt,
            aiResponse: aiResponse,  // Optional
            conversationHistory: nil,  // Optional
            dimensions: dimensions,
            adUnitId: nil,  // Optional
            callback: AdCellCallback(containerView: containerView, cell: self)
        )
    }
}

// Use a callback object that holds the container; ensure it is retained until callback
private class AdCellCallback: AdCallback {
    weak var containerView: UIView?
    weak var cell: UITableViewCell?

    func onSuccess(nativeAd: NativeAd) {
        guard let containerView = containerView else { return }
        // Build and add ad UI to containerView
    }

    func onError(error: String) {
        // Hide ad container or show placeholder
        cell?.contentView.isHidden = true
    }
}
```

### Example 3: Article Reader

```swift
class ArticleViewController: UIViewController, AdCallback {

    private func loadArticle(_ article: Article) {
        // Display article content
        titleLabel.text = article.title
        contentLabel.text = article.content

        let dimensions = AdDimensions(
            width: Int(contentView.bounds.width),
            height: 400  // Fixed height for article ads (points)
        )

        // Load contextual ad
        VelocityAds.loadNativeAd(
            prompt: article.title,
            aiResponse: article.content,  // Optional
            conversationHistory: nil,  // Optional
            dimensions: dimensions,
            adUnitId: nil,  // Optional
            callback: self
        )
    }

    func onSuccess(nativeAd: NativeAd) {
        // Display ad manually using custom UI
        displayAdManually(nativeAd)

        // Insert ad after first paragraph
        // (ad view would be inserted at position 1)
    }

    func onError(error: String) {
        print("Ad load failed: \(error)")
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. "SDK not initialized" Error

**Problem:** Calling `loadNativeAd` before `initSDK`, or loading ads before initialization has completed.


**Solution 1 — Use InitCallback:** 
Initialize at startup and only load ads after initialization succeeds. This avoids calling `loadNativeAd` before the SDK is ready.

```swift
VelocityAds.initSDK(
    appKey: "YOUR_APPLICATION_KEY",
    callback: MyInitCallback()
)

class MyInitCallback: InitCallback {
    func onInitSuccess(sessionId: String, mediationEnabled: Bool) {
        // SDK is ready — enable ad loading in your UI or trigger first ad load
        enableAdLoading()
    }
    
    func onInitFailure(error: String) {
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

VelocityAds.loadNativeAd(
    prompt: prompt,
    aiResponse: aiResponse,
    conversationHistory: conversationHistory,
    dimensions: dimensions,
    adUnitId: adUnitId,
    callback: self
)
```

#### 2. Ads Not Loading

**Checklist:**
- ✅ SDK initialized at app startup (AppDelegate or App init)
- ✅ Network connectivity available
- ✅ Debug mode enabled to see logs

**Enable Debug Mode:**
```swift
VelocityAds.initSDK(
    appKey: "YOUR_APPLICATION_KEY",
    debug = false,  // Enable debug logs
}
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
- Use weak references where appropriate (e.g. in callbacks)
- Clean up in `deinit` or when the view controller is dismissed

❌ **DON'T:**
- Keep strong references to ad views after the screen is dismissed

### 4. Error Handling

✅ **DO:**

```swift
func onError(error: String) {
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

#### `initSDK(appKey:publisherUserId:debug:callback:)`

```swift
VelocityAds.initSDK(
    appKey: String,
    publisherUserId: String? = nil,
    debug: Bool = false,
    callback: InitCallback? = nil
)
```

**Parameters:**
- `appKey` - Your application key (required)
- `publisherUserId` - User identifier (optional)
- `debug` - Enable debug logging (optional)
- `callback` - Initialization callback (optional)

#### `loadNativeAd(prompt:aiResponse:conversationHistory:dimensions:adUnitId:callback:)`

```swift
VelocityAds.loadNativeAd(
    prompt: String,
    aiResponse: String? = nil,
    conversationHistory: [[String: Any]]? = nil,
    dimensions: AdDimensions,
    adUnitId: String? = nil,
    callback: AdCallback
)
```

**Parameters:**
- `prompt` - User's query/prompt (required)
- `aiResponse` - AI-generated response content (optional)
- `conversationHistory` - Optional conversation history for ad targeting (array of dictionaries with `"role"` and `"content"`)
- `dimensions` - Ad dimensions in points (required)
- `adUnitId` - Ad unit identifier (optional)
- `callback` - Ad loading callback (required)

### Models

#### `AdDimensions`

```swift
AdDimensions(width: Int, height: Int)
```

- `width` - Width in points
- `height` - Height in points

#### `NativeAd`

```swift
struct NativeAd {
    let id: String                    // Unique ad identifier
    let title: String                 // Ad title/headline
    let description: String           // Ad body text
    let callToAction: String          // CTA button text (e.g., "Learn More")
    let sponsoredBy: String           // Advertiser/sponsor name
    let imageUrl: String              // Ad image URL
    let clickUrl: String              // Destination URL when ad is clicked
    let impressionUrl: String         // URL to track ad impressions
    let category: String              // Ad category (e.g., "Technology")
    let tags: [String]                // List of relevant tags/keywords
    let price: String?                // Optional price information
    let rating: Double?               // Optional rating (0.0 - 5.0)
    let reviewCount: Int?             // Optional number of reviews
}
```

### Callbacks

#### `InitCallback`

```swift
protocol InitCallback: AnyObject {
    func onInitSuccess(sessionId: String, mediationEnabled: Bool)
    func onInitFailure(error: String)
}
```

#### `AdCallback`

```swift
protocol AdCallback: AnyObject {
    func onSuccess(nativeAd: NativeAd)
    func onError(error: String)
}
```

---

**Last Updated:** February 2026  
**SDK Version:** 0.1.0
