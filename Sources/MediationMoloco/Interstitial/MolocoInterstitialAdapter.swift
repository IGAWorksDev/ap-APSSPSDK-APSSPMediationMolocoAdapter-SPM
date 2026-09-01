import UIKit
import APSSPSDK
import MolocoSDK

public final class MolocoInterstitialAdapter: APSSPInterstitialAdapterInappBiddingProtocol {
    public var rootViewController: UIViewController?
    public var delegate: APSSPInterstitialAdapterDelegate?
    private var mediationAd: MolocoMediationInterstitialAd?

    public init(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any?]) {
        let adUnitId = placementDic[APSSPPlacementKey.molocoAdUnitId.rawValue] ?? ""
        self.mediationAd = MolocoMediationInterstitialAd(adUnitId: adUnitId)
        self.rootViewController = rootViewController
    }

    public init(inappbiddingPlacementDic: [String: String], rootViewController: UIViewController?) {
        let adUnitId = inappbiddingPlacementDic[APSSPBiddingKey.molocoPlacementId.rawValue] ?? ""
        let biddingData = inappbiddingPlacementDic[APSSPBiddingKey.biddingData.rawValue]
        self.mediationAd = MolocoMediationInterstitialAd(adUnitId: adUnitId, biddingData: biddingData)
        self.rootViewController = rootViewController
    }

    @MainActor public func connectDelegate(delegate: APSSPInterstitialAdapterDelegate) {
        self.delegate = delegate
        mediationAd?.delegate = self
        mediationAd?.load()
    }

    public func disconnectDelegate() { mediationAd?.delegate = nil; delegate = nil }

    @MainActor public func present(from: UIViewController, completion: () -> Void) {
        mediationAd?.present(from: from) { completion() }
    }

    public func getBiddingToken() -> String { mediationAd?.getBiddingToken() ?? "" }
}

extension MolocoInterstitialAdapter: APSSPInterstitialAdapterDelegate {
    public func interstitialLoadSuccess() { delegate?.interstitialLoadSuccess() }
    public func interstitialLoadFail(error: APSSPNetworkError, errorMessage: String?) { delegate?.interstitialLoadFail(error: error, errorMessage: errorMessage) }
    public func interstitialShowSuccess(message: String) { delegate?.interstitialShowSuccess(message: message) }
    public func interstitialShowFail(message: String) { delegate?.interstitialShowFail(message: message) }
    public func interstitialClosed(message: String) { delegate?.interstitialClosed(message: message) }
    public func interstitialClicked(message: String) { delegate?.interstitialClicked(message: message) }
}
