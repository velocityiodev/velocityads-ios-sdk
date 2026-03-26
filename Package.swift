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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.1.1/VelocityAdsSDK-0.1.1.zip",
            checksum: "9a4a2afcfa34e1c9b809d22a56e64dce5942612071a62eb0efeba86d399f7a87"
        ),
    ]
)

