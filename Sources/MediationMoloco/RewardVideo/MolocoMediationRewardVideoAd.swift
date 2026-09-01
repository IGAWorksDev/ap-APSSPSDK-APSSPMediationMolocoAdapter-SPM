import UIKit
import APSSPSDK
import MolocoSDK

final class MolocoMediationRewardVideoAd: NSObject {
    var delegate: APSSPRewardVideoAdapterDelegate?
    private var rewardedAd: (any MolocoRewardedInterstitial)?
    private let adUnitId: String
    private var biddingData: String?

    init(adUnitId: String, biddingData: String? = nil) {
        self.adUnitId = adUnitId
        self.biddingData = biddingData
    }

    @MainActor func load() {
        guard !adUnitId.isEmpty else {
            APLogger.error("Moloco RewardVideo adUnitId is empty")
            delegate?.rewardVideoLoadFail(error: .nextMediation, errorMessage: "adUnitId is empty")
            return
        }
        
        let params = MolocoCreateAdParams(adUnit: adUnitId, mediation: "AdPopcornSSP")
        rewardedAd = Moloco.shared.createRewarded(params: params)
        rewardedAd?.rewardedDelegate = self
        rewardedAd?.load(bidResponse: biddingData ?? "")
    }

    @MainActor func present(from: UIViewController, completion: @escaping () -> Void) {
        rewardedAd?.show(from: from)
        completion()
    }

    func getBiddingToken() -> String {
        var token = ""
        let semaphore = DispatchSemaphore(value: 0)
        Moloco.shared.getBidToken(params: MolocoParams(mediation: "AdPopcornSSP")) { bidToken, _ in
            token = bidToken ?? ""; semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 3)
        return token
    }
}

extension MolocoMediationRewardVideoAd: MolocoRewardedDelegate {
    
    func didLoad(ad: any MolocoAd) { delegate?.rewardVideoLoadSuccess() }
    func failToLoad(ad: any MolocoAd, with error: Error?) { delegate?.rewardVideoLoadFail(error: .nextMediation, errorMessage: error?.localizedDescription) }
    func didShow(ad: any MolocoAd) { delegate?.rewardVideoShowSuccess(message: "Moloco RV show") }
    func failToShow(ad: any MolocoAd, with error: Error?) { delegate?.rewardVideoShowFail(message: error?.localizedDescription ?? "Moloco RV show fail") }
    func didHide(ad: any MolocoAd) { delegate?.rewardVideoClosed(message: "Moloco RV closed") }
    func didClick(on ad: any MolocoAd) { delegate?.rewardVideoClicked(message: "Moloco RV clicked") }
    func userRewarded(ad: any MolocoAd) { }
    func rewardedVideoStarted(ad: any MolocoAd) { }
    func rewardedVideoCompleted(ad: any MolocoAd) {delegate?.rewardVideoCompleted() }
}
