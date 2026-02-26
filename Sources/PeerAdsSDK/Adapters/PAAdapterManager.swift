import UIKit

/// Routes ad rendering to the correct third-party adapter based on the
/// `network` string from PeerAds server when `source == "self"`.
public final class PAAdapterManager {
  public weak var delegate: PAAdNetworkDelegate?
  private var adapters: [String: PAAdNetworkAdapter] = [:]

  private func getOrCreate(_ network: String) -> PAAdNetworkAdapter {
    if let existing = adapters[network] { return existing }
    let adapter: PAAdNetworkAdapter
    switch network {
    case "admob":      adapter = PAAdMobAdapter()
    case "meta":       adapter = PAMetaAdapter()
    case "applovin":   adapter = PAAppLovinAdapter()
    case "unity":      adapter = PAUnityAdapter()
    case "ironsource": adapter = PAIronSourceAdapter()
    default:           adapter = PAAdMobAdapter()
    }
    adapter.delegate = delegate
    adapters[network] = adapter
    return adapter
  }

  public func initializeAll(networksConfig: [String: PANetworkConfig]) {
    for (name, config) in networksConfig {
      getOrCreate(name).initialize(config: config)
    }
  }

  public func loadBanner(network: String, adUnitId: String, size: CGSize, into container: UIView) {
    getOrCreate(network).loadBanner(adUnitId: adUnitId, size: size, into: container)
  }

  public func loadInterstitial(network: String, adUnitId: String) {
    getOrCreate(network).loadInterstitial(adUnitId: adUnitId)
  }

  public func showInterstitial(network: String, from viewController: UIViewController) {
    getOrCreate(network).showInterstitial(from: viewController)
  }

  public func loadRewarded(network: String, adUnitId: String) {
    getOrCreate(network).loadRewarded(adUnitId: adUnitId)
  }

  public func showRewarded(network: String, from viewController: UIViewController) {
    getOrCreate(network).showRewarded(from: viewController)
  }

  public func isInterstitialReady(network: String) -> Bool {
    adapters[network]?.isInterstitialReady ?? false
  }

  public func isRewardedReady(network: String) -> Bool {
    adapters[network]?.isRewardedReady ?? false
  }
}
