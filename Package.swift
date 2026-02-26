// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PeerAdsSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "PeerAdsSDK", targets: ["PeerAdsSDK"]),
    ],
    dependencies: [
        // Google Mobile Ads (AdMob)
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "11.0.0"
        ),
        // AppLovin MAX
        .package(
            url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git",
            from: "12.0.0"
        ),
        // Unity Ads
        .package(
            url: "https://github.com/Unity-Technologies/unity-ads-ios.git",
            from: "4.9.0"
        ),
        // IronSource (SPM adapter)
        .package(
            url: "https://github.com/ironsource-mobile/IronSource-iOS-AdaptersSPM.git",
            from: "7.5.0"
        ),
        // Note: Meta (FBAudienceNetwork) is not available via SPM.
        // Add via CocoaPods: pod 'FBAudienceNetwork', '~> 6.15'
    ],
    targets: [
        .target(
            name: "PeerAdsSDK",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
                .product(name: "UnityAds", package: "unity-ads-ios"),
                .product(name: "IronSource", package: "IronSource-iOS-AdaptersSPM"),
            ],
            path: "Sources/PeerAdsSDK"
        ),
        .testTarget(
            name: "PeerAdsSDKTests",
            dependencies: ["PeerAdsSDK"],
            path: "Tests/PeerAdsSDKTests"
        ),
    ]
)
