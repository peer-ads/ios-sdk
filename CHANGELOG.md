# Changelog

All notable changes to `PeerAdsSDK` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-02-24

### Added
- Initial release of `PeerAdsSDK`
- `PeerAds.initialize(config:)` — SDK initialisation. Call in `UIApplicationDelegate.didFinishLaunching`.
- `PAConfig` — configuration struct with live/test key pairs, environment, and network map
- `sdk.requestAd(type:slotId:)` — `async throws` ad request returning `PAAdResponse`
- `sdk.loadBanner(ad:size:into:)` — load and render a banner into any `UIView`
- `sdk.loadInterstitial(ad:)` / `showInterstitial(network:from:)` — full-screen interstitial support
- `sdk.isInterstitialReady(network:)` — check readiness before showing
- `sdk.loadRewarded(ad:)` / `showRewarded(network:from:)` — rewarded video support
- `sdk.isRewardedReady(network:)` — check readiness before showing
- `sdk.track(adId:event:)` — fire `"impression"`, `"click"`, or `"install"` events
- `sdk.reportDau(_:)` — `async throws` DAU reporting via secret key (server-side only)
- `PAAdapterManager` — delegates banner/interstitial/rewarded load and show to installed network SDKs
- Network adapters via SPM: AdMob (`GoogleMobileAds`), AppLovin MAX, Unity Ads, IronSource
- `PAError` — typed errors: `notInitialized`, `invalidURL`, `adLoadFailed(_:)`, `missingSecretKey`
- `.test` environment mode with `testApiKey` and visual `[TEST]` label
- iOS 15+ minimum deployment target; Swift 5.9 / Swift concurrency (`async/await`)
