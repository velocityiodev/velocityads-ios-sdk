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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.13.0/VelocityAdsSDK-0.13.0.zip",
            checksum: "d767384ab2eaf0e2a74573e890a61c31ec8abb8f069c1d29ce04c03dea13d99e"
        ),
    ]
)

