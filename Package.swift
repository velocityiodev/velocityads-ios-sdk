// swift-tools-version:5.9
// Velocity Ads SDK for iOS — binary package from GitHub Releases
import PackageDescription

let package = Package(
    name: "VelocityAdsSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VelocityAdsSDK", targets: ["VelocityAdsSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "VelocityAdsSDK",
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.12.0/VelocityAdsSDK-0.12.0.zip",
            checksum: "02249fed5863f056a0a4c6de0cc67e3a8a2d27a84bfa4a03e75a60d8b4fe7aa6"
        ),
    ]
)

