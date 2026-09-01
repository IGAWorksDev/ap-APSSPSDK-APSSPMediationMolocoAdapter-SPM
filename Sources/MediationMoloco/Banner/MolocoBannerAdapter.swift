import UIKit
import APSSPSDK
import MolocoSDK

public final class MolocoBannerAdapter: APSSPBannerAdapterInappBiddingProtocol {
    private let bannerView: MolocoMediationBannerView
    weak public var delegate: APSSPBannerAdapterDelegate?
    weak public var rootViewController: UIViewController?

    public init(placementDic: [String: String], bannerType: APSSPBannerSize, rootViewController: UIViewController?, info: [String: Any?]) {
        let adUnitId = placementDic[APSSPPlacementKey.molocoAdUnitId.rawValue] ?? ""
        self.bannerView = MolocoMediationBannerView(adUnitId: adUnitId, bannerType: bannerType, rootViewController: rootViewController)
        self.rootViewController = rootViewController
        bannerView.delegate = self
    }

    public init(inappbiddingPlacementDic: [String: String], bannerType: APSSPBannerSize, rootViewController: UIViewController?) {
        let adUnitId = inappbiddingPlacementDic[APSSPBiddingKey.molocoPlacementId.rawValue] ?? ""
        let biddingData = inappbiddingPlacementDic[APSSPBiddingKey.biddingData.rawValue] ?? ""
        self.bannerView = MolocoMediationBannerView(adUnitId: adUnitId, bannerType: bannerType, rootViewController: rootViewController, biddingData: biddingData)
        self.rootViewController = rootViewController
        bannerView.delegate = self
    }

    public func connectDelegate(delegate: APSSPBannerAdapterDelegate) {
        self.delegate = delegate
        bannerView.load()
    }

    public func disconnectDelegate() { bannerView.delegate = nil; delegate = nil }
    public func stop() { bannerView.stop() }
    public func getBiddingToken() -> String { return bannerView.getBiddingToken() }
}

extension MolocoBannerAdapter: APSSPBannerAdapterDelegate {
    public func bannerViewSuccess(bannerView: UIView) { delegate?.bannerViewSuccess(bannerView: bannerView) }
    public func bannerViewFailed(bannerView: UIView, error: APSSPNetworkError, errorMessage: String?) { delegate?.bannerViewFailed(bannerView: UIView(), error: .nextMediation, errorMessage: errorMessage) }
    public func bannerViewClicked(message: String) { delegate?.bannerViewClicked(message: message) }
    public func bannerViewImpression(message: String) { delegate?.bannerViewImpression(message: message) }
}
