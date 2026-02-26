import UIKit
import WebKit

// MARK: - PAReward

/// The reward granted after a successful rewarded-ad view.
public struct PAReward {
    public let type:   String
    public let amount: Int
}

// MARK: - PARewardedAdViewController

/// Full-screen rewarded-ad view controller — renders the shared HTML page
/// in a `WKWebView`.
///
/// The WKWebView bridge (`window.webkit.messageHandlers.peerads`) receives
/// events from the page and dispatches them to the public callbacks.
///
/// Timer pause/resume is handled automatically inside the HTML via
/// `document.visibilitychange`. The VC also calls `window.PAAd.pause/resume()`
/// from `viewWillDisappear` / `viewWillAppear` as a safety net.
///
/// Usage:
/// ```swift
/// let vc = PARewardedAdViewController(ad: ad, duration: 30)
/// vc.onRewardAvailable = { reward in /* pre-unlock */ }
/// vc.onRewardEarned    = { reward in coins += reward.amount }
/// vc.onAdClosed        = { }
/// present(vc, animated: true)
/// ```
public final class PARewardedAdViewController: UIViewController {

    // MARK: - Public callbacks

    /// Fired when the user finishes watching — they are now eligible.
    public var onRewardAvailable: ((PAReward) -> Void)?
    /// Fired when the user taps "Claim Reward".
    public var onRewardEarned: ((PAReward) -> Void)?
    /// Fired after the view controller is dismissed.
    public var onAdClosed: (() -> Void)?

    // MARK: - Private

    private let ad:            PAAdResponse
    private let totalDuration: Int
    private var webView:       WKWebView!
    private var eligible       = false

    // MARK: - Init

    /// - Parameters:
    ///   - ad:       The `PAAdResponse` returned by `PeerAds.shared?.requestAd(...)`.
    ///   - duration: Seconds the user must watch before becoming eligible. Defaults to 30.
    public init(ad: PAAdResponse, duration: Int = 30) {
        self.ad            = ad
        self.totalDuration = duration
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle   = .coverVertical
        isModalInPresentation  = true   // blocks swipe-to-dismiss (iOS 13+)
    }

    required init?(coder: NSCoder) { fatalError("Use init(ad:duration:)") }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadAdPage()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Extra safety net — visibilitychange handles this inside the HTML too
        webView.evaluateJavaScript("window.PAAd&&window.PAAd.pause();", completionHandler: nil)
        if isBeingDismissed { onAdClosed?() }
    }

    public override var prefersStatusBarHidden: Bool { true }

    // MARK: - WebView setup

    private func setupWebView() {
        let config  = WKWebViewConfiguration()
        // Register bridge — handler name "peerads" → webkit.messageHandlers.peerads
        config.userContentController.add(PAMessageHandler(vc: self), name: "peerads")

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask    = [.flexibleWidth, .flexibleHeight]
        webView.isOpaque            = false
        webView.backgroundColor     = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1)
        webView.scrollView.isScrollEnabled = false
        view.addSubview(webView)
    }

    private func loadAdPage() {
        let html = buildRewardedAdHtml(
            adId:        ad.id,
            title:       ad.creative.title,
            description: ad.creative.description ?? "",
            imageUrl:    ad.creative.imageUrl    ?? "",
            duration:    totalDuration
        )
        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - Bridge event dispatch (called by PAMessageHandler)

    fileprivate func handleBridgeEvent(_ event: String, data: [String: Any]) {
        switch event {
        case "impression":
            PeerAds.shared?.track(adId: ad.id, event: "impression")

        case "rewardAvailable":
            eligible = true
            isModalInPresentation = false   // allow swipe-to-dismiss now
            let reward = PAReward(
                type:   data["type"]   as? String ?? "coins",
                amount: data["amount"] as? Int    ?? 10
            )
            onRewardAvailable?(reward)

        case "rewardEarned":
            PeerAds.shared?.track(adId: ad.id, event: "complete")
            let reward = PAReward(
                type:   data["type"]   as? String ?? "coins",
                amount: data["amount"] as? Int    ?? 10
            )
            onRewardEarned?(reward)

        case "closed":
            dismiss(animated: true)

        default:
            break
        }
    }
}

// MARK: - WKScriptMessageHandler

private final class PAMessageHandler: NSObject, WKScriptMessageHandler {
    weak var vc: PARewardedAdViewController?
    init(vc: PARewardedAdViewController) { self.vc = vc }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            let body  = message.body as? [String: Any],
            let event = body["event"] as? String
        else { return }
        let data = body["data"] as? [String: Any] ?? [:]
        DispatchQueue.main.async { self.vc?.handleBridgeEvent(event, data: data) }
    }
}
