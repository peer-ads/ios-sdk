// PeerAds iOS SDK — Demo App
//
// Single-file SwiftUI demo that covers:
//   • SDK initialisation
//   • Banner ads (UIViewRepresentable wrapper around PABannerView)
//   • Interstitial ads
//   • Rewarded ads
//   • DAU reporting
//   • Manual ad request + event tracking
//
// How to use:
//   1. Create a new Xcode project (SwiftUI, iOS 16+)
//   2. Add this package via File ▸ Add Packages:
//      https://github.com/peerads/peerads-ios
//   3. Replace this file (or merge with ContentView.swift)
//   4. Replace "pk_test_REPLACE_ME" with your test API key

import SwiftUI
import PeerAdsSDK

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------
@main
struct PeerAdsDemoApp: App {
    init() {
        // 1. Initialise the SDK — do this as early as possible
        PeerAds.initialize(config: PAConfig(
            apiKey: "pk_test_REPLACE_ME",   // ← replace with your test key
            environment: .test,
            testMode: true,
            peerPromotionPercent: 90
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// ---------------------------------------------------------------------------
// Root navigation
// ---------------------------------------------------------------------------
struct ContentView: View {
    var body: some View {
        TabView {
            BannerDemoView()
                .tabItem { Label("Banner",       systemImage: "rectangle.on.rectangle") }

            InterstitialDemoView()
                .tabItem { Label("Interstitial", systemImage: "rectangle.fill.on.rectangle.fill") }

            RewardedDemoView()
                .tabItem { Label("Rewarded",     systemImage: "gift") }

            InfoView()
                .tabItem { Label("Info",         systemImage: "info.circle") }
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
struct LogEntry: Identifiable {
    let id  = UUID()
    enum Level { case ok, err, info }
    let level: Level
    let msg:   String
}

@MainActor
class LogModel: ObservableObject {
    @Published var entries: [LogEntry] = []
    func add(_ level: LogEntry.Level, _ msg: String) {
        entries.insert(LogEntry(level: level, msg: msg), at: 0)
        if entries.count > 30 { entries.removeLast() }
    }
}

struct LogView: View {
    @ObservedObject var model: LogModel
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 3) {
                ForEach(model.entries) { e in
                    Text(e.msg)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(e.level == .ok  ? Color(hex: "#34D399") :
                                         e.level == .err ? Color(hex: "#F87171") :
                                                           Color(hex: "#94A3B8"))
                }
            }
            .padding(12)
        }
        .background(Color(hex: "#0F172A"))
        .cornerRadius(10)
    }
}

// ---------------------------------------------------------------------------
// UIViewRepresentable — PABannerView wrapper for SwiftUI
// ---------------------------------------------------------------------------
struct PABannerViewRepresentable: UIViewRepresentable {
    var size: PABannerSize = .standard
    var onLoad:    (() -> Void)?  = nil
    var onFail:    ((Error) -> Void)? = nil
    var onClick:   (() -> Void)?  = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PABannerView {
        let view = PABannerView(size: size)
        view.delegate = context.coordinator
        view.load()
        return view
    }
    func updateUIView(_ uiView: PABannerView, context: Context) {}

    class Coordinator: NSObject, PABannerViewDelegate {
        let parent: PABannerViewRepresentable
        init(_ parent: PABannerViewRepresentable) { self.parent = parent }
        func bannerViewDidLoad(_ bannerView: PABannerView)              { parent.onLoad?() }
        func bannerViewDidFail(_ bannerView: PABannerView, error: Error){ parent.onFail?(error) }
        func bannerViewDidClick(_ bannerView: PABannerView)             { parent.onClick?() }
    }
}

// ---------------------------------------------------------------------------
// Banner Demo
// ---------------------------------------------------------------------------
struct BannerDemoView: View {
    @StateObject private var log = LogModel()
    @State private var bannerSize: PABannerSize = .standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Size picker
                Picker("Size", selection: $bannerSize) {
                    Text("320×50").tag(PABannerSize.standard)
                    Text("320×100").tag(PABannerSize.largeBanner)
                    Text("300×250").tag(PABannerSize.mediumRect)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Banner
                PABannerViewRepresentable(
                    size: bannerSize,
                    onLoad:  { log.add(.ok,   "Banner loaded (\(bannerSize))") },
                    onFail:  { log.add(.err,  "Banner error: \($0)") },
                    onClick: { log.add(.info, "Banner clicked") }
                )
                .frame(
                    width:  bannerSize == .mediumRect ? 300 : 320,
                    height: bannerSize == .standard   ? 50 :
                            bannerSize == .largeBanner ? 100 : 250
                )
                .border(Color.secondary.opacity(0.3))

                LogView(model: log)
                    .frame(maxHeight: 220)
                    .padding(.horizontal)
            }
            .navigationTitle("Banner Ad")
        }
    }
}

// ---------------------------------------------------------------------------
// Interstitial Demo
// ---------------------------------------------------------------------------
struct InterstitialDemoView: View {
    @StateObject private var log = LogModel()
    @State private var loadedAd: PAAdResponse?
    @State private var loading = false

    private var sdk: PeerAds? { PeerAds.shared }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(
                    "Interstitial ads cover the full screen. Preload during idle time, "
                    + "then show at a natural break point."
                )
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                Button(action: preload) {
                    Label(loading ? "Loading…" : "Preload Interstitial", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading)
                .padding(.horizontal)

                Button(action: show) {
                    Label("Show Interstitial", systemImage: "play.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(loadedAd == nil)
                .padding(.horizontal)

                LogView(model: log)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Interstitial Ad")
        }
    }

    private func preload() {
        guard let sdk else { log.add(.err, "SDK not initialised"); return }
        loading = true
        Task {
            do {
                let ad = try await sdk.requestAd(type: "interstitial", slotId: "slot-001")
                sdk.loadInterstitial(ad: ad)
                loadedAd = ad
                log.add(.ok, "Interstitial ready  source=\(ad.source)")
            } catch {
                log.add(.err, "Preload failed: \(error.localizedDescription)")
            }
            loading = false
        }
    }

    private func show() {
        guard let sdk, let ad = loadedAd else { return }
        guard let vc = UIApplication.shared.topViewController() else { return }
        sdk.showInterstitial(network: ad.network ?? "self", from: vc)
        log.add(.info, "Interstitial shown")
        loadedAd = nil
    }
}

// ---------------------------------------------------------------------------
// Rewarded Demo
// ---------------------------------------------------------------------------
struct RewardedDemoView: View {
    @StateObject private var log = LogModel()
    @State private var coins   = 0
    @State private var loading = false

    private var sdk: PeerAds? { PeerAds.shared }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Coin counter
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("\(coins) coins")
                        .font(.title).bold()
                }
                .padding()
                .background(Color(hex: "#0F172A"))
                .cornerRadius(12)

                Text("Watch a full rewarded ad to earn coins.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Button(action: watchAd) {
                    Label(loading ? "Loading…" : "Watch Rewarded Ad (+10 coins)",
                          systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(loading)
                .padding(.horizontal)

                LogView(model: log)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Rewarded Ad")
        }
    }

    private func watchAd() {
        guard let sdk else { log.add(.err, "SDK not initialised"); return }
        loading = true
        Task {
            do {
                let ad = try await sdk.requestAd(type: "rewarded", slotId: "slot-002")
                sdk.loadRewarded(ad: ad)
                log.add(.ok, "Rewarded loaded  source=\(ad.source)")
                guard let vc = UIApplication.shared.topViewController() else { return }
                sdk.showRewarded(network: ad.network ?? "self", from: vc)
                // Simulate reward callback (real SDK fires this after completion)
                await MainActor.run {
                    coins += 10
                    log.add(.ok, "Reward granted: +10 coins (total: \(coins))")
                }
            } catch {
                log.add(.err, "Error: \(error.localizedDescription)")
            }
            loading = false
        }
    }
}

// ---------------------------------------------------------------------------
// Info / DAU Demo
// ---------------------------------------------------------------------------
struct InfoView: View {
    @StateObject private var log = LogModel()
    @State private var dauReported = false

    private var sdk: PeerAds? { PeerAds.shared }

    var body: some View {
        NavigationStack {
            List {
                Section("SDK Status") {
                    LabeledContent("Version",     value: "0.1.0")
                    LabeledContent("Environment", value: PeerAds.shared != nil ? "test" : "—")
                    LabeledContent("Peer %",      value: "90%")
                }

                Section("DAU Reporting") {
                    Button(dauReported ? "DAU Reported ✓" : "Report DAU (5 000)") {
                        Task {
                            do {
                                try await sdk?.reportDau(5000)
                                dauReported = true
                                log.add(.ok, "DAU reported: 5 000")
                            } catch {
                                log.add(.err, "DAU error: \(error)")
                            }
                        }
                    }
                    .disabled(dauReported)
                }

                Section("Manual Ad Request") {
                    Button("Request Banner (slot-001)") {
                        Task {
                            do {
                                let ad = try await sdk!.requestAd(type: "banner", slotId: "slot-001")
                                log.add(.ok, "source=\(ad.source)  network=\(ad.network ?? "self")")
                                sdk?.track(adId: ad.id, event: "impression")
                                log.add(.info, "Impression tracked")
                            } catch {
                                log.add(.err, "\(error)")
                            }
                        }
                    }
                }

                Section("Event Log") {
                    LogView(model: log)
                        .frame(minHeight: 200)
                        .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Info")
        }
    }
}

// ---------------------------------------------------------------------------
// Extensions
// ---------------------------------------------------------------------------
extension UIApplication {
    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        if let nav = root as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = root as? UITabBarController     { return topViewController(base: tab.selectedViewController) }
        if let presented = root?.presentedViewController { return topViewController(base: presented) }
        return root
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
