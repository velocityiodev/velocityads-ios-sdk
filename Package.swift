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
            url: "https://github.com/velocityiodev/velocityads-ios-sdk/releases/download/0.1.0/VelocityAdsSDK-0.1.0.zip",
            checksum: "f07a474ac1368608fca129e42db6e81ee0d6e6ac35c7a75edf40aac8ee33aa14"
        ),
    ]
)

