import Foundation
import UIKit

// MARK: - Environment

public enum PAEnvironment: String {
  case test       = "test"
  case production = "production"
}

// MARK: - Configuration

public struct PAConfig {
  /// Live public key: pk_live_... — embed in production app
  public let apiKey: String
  /// Live secret key: sk_live_... — server-side only, never ship in app bundle
  public let secretKey: String?
  /// Test public key: pk_test_... — embed in dev/staging
  public let testApiKey: String?
  /// Test secret key: sk_test_... — server-side only
  public let testSecretKey: String?
  /// .test → uses testApiKey and returns mock ads. Default: .production
  public let environment: PAEnvironment
  public let apiUrl: String
  public let peerPromotionPercent: Int
  public let testMode: Bool
  public let networks: [String: PANetworkConfig]

  public init(
    apiKey: String,
    secretKey: String? = nil,
    testApiKey: String? = nil,
    testSecretKey: String? = nil,
    environment: PAEnvironment = .production,
    apiUrl: String = "https://api.peerads.io/api/v1",
    peerPromotionPercent: Int = 90,
    testMode: Bool = false,
    networks: [String: PANetworkConfig] = [:]
  ) {
    self.apiKey = apiKey
    self.secretKey = secretKey
    self.testApiKey = testApiKey
    self.testSecretKey = testSecretKey
    self.environment = environment
    self.apiUrl = apiUrl
    self.peerPromotionPercent = peerPromotionPercent
    self.testMode = testMode
    self.networks = networks
  }

  /// The API key to use for ad requests based on the configured environment.
  var activeApiKey: String {
    if environment == .test {
      guard let k = testApiKey else {
        fatalError("[PeerAds] testApiKey required when environment is .test")
      }
      return k
    }
    return apiKey
  }

  /// The secret key to use for privileged server-to-server calls.
  var activeSecretKey: String? {
    environment == .test ? testSecretKey : secretKey
  }
}

// MARK: - Main SDK class

public class PeerAds {
  public static var shared: PeerAds?
  public private(set) var config: PAConfig
  public private(set) var adapterManager: PAAdapterManager?

  private init(config: PAConfig) { self.config = config }

  /// Initialize the SDK. Call in AppDelegate.didFinishLaunching.
  public static func initialize(config: PAConfig) {
    let instance = PeerAds(config: config)
    if !config.networks.isEmpty {
      let manager = PAAdapterManager()
      manager.initializeAll(networksConfig: config.networks)
      instance.adapterManager = manager
    }
    shared = instance
    if config.testMode || config.environment == .test {
      print("[PeerAds] Initialized (\(config.environment.rawValue)) | apiKey: \(config.activeApiKey)")
    }
  }

  // MARK: - Ad request

  public func requestAd(type: String, slotId: String) async throws -> PAAdResponse {
    guard let url = URL(string: "\(config.apiUrl)/ads/serve") else { throw PAError.invalidURL }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode([
      "apiKey": config.activeApiKey,
      "slotType": type,
      "platform": "ios"
    ])
    let (data, _) = try await URLSession.shared.data(for: request)
    let wrapper = try JSONDecoder().decode(PAAdResponseWrapper.self, from: data)
    return wrapper.ad
  }

  // MARK: - DAU reporting (server-to-server via secret key)

  /// Report your app's DAU. Call from your server-side code, not from the app bundle.
  public func reportDau(_ dau: Int) async throws {
    guard let sk = config.activeSecretKey else {
      throw PAError.missingSecretKey
    }
    guard let url = URL(string: "\(config.apiUrl)/apps/dau") else { throw PAError.invalidURL }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(sk, forHTTPHeaderField: "X-PeerAds-Secret-Key")
    request.httpBody = try JSONEncoder().encode(["dau": dau])
    _ = try await URLSession.shared.data(for: request)
  }

  // MARK: - Adapter helpers

  public func loadBanner(ad: PAAdResponse, size: CGSize = CGSize(width: 320, height: 50), into container: UIView) {
    guard ad.source == "self", let network = ad.network, !network.isEmpty else { return }
    adapterManager?.loadBanner(network: network, adUnitId: ad.adUnitId ?? "", size: size, into: container)
  }

  public func loadInterstitial(ad: PAAdResponse) {
    guard ad.source == "self", let network = ad.network, !network.isEmpty else { return }
    adapterManager?.loadInterstitial(network: network, adUnitId: ad.adUnitId ?? "")
  }

  public func showInterstitial(network: String, from vc: UIViewController) {
    adapterManager?.showInterstitial(network: network, from: vc)
  }

  public func loadRewarded(ad: PAAdResponse) {
    guard ad.source == "self", let network = ad.network, !network.isEmpty else { return }
    adapterManager?.loadRewarded(network: network, adUnitId: ad.adUnitId ?? "")
  }

  public func showRewarded(network: String, from vc: UIViewController) {
    adapterManager?.showRewarded(network: network, from: vc)
  }

  public func isInterstitialReady(network: String) -> Bool { adapterManager?.isInterstitialReady(network: network) ?? false }
  public func isRewardedReady(network: String) -> Bool { adapterManager?.isRewardedReady(network: network) ?? false }

  // MARK: - Tracking

  public func track(adId: String, event: String) {
    Task {
      guard let url = URL(string: "\(config.apiUrl)/ads/track") else { return }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try? JSONEncoder().encode(["adId": adId, "event": event])
      _ = try? await URLSession.shared.data(for: request)
    }
  }
}

// MARK: - Errors

public enum PAError: Error {
  case notInitialized
  case invalidURL
  case adLoadFailed(String)
  case missingSecretKey
}

// MARK: - Models

public struct PAAdResponse: Decodable {
  public let id: String
  public let type: String
  public let source: String
  public let network: String?
  public let adUnitId: String?
  public let creative: PACreative
  public let trackingUrl: String
  public let environment: String?
}

public struct PACreative: Decodable {
  public let title: String
  public let description: String?
  public let imageUrl: String?
  public let ctaText: String
  public let clickUrl: String
}

private struct PAAdResponseWrapper: Decodable {
  let ad: PAAdResponse
  let environment: String?
}
