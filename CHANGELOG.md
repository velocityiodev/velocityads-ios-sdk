# Changelog

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
