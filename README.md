# Velocity Ads SDK for iOS

Velocity Ads is an iOS SDK that provides AI-powered contextual advertising.

**Requirements:** iOS 15.0+, Xcode 26.0+, Swift 5.5+

---

## Installation (Swift Package Manager)

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the package URL:
   ```
   https://github.com/velocityiodev/velocityads-ios-sdk
   ```
3. Choose the version rule (e.g. "Up to Next Major" from `0.11.0`) and add the package.
4. Add the **VelocityAdsSDK** library to your app target.

---

## Installation (CocoaPods)

Add the following to your `Podfile`:

```ruby
pod 'VelocityAdsSDK', '0.11.0'
```

Then run:

```bash
pod install
```

---

## Quick Start

### 1. Initialize

```swift
import VelocityAdsSDK

let initRequest = VelocityAdsInitRequest.Builder("your-app-key").build()
VelocityAds.initSDK(initRequest, delegate: self)
```

```swift
func onInitSuccess() { /* SDK ready — safe to load ads */ }
func onInitFailure(error: VelocityAdsError) { /* handle error */ }
```

---

### 2. Native Ads

```swift
// Manual rendering
let adRequest = VelocityNativeAdRequest.Builder(adUnitId: "your-ad-unit-id")
    .withPrompt("user query")           // optional
    .withAIResponse("AI response text") // optional
    .build()

let nativeAd = VelocityNativeAd(adRequest)
nativeAd.load(delegate: self)
```

```swift
func onAdLoaded(nativeAd: VelocityNativeAd) {
    // Read nativeAd.data to populate your own UI, then:
    nativeAd.registerViewForInteraction(adView: container, clickableViews: [ctaButton])
}
func onAdFailedToLoad(nativeAd: VelocityNativeAd, error: VelocityAdsError) {}
// onAdImpression / onAdClicked — optional, default no-op
```

For the SDK-rendered path (`VelocityNativeAdViewRequest` + `createAdView()` / `createAdSwiftUIView()`), see the [Integration Guide](Docs/INTEGRATION_GUIDE.md).

---

### 3. Interstitial Ads

```swift
let adRequest = VelocityInterstitialAdRequest.Builder(adUnitId: "your-ad-unit-id").build()
let interstitialAd = VelocityInterstitialAd(adRequest)
interstitialAd.load(delegate: self)
```

The fullscreen delegate methods deliver the ad as `any VelocityFullscreenAd`:

```swift
func onAdLoaded(ad: any VelocityFullscreenAd) {
    ad.show() // or show at a later break point
}
func onAdFailedToLoad(ad: any VelocityFullscreenAd, error: VelocityAdsError) {}
func onAdDismissed(ad: any VelocityFullscreenAd) {
    ad.destroy() // instance is spent — create a new one for the next ad
}
// onAdShown / onAdImpression / onAdFailedToShow / onAdClicked — optional, default no-op
```

---

### 4. Rewarded Ads

```swift
let adRequest = VelocityRewardedAdRequest.Builder(adUnitId: "your-ad-unit-id").build()
let rewardedAd = VelocityRewardedAd(adRequest)
rewardedAd.load(delegate: self)
```

```swift
func onAdLoaded(ad: any VelocityFullscreenAd) {
    ad.show() // or show at a later break point
}
func onAdFailedToLoad(ad: any VelocityFullscreenAd, error: VelocityAdsError) {}
func onUserRewarded(ad: any VelocityFullscreenAd) {
    // User completed the ad — grant the reward
}
func onAdDismissed(ad: any VelocityFullscreenAd) {
    ad.destroy() // instance is spent — create a new one for the next ad
}
// onAdShown / onAdImpression / onAdFailedToShow / onAdClicked — optional, default no-op
```

---

### 5. Banner Ads

```swift
let adRequest = VelocityBannerAdRequest.Builder(
    adUnitId: "your-ad-unit-id",
    adSize: .banner // or .mrec, .leaderboard, .adaptiveBanner(width:)
)
.withAdditionalContext("travel, summer") // optional
.build()

let bannerAd = VelocityBannerAd(adRequest)
bannerAd.load(bannerView: bannerView, delegate: self)
```

```swift
func onAdLoaded(ad: VelocityBannerAd) {
    // bannerView is ready — add it to your view hierarchy
    bannerContainerView.addSubview(bannerView)
}
func onAdFailedToLoad(ad: VelocityBannerAd, error: VelocityAdsError) {}
// onAdImpression / onAdFailedToShow / onAdClicked — optional, default no-op

// When done:
bannerAd.destroy()
```

---

## Full Documentation

For installation details, initialization options, privacy (CCPA, GDPR), loading ads, and the full API reference, see the **[Integration Guide](Docs/INTEGRATION_GUIDE.md)**.

---

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
