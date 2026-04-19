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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.3.0/VelocityAdsSDK-0.3.0.zip",
            checksum: "0b332aa5227d712706a711d7bd717b75c15526320bc87d85176282a03b42b8d7"
        ),
    ]
)

