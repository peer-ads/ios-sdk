import UIKit

public enum PABannerSize {
    case standard      // 320x50
    case largeBanner   // 320x100
    case mediumRect    // 300x250

    var size: CGSize {
        switch self {
        case .standard:    return CGSize(width: 320, height: 50)
        case .largeBanner: return CGSize(width: 320, height: 100)
        case .mediumRect:  return CGSize(width: 300, height: 250)
        }
    }
}

public protocol PABannerViewDelegate: AnyObject {
    func bannerViewDidLoad(_ bannerView: PABannerView)
    func bannerViewDidFail(_ bannerView: PABannerView, error: Error)
    func bannerViewDidClick(_ bannerView: PABannerView)
}

public class PABannerView: UIView {
    public weak var delegate: PABannerViewDelegate?
    public let adSize: PABannerSize
    private var currentAd: PAAdResponse?

    public init(size: PABannerSize = .standard) {
        self.adSize = size
        super.init(frame: CGRect(origin: .zero, size: size.size))
        backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 1, alpha: 1)
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.88, green: 0.91, blue: 1, alpha: 1).cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    public func load() {
        guard let sdk = PeerAds.shared else {
            delegate?.bannerViewDidFail(self, error: PAError.notInitialized)
            return
        }
        Task { @MainActor in
            do {
                let ad = try await sdk.requestAd(type: "banner", slotId: "banner")
                self.currentAd = ad
                self.renderAd(ad)
                sdk.track(adId: ad.id, event: "impression")
                self.delegate?.bannerViewDidLoad(self)
            } catch {
                self.delegate?.bannerViewDidFail(self, error: error)
            }
        }
    }

    private func renderAd(_ ad: PAAdResponse) {
        subviews.forEach { $0.removeFromSuperview() }
        let label = UILabel()
        label.text = ad.creative.title
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 0.26, green: 0.21, blue: 0.79, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        guard let ad = currentAd else { return }
        PeerAds.shared?.track(adId: ad.id, event: "click")
        if let url = URL(string: ad.creative.clickUrl) {
            UIApplication.shared.open(url)
        }
        delegate?.bannerViewDidClick(self)
    }
}
