// swift-tools-version:5.9
// Velocity Ads SDK for iOS — binary package from GitHub Releases
import PackageDescription

let package = Package(
    name: "VelocityAdsSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "VelocityAdsSDK", targets: ["VelocityAdsSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "VelocityAdsSDK",
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.4.0/VelocityAdsSDK-0.4.0.zip",
            checksum: "bc1e9f39caaa4a657ebec10a3483e93675a0348effc78dd9f91e8b62d400adcc"
        ),
    ]
)

