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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.11.0/VelocityAdsSDK-0.11.0.zip",
            checksum: "7334e31b0930b2bac407103bcf21f555b13b49257b11d5ab299e1bcb4b2cbeae"
        ),
    ]
)

