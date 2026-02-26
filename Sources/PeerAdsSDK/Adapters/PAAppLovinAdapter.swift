import UIKit

/// AppLovin MAX adapter.
///
/// Add via Swift Package Manager:
///   https://github.com/AppLovin/AppLovin-MAX-Swift-Package
///   Package: AppLovinSDK, version ≥ 12.0.0
///
/// Set your SDK key in config["sdkKey"] and add it to Info.plist as AppLovinSdkKey.
public final class PAAppLovinAdapter: NSObject, PAAdNetworkAdapter {
  public weak var delegate: PAAdNetworkDelegate?
  public private(set) var isInterstitialReady = false
  public private(set) var isRewardedReady = false

  private var sdkKey = ""
  private var bannerView: AnyObject?
  private var interstitialAdUnitId = ""
  private var rewardedAdUnitId = ""

  public func initialize(config: PANetworkConfig) {
    sdkKey = config["sdkKey"] ?? ""
    // ALSdk.shared().mediationProvider = "max"
    // ALSdk.shared().initializeSdk { _ in }
    print("[PeerAds/AppLovin] Initialized sdkKey=*** — add AppLovinSDK via SPM to enable real ads")
  }

  public func loadBanner(adUnitId: String, size: CGSize, into container: UIView) {
    // let banner = MAAdView(adUnitIdentifier: adUnitId)
    // banner.frame = CGRect(origin: .zero, size: size)
    // banner.delegate = self; container.addSubview(banner); banner.loadAd()
    // self.bannerView = banner

    let label = UILabel(frame: CGRect(origin: .zero, size: size))
    label.text = "AppLovin Banner (\(adUnitId))"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 11)
    label.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1, alpha: 1)
    container.addSubview(label)
    delegate?.adNetworkDidLoadBanner(label, network: "applovin")
  }

  public func loadInterstitial(adUnitId: String) {
    interstitialAdUnitId = adUnitId
    // let interstitial = MAInterstitialAd(adUnitIdentifier: adUnitId)
    // interstitial.delegate = self; interstitial.load()
    isInterstitialReady = true
    delegate?.adNetworkDidLoadInterstitial(network: "applovin")
  }

  public func showInterstitial(from viewController: UIViewController) {
    guard isInterstitialReady else { return }
    // interstitialAd?.show()
    isInterstitialReady = false
  }

  public func loadRewarded(adUnitId: String) {
    rewardedAdUnitId = adUnitId
    // let rewarded = MARewardedAd.shared(withAdUnitIdentifier: adUnitId)
    // rewarded.delegate = self; rewarded.load()
    isRewardedReady = true
  }

  public func showRewarded(from viewController: UIViewController) {
    guard isRewardedReady else { return }
    // MARewardedAd.shared(withAdUnitIdentifier: rewardedAdUnitId).show()
    // MARewardedAdDelegate.didRewardUser -> delegate?.adNetworkDidEarnReward
    delegate?.adNetworkDidEarnReward(type: "coins", amount: 10, network: "applovin")
    isRewardedReady = false
  }
}
