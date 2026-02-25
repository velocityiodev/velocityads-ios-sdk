# Velocity Ads SDK for iOS

Velocity Ads is an iOS SDK that provides AI-powered contextual advertising.

**Requirements:** iOS 15.0+, Xcode 16.0+, Swift 5.5+

---

## Installation (Swift Package Manager)

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:
   ```
   https://github.com/velocityiodev/velocityads-ios-sdk
   ```
3. Choose the version rule (e.g. "Up to Next Major" from `0.1.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

---

## Quick Start

```swift
import VelocityAdsSDK

// 1. Initialize at app startup
VelocityAds.initSDK(
   appKey: "app_123",
   publisherUserId: "user_456",
   callback: myInitCallback
)

// 2. Load a native ad when needed
VelocityAds.loadNativeAd(
    prompt: "user query",
    aiResponse: "AI response text",
    conversationHistory: conversationHistory,
    dimensions: AdDimensions(width: 320, height: 50),
    adUnitId: adUnitId,
    callback: myAdCallback
)
```

---

## Full documentation

For installation details, initialization options, privacy (CCPA, GDPR, IAB TCF), loading ads, and the full API reference, see the **[Integration Guide](Docs/INTEGRATION_GUIDE.md)**.

---

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
