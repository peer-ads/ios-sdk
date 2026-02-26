import UIKit

/// Unity Ads adapter.
///
/// Add via Swift Package Manager:
///   https://github.com/Unity-Technologies/unity-ads-ios
///   Package: UnityAds, version ≥ 4.9.0
public final class PAUnityAdapter: NSObject, PAAdNetworkAdapter {
  public weak var delegate: PAAdNetworkDelegate?
  public private(set) var isInterstitialReady = false
  public private(set) var isRewardedReady = false

  private var gameId = ""
  private var interstitialPlacement = "Interstitial_iOS"
  private var rewardedPlacement = "Rewarded_iOS"
  private var bannerPlacement = "Banner_iOS"

  public func initialize(config: PANetworkConfig) {
    gameId = config["gameId"] ?? ""
    interstitialPlacement = config["interstitialPlacement"] ?? "Interstitial_iOS"
    rewardedPlacement = config["rewardedPlacement"] ?? "Rewarded_iOS"
    bannerPlacement = config["bannerPlacement"] ?? "Banner_iOS"
    // UnityAds.initialize(gameId, testMode: false, initializationDelegate: self)
    print("[PeerAds/Unity] Initialized gameId=\(gameId) — add unity-ads-ios via SPM to enable real ads")
  }

  public func loadBanner(adUnitId: String, size: CGSize, into container: UIView) {
    let placement = adUnitId.isEmpty ? bannerPlacement : adUnitId
    // let banner = UADSBannerView(placementId: placement, size: size)
    // banner.delegate = self; container.addSubview(banner); banner.load()

    let label = UILabel(frame: CGRect(origin: .zero, size: size))
    label.text = "Unity Banner (\(placement))"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 11)
    label.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1, alpha: 1)
    container.addSubview(label)
    delegate?.adNetworkDidLoadBanner(label, network: "unity")
  }

  public func loadInterstitial(adUnitId: String) {
    let placement = adUnitId.isEmpty ? interstitialPlacement : adUnitId
    // UnityAds.load(placement, options: UADSLoadOptions(), loadDelegate: self)
    isInterstitialReady = true
    delegate?.adNetworkDidLoadInterstitial(network: "unity")
  }

  public func showInterstitial(from viewController: UIViewController) {
    guard isInterstitialReady else { return }
    // UnityAds.show(viewController, placementId: interstitialPlacement, showDelegate: self)
    isInterstitialReady = false
  }

  public func loadRewarded(adUnitId: String) {
    let placement = adUnitId.isEmpty ? rewardedPlacement : adUnitId
    // UnityAds.load(placement, options: UADSLoadOptions(), loadDelegate: self)
    isRewardedReady = true
  }

  public func showRewarded(from viewController: UIViewController) {
    guard isRewardedReady else { return }
    // UnityAds.show(viewController, placementId: rewardedPlacement, showDelegate: self)
    // unityAdsShowComplete -> delegate?.adNetworkDidEarnReward
    delegate?.adNetworkDidEarnReward(type: "unity_reward", amount: 1, network: "unity")
    isRewardedReady = false
  }
}
