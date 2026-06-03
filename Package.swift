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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.7.0/VelocityAdsSDK-0.7.0.zip",
            checksum: "023117613045ee805f104bfd41db88793f00c2bdf710362d9867c26995fde3ed"
        ),
    ]
)

