# Changelog

## [0.7.0] - 2026-06-03

**Features:**

- **`VelocityNativeAdViewSize.XS`** – New extra-small ad size (64 pt height).
- **`VelocityNativeAd.onCollapseStateChanged`** – New optional closure for SwiftUI publishers who use `createAdSwiftUIView()`. This closure fires on the main thread when a Large (`L`) ad transitions between expanded and collapsed states.
- **`NativeAd.getLargeImageUrl(width:height:)`** – New method on `NativeAd` (accessible via `VelocityNativeAd.data`) that returns the landscape large image URL with dimension placeholders substituted for the supplied pixel values. Use this when manually rendering the large image at a known size to request an optimized resolution. When `width` or `height` is ≤ 0 the default 1920×640 dimensions are used. The existing `largeImageUrl` property continues to resolve at the default size.

**Breaking Changes:**

- **`adUnitId` is now a required parameter** — `VelocityNativeAdRequest.Builder` and `VelocityNativeAdViewRequest.Builder` both require `adUnitId` as their first constructor argument. Calls to `Builder()` (no arguments) or the now-removed `.withAdUnitId(_:)` chain method will not compile.
  - `VelocityNativeAdRequest.Builder()` → `VelocityNativeAdRequest.Builder(adUnitId: "your-unit-id")`
  - `VelocityNativeAdViewRequest.Builder(adViewSize: .M)` → `VelocityNativeAdViewRequest.Builder(adUnitId: "your-unit-id", adViewSize: .M)`
  - Remove any `.withAdUnitId(...)` chain calls — the value is now passed directly to the constructor.
- Updated the Small (`S`) ad view height from 50pt to 100pt.

## [0.6.0] - 2026-05-24

**Features:**

- **Expanded demand offering and improved performance** — NativeAdView ads now benefit from an expanded advertiser network and optimized ad delivery, resulting in higher fill rates and faster load times.
- Updated the iOS SDK version numbering to align with the corresponding Android SDK version for cross-platform consistency.

**Breaking Changes:**

- **`NativeAd` model fields removed** – The following fields have been removed from the public `NativeAd` struct (accessible via `VelocityNativeAd.data`):
  - `id: String?`
  - `adTemplateId: AdTemplateId?`
  - `expandButton: String?`

  If your app reads any of these fields from `nativeAd.data`, remove those references.

## [0.4.0] - 2026-05-10

**Features:**

- **Preliminary Text** – `VelocityNativeAdRequest` now accepts an optional `includePreliminaryText(Bool)` parameter. When enabled, the server returns a short contextual snippet in `VelocityNativeAd.data?.preliminaryText` that publishers can display above the ad creative to increase relevance.
- **Expand/Collapse Animation** – Large (`L`) ad views now support expand/collapse animation. Call `nativeAd.collapse()` or `adView.collapse()` to animate the card from 280pt to 158pt.
- **New Color Tokens** – Added two new `AdColors` tokens: `ctaBorder` (CTA button border) and `cardBorder` (outer card border).

**Breaking Changes:**

- Removed `debug` option from `VelocityAdsInitRequest`.
- Updated the Medium (`M`) ad view height from 160pt to 158pt.
- Updated the Large (`L`) ad view height from 300pt to 280pt.

## [0.3.1] - 2026-04-28

**Breaking Changes:**

- Updated the Medium (`M`) ad view height from 100pt to 160pt.

## [0.3.0] - 2026-04-19

**Features:**

- **SwiftUI Native Ad View** – Pre-built SwiftUI view for Native Ads. Supports all three sizes (S / M / L), theming, custom colors, typography, and dark mode.
- **View recycling support** – New `configureAdView(_:)` method on `VelocityNativeAd` rebinds an existing `VelocityNativeAdView` to new ad data without recreating the view hierarchy, enabling efficient cell reuse in UIKit and SwiftUI list containers.

**Breaking Changes:**

- **MAJOR SDK release** — This version includes an overhaul of the Velocity SDK API & features. In case you already have the Velocity Ads SDK integrated — please review the docs and update the integration accordingly. This isn't a drag & drop change. Note that it's highly recommended to update the integration to use the NativeAdView API suite. 

**Bug Fixes:**

- Fixed an issue where the Native Ad view would sometimes not render the description text under certain conditions.

## [0.2.0] - 2026-03-31

**Features:**

- **Native Ad View** – New pre-rendered `VelocityNativeAdView` (UIKit) with built-in ad layouts in three sizes (S / M / L), theming support via `AdViewConfiguration`, custom color schemes, and typography
- **Public SDK Breaking Change** – New Interface Layer for both Init and Load Native Ad functionality
- **Set User Id API** – A new API to set the user identifier

For more in depth info on all of these changes, see the Integration Guide.

## [0.1.1] - 2026-03-26

- Lowered minimum iOS deployment target iOS 13.0
- Added CocoaPods support

## [0.1.0] - 2026-02-25

Initial release of VelocityAds SDK for iOS.

**Features:**

- **loadNativeAd()** – Load native ads with AI-powered contextual targeting
- **Native ad model** with rich data (title, description, image, CTA, rating, price, etc.)
- **GDPR consent management** – `setConsent()`
- **CCPA "Do Not Sell" support** – `setDoNotSell()`
