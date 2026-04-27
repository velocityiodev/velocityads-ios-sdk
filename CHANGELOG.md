# Changelog

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
