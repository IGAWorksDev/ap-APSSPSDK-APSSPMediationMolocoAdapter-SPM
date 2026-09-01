import UIKit
import APSSPSDK
import MolocoSDK

public final class MolocoRewardVideoAdapter: APSSPRewardVideoAdapterInappBiddingProtocol {
    public var delegate: APSSPRewardVideoAdapterDelegate?
    public var rootViewController: UIViewController?
    private var mediationAd: MolocoMediationRewardVideoAd?

    public init(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any?]) {
        let adUnitId = placementDic[APSSPPlacementKey.molocoAdUnitId.rawValue] ?? ""
        self.mediationAd = MolocoMediationRewardVideoAd(adUnitId: adUnitId)
        self.rootViewController = rootViewController
    }

    public init(inappbiddingPlacementDic: [String: String], rootViewController: UIViewController?) {
        let adUnitId = inappbiddingPlacementDic[APSSPBiddingKey.molocoPlacementId.rawValue] ?? ""
        let biddingData = inappbiddingPlacementDic[APSSPBiddingKey.biddingData.rawValue]
        self.mediationAd = MolocoMediationRewardVideoAd(adUnitId: adUnitId, biddingData: biddingData)
        self.rootViewController = rootViewController
    }

    @MainActor public func connectDelegate(delegate: APSSPRewardVideoAdapterDelegate) {
        self.delegate = delegate
        mediationAd?.delegate = self
        mediationAd?.load()
    }

    public func disconnectDelegate() { mediationAd?.delegate = nil; delegate = nil }

    @MainActor public func present(from: UIViewController, completion: @escaping () -> Void) {
        mediationAd?.present(from: from) { completion() }
    }

    public func getBiddingToken() -> String { mediationAd?.getBiddingToken() ?? "" }
}

extension MolocoRewardVideoAdapter: APSSPRewardVideoAdapterDelegate {
    public func rewardVideoLoadSuccess() { delegate?.rewardVideoLoadSuccess() }
    public func rewardVideoLoadFail(error: APSSPNetworkError, errorMessage: String?) { delegate?.rewardVideoLoadFail(error: error, errorMessage: errorMessage) }
    public func rewardVideoShowSuccess(message: String) { delegate?.rewardVideoShowSuccess(message: message) }
    public func rewardVideoShowFail(message: String) { delegate?.rewardVideoShowFail(message: message) }
    public func rewardVideoClosed(message: String) { delegate?.rewardVideoClosed(message: message) }
    public func rewardVideoClicked(message: String) { delegate?.rewardVideoClicked(message: message) }
    public func rewardVideoCompleted() { delegate?.rewardVideoCompleted() }
}
