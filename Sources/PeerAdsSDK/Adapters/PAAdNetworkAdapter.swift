import UIKit

/// Config dictionary passed to each adapter on initialize.
public typealias PANetworkConfig = [String: String]

/// Delegate called after ad events.
public protocol PAAdNetworkDelegate: AnyObject {
  func adNetworkDidLoadBanner(_ view: UIView, network: String)
  func adNetworkDidFailBanner(error: Error, network: String)
  func adNetworkDidLoadInterstitial(network: String)
  func adNetworkDidFailInterstitial(error: Error, network: String)
  func adNetworkDidEarnReward(type: String, amount: Int, network: String)
}

/// Protocol every ad-network adapter must conform to.
public protocol PAAdNetworkAdapter: AnyObject {
  var delegate: PAAdNetworkDelegate? { get set }
  var isInterstitialReady: Bool { get }
  var isRewardedReady: Bool { get }

  /// Initialize the SDK — called once from PeerAds.initialize().
  func initialize(config: PANetworkConfig)

  /// Load a banner into the provided container view.
  func loadBanner(adUnitId: String, size: CGSize, into container: UIView)

  /// Pre-load an interstitial.
  func loadInterstitial(adUnitId: String)

  /// Present a pre-loaded interstitial from the given view controller.
  func showInterstitial(from viewController: UIViewController)

  /// Pre-load a rewarded ad.
  func loadRewarded(adUnitId: String)

  /// Present a pre-loaded rewarded ad.
  func showRewarded(from viewController: UIViewController)
}
