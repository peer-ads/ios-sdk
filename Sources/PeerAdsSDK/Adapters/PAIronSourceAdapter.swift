import UIKit

/// IronSource adapter.
///
/// IronSource distributes their iOS SDK as a binary XCFramework.
/// Download from: https://developers.is.com/ironsource-mobile/ios/ios-sdk/
/// Or via CocoaPods: pod 'IronSourceSDK', '~> 7.5'
///
/// Swift Package Manager support: https://github.com/ironsource-mobile/IronSource-iOS-AdaptersSPM
public final class PAIronSourceAdapter: NSObject, PAAdNetworkAdapter {
  public weak var delegate: PAAdNetworkDelegate?
  public private(set) var isInterstitialReady = false
  public private(set) var isRewardedReady = false

  private var appKey = ""

  public func initialize(config: PANetworkConfig) {
    appKey = config["appKey"] ?? ""
    // IronSource.setAdaptersDebug(false)
    // IronSource.initWithAppKey(appKey, adUnits: [IS_INTERSTITIAL, IS_REWARDED_VIDEO, IS_BANNER])
    print("[PeerAds/IronSource] Initialized appKey=*** — add IronSourceSDK to enable real ads")
  }

  public func loadBanner(adUnitId: String, size: CGSize, into container: UIView) {
    // IronSource.loadBanner(with: viewController, size: ISBannerSize(description: "BANNER"), placement: nil)
    let label = UILabel(frame: CGRect(origin: .zero, size: size))
    label.text = "IronSource Banner"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 11)
    label.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1, alpha: 1)
    container.addSubview(label)
    delegate?.adNetworkDidLoadBanner(label, network: "ironsource")
  }

  public func loadInterstitial(adUnitId: String) {
    // IronSource.loadInterstitial()
    // ISInterstitialDelegate.interstitialDidLoad() -> isInterstitialReady = true
    isInterstitialReady = true
    delegate?.adNetworkDidLoadInterstitial(network: "ironsource")
  }

  public func showInterstitial(from viewController: UIViewController) {
    guard isInterstitialReady else { return }
    // IronSource.showInterstitial(with: viewController)
    isInterstitialReady = false
  }

  public func loadRewarded(adUnitId: String) {
    // IronSource.loadRewardedVideo() — or check IronSource.isRewardedVideoAvailable()
    isRewardedReady = true
  }

  public func showRewarded(from viewController: UIViewController) {
    guard isRewardedReady else { return }
    // IronSource.showRewardedVideo(with: viewController)
    // ISRewardedVideoDelegate.didReceiveReward(forPlacement:) -> delegate?.adNetworkDidEarnReward
    delegate?.adNetworkDidEarnReward(type: "coins", amount: 0, network: "ironsource")
    isRewardedReady = false
  }
}
