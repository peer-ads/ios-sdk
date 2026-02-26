import UIKit

/// AdMob adapter — wraps Google Mobile Ads SDK.
///
/// Add via Swift Package Manager:
///   https://github.com/googleads/swift-package-manager-google-mobile-ads
///   Package: GoogleMobileAds, version ≥ 11.0.0
///
/// In Info.plist add:
///   GADApplicationIdentifier = ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
public final class PAAdMobAdapter: NSObject, PAAdNetworkAdapter {
  public weak var delegate: PAAdNetworkDelegate?
  public private(set) var isInterstitialReady = false
  public private(set) var isRewardedReady = false

  // Kept as Any to avoid compile errors when GoogleMobileAds is not linked
  private var bannerView: AnyObject?
  private var interstitialAd: AnyObject?
  private var rewardedAd: AnyObject?

  public func initialize(config: PANetworkConfig) {
    // GADMobileAds.sharedInstance().start(completionHandler: nil)
    print("[PeerAds/AdMob] Initialized — add GoogleMobileAds via SPM to enable real ads")
  }

  public func loadBanner(adUnitId: String, size: CGSize, into container: UIView) {
    // let banner = GADBannerView(adSize: GADAdSizeBanner)
    // banner.adUnitID = adUnitId
    // banner.rootViewController = container.window?.rootViewController
    // banner.delegate = self
    // container.addSubview(banner)
    // banner.load(GADRequest())
    // self.bannerView = banner

    // Placeholder label when SDK not linked
    let label = UILabel(frame: CGRect(origin: .zero, size: size))
    label.text = "AdMob Banner (\(adUnitId))"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 11)
    label.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1, alpha: 1)
    container.addSubview(label)
    delegate?.adNetworkDidLoadBanner(label, network: "admob")
  }

  public func loadInterstitial(adUnitId: String) {
    // GADInterstitialAd.load(withAdUnitID: adUnitId, request: GADRequest()) { ad, error in
    //   if let error { self.delegate?.adNetworkDidFailInterstitial(error: error, network: "admob"); return }
    //   self.interstitialAd = ad
    //   self.isInterstitialReady = true
    //   self.delegate?.adNetworkDidLoadInterstitial(network: "admob")
    // }
    isInterstitialReady = true
    delegate?.adNetworkDidLoadInterstitial(network: "admob")
  }

  public func showInterstitial(from viewController: UIViewController) {
    guard isInterstitialReady else { return }
    // (interstitialAd as? GADInterstitialAd)?.present(fromRootViewController: viewController)
    isInterstitialReady = false
  }

  public func loadRewarded(adUnitId: String) {
    // GADRewardedAd.load(withAdUnitID: adUnitId, request: GADRequest()) { ad, error in
    //   if let error { return }
    //   self.rewardedAd = ad
    //   self.isRewardedReady = true
    // }
    isRewardedReady = true
  }

  public func showRewarded(from viewController: UIViewController) {
    guard isRewardedReady else { return }
    // (rewardedAd as? GADRewardedAd)?.present(fromRootViewController: viewController) {
    //   let reward = self.rewardedAd?.adReward
    //   self.delegate?.adNetworkDidEarnReward(type: reward?.type ?? "", amount: Int(truncating: reward?.amount ?? 0), network: "admob")
    // }
    delegate?.adNetworkDidEarnReward(type: "coins", amount: 10, network: "admob")
    isRewardedReady = false
  }
}
