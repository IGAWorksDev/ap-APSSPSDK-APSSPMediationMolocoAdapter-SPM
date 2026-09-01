import UIKit
import APSSPSDK
import MolocoSDK

final class MolocoMediationBannerView: UIView {
    weak var delegate: APSSPBannerAdapterDelegate?
    private var bannerAd: MolocoBannerAdView?
    private let adUnitId: String
    private let bannerType: APSSPBannerSize
    private weak var rootViewController: UIViewController?
    private var biddingData: String?

    init(adUnitId: String, bannerType: APSSPBannerSize, rootViewController: UIViewController?, biddingData: String? = nil) {
        self.adUnitId = adUnitId
        self.bannerType = bannerType
        self.rootViewController = rootViewController
        self.biddingData = biddingData
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func load() {
        guard !adUnitId.isEmpty else {
            APLogger.error("Moloco Banner adUnitId is empty")
            delegate?.bannerViewFailed(bannerView: self, error: .nextMediation, errorMessage: "adUnitId is empty")
            return
        }
        
        guard let rootViewController else {
            delegate?.bannerViewFailed(bannerView: self, error: .nextMediation, errorMessage: "rootViewController is nil")
            return
        }
        let params = MolocoCreateAdParams(adUnit: adUnitId, mediation: "AdPopcornSSP")
        if bannerType == .banner300x250 {
            bannerAd = Moloco.shared.createMREC(params: params, viewController: rootViewController)
        } else {
            bannerAd = Moloco.shared.createBanner(params: params, viewController: rootViewController)
        }
        bannerAd?.delegate = self
        bannerAd?.load(bidResponse: biddingData ?? "")
    }

    func stop() {
        bannerAd?.delegate = nil
        bannerAd?.destroy()
        bannerAd?.removeFromSuperview()
        bannerAd = nil
    }

    func getBiddingToken() -> String {
        var token = ""
        let semaphore = DispatchSemaphore(value: 0)
        let params = MolocoParams(mediation: "AdPopcornSSP")
        Moloco.shared.getBidToken(params: params) { bidToken, _ in
            token = bidToken ?? ""
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 3)
        return token
    }
}

extension MolocoMediationBannerView: MolocoBannerDelegate {
    func didLoad(ad: any MolocoAd) {
        if let bannerAd { delegate?.bannerViewSuccess(bannerView: bannerAd) }
    }

    func failToLoad(ad: any MolocoAd, with error: Error?) {
        delegate?.bannerViewFailed(bannerView: self, error: .nextMediation, errorMessage: error?.localizedDescription)
    }

    func didClick(on ad: any MolocoAd) {
        delegate?.bannerViewClicked(message: "Moloco Banner clicked")
    }

    func didShow(ad: any MolocoAd) {
        delegate?.bannerViewImpression(message: "Moloco Banner Impression")
    }
    func failToShow(ad: any MolocoAd, with error: Error?) { }
    func didHide(ad: any MolocoAd) { }
}
