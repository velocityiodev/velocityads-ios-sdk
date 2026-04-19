# Velocity Ads SDK for iOS

Velocity Ads is an iOS SDK that provides AI-powered contextual advertising.

**Requirements:** iOS 13.0+, Xcode 16.0+, Swift 5.5+

---

## Installation (Swift Package Manager)

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:
   ```
   https://github.com/velocityiodev/velocityads-ios-sdk
   ```
3. Choose the version rule (e.g. "Up to Next Major" from `0.3.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

---

## Installation (CocoaPods)

Add the following to your `Podfile`:

```ruby
pod 'VelocityAdsSDK', '0.3.0'
```

Then run:

```bash
pod install
```

---

## Quick Start

```swift
import VelocityAdsSDK

// 1. Initialize at app startup
let initRequest = VelocityAdsInitRequest.Builder("app_123").build()
VelocityAds.initSDK(initRequest, delegate: MyInitDelegate())

// 2a. Load a native ad (manual rendering)
let adRequest = VelocityNativeAdRequest.Builder()
    .withPrompt("user query") // optional
    .withAIResponse("AI response text") // optional
    .withConversationHistory(conversationHistory) // optional
    .withAdditionalContext("optional extra context") // optional
    .withAdUnitId(adUnitId) // optional
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: myAdDelegate)

// 2b. Load a native ad (SDK-rendered view — size required for template selection)
let viewRequest = VelocityNativeAdViewRequest.Builder(adViewSize: .M)
    .withPrompt("user query") // optional
    .withAIResponse("AI response text") // optional
    .build()

let nativeAd = VelocityNativeAd(viewRequest)
nativeAd.loadAd(delegate: myAdDelegate)
```

Delegate contracts:

```swift
@MainActor
final class MyInitDelegate: VelocityAdsInitDelegate {
    func onInitSuccess() { /* SDK ready — safe to load ads */ }
    func onInitFailure(error: VelocityAdsError) { /* handle error */ }
}

@MainActor
final class MyAdDelegate: VelocityNativeAdDelegate {
    func onAdLoaded(nativeAd: VelocityNativeAd) {
        // SDK-rendered path (VelocityNativeAdViewRequest):
        //   let adView = nativeAd.createAdView()   // UIKit
        //   let adView = nativeAd.createAdSwiftUIView()  // SwiftUI
        //   — impression & click tracking are automatic

        // Manual rendering path (VelocityNativeAdRequest):
        //   Read nativeAd.data to populate your own UI, then:
        //   nativeAd.registerViewForInteraction(adView: container, clickableViews: [ctaButton])
        //   — enables automatic impression & click tracking
    }
    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {}
    func onAdImpression(nativeAd: VelocityNativeAd) {}  // optional — default no-op
    func onAdClicked(nativeAd: VelocityNativeAd) {}     // optional — default no-op
}
```

---

## Full Documentation

For installation details, initialization options, privacy (CCPA, GDPR), loading ads, and the full API reference, see the **[Integration Guide](Docs/INTEGRATION_GUIDE.md)**.

---

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
