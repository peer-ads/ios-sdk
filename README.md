# PeerAdsSDK (iOS)

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 15+](https://img.shields.io/badge/iOS-15+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)

iOS SDK for [PeerAds](https://peerads.io) — unified ad mediation + peer cross-promotion, distributed as a Swift Package.

## Features

- **Peer network** — cross-promote with same-tier apps at zero cost (90 % of slots by default)
- **Paid campaigns** — CPM-bid waterfall fills remaining slots
- **Self network** — falls back to AdMob, AppLovin MAX, Unity Ads, or IronSource
- **Banner, Interstitial, and Rewarded** ad formats via `UIKit`
- **Swift concurrency** — all network calls use `async/await`
- **Test mode** — isolated sandbox via `pk_test_` keys

## Requirements

- iOS 15+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies…**

```
https://github.com/peerads/peerads-ios.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/peerads/peerads-ios.git", from: "0.1.0")
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "PeerAdsSDK", package: "peerads-ios")
    ])
]
```

> **Note:** Meta (FBAudienceNetwork) is not available via SPM.
> Add it via CocoaPods: `pod 'FBAudienceNetwork', '~> 6.15'`

## Quick Start

### 1. Initialize in AppDelegate

```swift
import PeerAdsSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        PeerAds.initialize(config: PAConfig(
            apiKey: "pk_live_YOUR_KEY",
            networks: [
                "admob":    PANetworkConfig(adUnitId: "ca-app-pub-XXXX/YYYY"),
                "applovin": PANetworkConfig(sdkKey: "YOUR_APPLOVIN_KEY"),
            ]
        ))
        return true
    }
}
```

### 2. Request and show a banner

```swift
import PeerAdsSDK

class HomeViewController: UIViewController {
    @IBOutlet weak var bannerContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await loadBanner() }
    }

    private func loadBanner() async {
        guard let sdk = PeerAds.shared else { return }
        do {
            let ad = try await sdk.requestAd(type: "banner", slotId: "home_banner")
            sdk.loadBanner(ad: ad, into: bannerContainer)
            sdk.track(adId: ad.id, event: "impression")
        } catch {
            print("Banner load failed:", error)
        }
    }
}
```

## Ad Formats

### Interstitial

```swift
// Load (e.g. on level start)
let ad = try await sdk.requestAd(type: "interstitial", slotId: "interstitial")
sdk.loadInterstitial(ad: ad)

// Show at a natural break point
if sdk.isInterstitialReady(network: ad.network ?? "") {
    sdk.showInterstitial(network: ad.network ?? "", from: self)
    sdk.track(adId: ad.id, event: "impression")
}
```

### Rewarded

```swift
let ad = try await sdk.requestAd(type: "rewarded", slotId: "rewarded")
sdk.loadRewarded(ad: ad)

if sdk.isRewardedReady(network: ad.network ?? "") {
    sdk.showRewarded(network: ad.network ?? "", from: self)
    sdk.track(adId: ad.id, event: "impression")
}
```

## Ad Network Adapters

```swift
PeerAds.initialize(config: PAConfig(
    apiKey: "pk_live_...",
    networks: [
        "admob": PANetworkConfig(
            adUnitId:    "ca-app-pub-XXXX/YYYY",    // banner / interstitial
            rewardedId:  "ca-app-pub-XXXX/ZZZZ"
        ),
        "applovin": PANetworkConfig(sdkKey: "YOUR_APPLOVIN_KEY"),
        "unity":    PANetworkConfig(gameId: "YOUR_UNITY_GAME_ID"),
        "ironsource": PANetworkConfig(appKey: "YOUR_IS_APP_KEY"),
    ]
))
```

## DAU Reporting

Report from your **server**, never from the app bundle (requires secret key).

```swift
// Server-side Swift only
try await sdk.reportDau(15000)
```

## Test Mode

```swift
PeerAds.initialize(config: PAConfig(
    apiKey:     "pk_live_...",
    testApiKey: "pk_test_...",
    environment: .test   // uses testApiKey; ads are labelled [TEST]
))
```

## Error Handling

```swift
do {
    let ad = try await sdk.requestAd(type: "banner", slotId: "banner_1")
} catch PAError.notInitialized {
    // Call PeerAds.initialize() first
} catch PAError.adLoadFailed(let reason) {
    print("Ad failed:", reason)
} catch PAError.missingSecretKey {
    // secretKey required for this call
} catch {
    print("Unexpected error:", error)
}
```

## API Reference

| Method | Description |
|--------|-------------|
| `PeerAds.initialize(config:)` | Initialize the SDK. Call in `didFinishLaunching`. |
| `PeerAds.shared` | The singleton instance after initialization. |
| `sdk.requestAd(type:slotId:)` | Fetch an ad (`"banner"`, `"interstitial"`, `"rewarded"`). |
| `sdk.loadBanner(ad:size:into:)` | Load and render a banner into a `UIView`. |
| `sdk.loadInterstitial(ad:)` | Pre-load an interstitial. |
| `sdk.showInterstitial(network:from:)` | Show a pre-loaded interstitial. |
| `sdk.isInterstitialReady(network:)` | Check if an interstitial is ready to show. |
| `sdk.loadRewarded(ad:)` | Pre-load a rewarded video. |
| `sdk.showRewarded(network:from:)` | Show a pre-loaded rewarded video. |
| `sdk.isRewardedReady(network:)` | Check if a rewarded video is ready to show. |
| `sdk.track(adId:event:)` | Track `"impression"`, `"click"`, or `"install"`. |
| `sdk.reportDau(_:)` | Report DAU (server-side, secret key required). |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © PeerAds
