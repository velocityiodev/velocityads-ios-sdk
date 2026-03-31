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
3. Choose the version rule (e.g. "Up to Next Major" from `0.2.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

---

## Installation (CocoaPods)

Add the following to your `Podfile`:

```ruby
pod 'VelocityAdsSDK', '0.2.0'
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

// 2. Load a native ad when needed
let adRequest = VelocityNativeAdRequest.Builder()
    .withPrompt("user query")
    .withAIResponse("AI response text")
    .withConversationHistory(conversationHistory) // optional
    .withAdditionalContext("optional extra context") // optional
    .withAdUnitId(adUnitId) // optional
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.loadAd(delegate: myAdDelegate)
```

Delegate contracts:

```swift
final class MyInitDelegate: VelocityAdsInitDelegate {
    func onInitSuccess() {}
    func onInitFailure(error: VelocityAdsError) {}
}

final class MyAdDelegate: VelocityNativeAdDelegate {
    func onAdLoaded(nativeAd: VelocityNativeAd) {}
    func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {}
    func onAdImpression(nativeAd: VelocityNativeAd) {}
    func onAdClicked(nativeAd: VelocityNativeAd) {}
}
```

---

## Full Documentation

For installation details, initialization options, privacy (CCPA, GDPR, IAB TCF), loading ads, and the full API reference, see the **[Integration Guide](Docs/INTEGRATION_GUIDE.md)**.

---

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
