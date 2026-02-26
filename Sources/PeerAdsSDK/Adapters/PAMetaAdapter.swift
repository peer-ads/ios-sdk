import UIKit

/// Meta Audience Network adapter.
///
/// Add via CocoaPods (SPM not officially supported):
///   pod 'FBAudienceNetwork', '~> 6.15'
///
/// Or use Meta's XCFramework directly from:
///   https://developers.facebook.com/docs/audience-network/setting-up/platform-setup/ios/add-sdk
public final class PAMetaAdapter: NSObject, PAAdNetworkAdapter {
  public weak var delegate: PAAdNetworkDelegate?
  public private(set) var isInterstitialReady = false
  public private(set) var isRewardedReady = false

  private var placementId = ""
  private var interstitialAd: AnyObject?
  private var rewardedAd: AnyObject?

  public func initialize(config: PANetworkConfig) {
    placementId = config["placementId"] ?? ""
    // FBAudienceNetworkAds.initialize(settings: nil, completionHandler: nil)
    print("[PeerAds/Meta] Initialized placementId=\(placementId) — add FBAudienceNetwork to enable real ads")
  }

  public func loadBanner(adUnitId: String, size: CGSize, into container: UIView) {
    let pid = adUnitId.isEmpty ? placementId : adUnitId
    // let banner = FBAdView(placementID: pid, adSize: kFBAdSize320x50, rootViewController: vc)
    // banner.delegate = self; banner.loadAd(); container.addSubview(banner)

    let label = UILabel(frame: CGRect(origin: .zero, size: size))
    label.text = "Meta Banner (\(pid))"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 11)
    label.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1, alpha: 1)
    container.addSubview(label)
    delegate?.adNetworkDidLoadBanner(label, network: "meta")
  }

  public func loadInterstitial(adUnitId: String) {
    let pid = adUnitId.isEmpty ? placementId : adUnitId
    // interstitialAd = FBInterstitialAd(placementID: pid)
    // (interstitialAd as? FBInterstitialAd)?.delegate = self
    // (interstitialAd as? FBInterstitialAd)?.loadAd()
    isInterstitialReady = true
    delegate?.adNetworkDidLoadInterstitial(network: "meta")
  }

  public func showInterstitial(from viewController: UIViewController) {
    guard isInterstitialReady else { return }
    // (interstitialAd as? FBInterstitialAd)?.show(fromRootViewController: viewController)
    isInterstitialReady = false
  }

  public func loadRewarded(adUnitId: String) {
    let pid = adUnitId.isEmpty ? placementId : adUnitId
    // rewardedAd = FBRewardedVideoAd(placementID: pid)
    // (rewardedAd as? FBRewardedVideoAd)?.delegate = self; (rewardedAd as? FBRewardedVideoAd)?.loadAd()
    isRewardedReady = true
  }

  public func showRewarded(from viewController: UIViewController) {
    guard isRewardedReady else { return }
    // (rewardedAd as? FBRewardedVideoAd)?.show(fromRootViewController: viewController)
    delegate?.adNetworkDidEarnReward(type: "meta_reward", amount: 1, network: "meta")
    isRewardedReady = false
  }
}
