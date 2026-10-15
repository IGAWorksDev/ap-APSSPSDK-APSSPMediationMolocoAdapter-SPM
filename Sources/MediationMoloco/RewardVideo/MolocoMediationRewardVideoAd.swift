import UIKit
import APSSPSDK
import MolocoSDK

final class MolocoMediationRewardVideoAd: NSObject {
    weak var delegate: APSSPRewardVideoAdapterDelegate?
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
    /// 리워드 지급 시점. **완료 통보는 이 콜백을 기준으로 한다.**
    ///
    /// Moloco 는 `rewardedVideoCompleted` 를 호출하지 않는 경우가 있어
    /// 그쪽에 걸어두면 완료 트래킹(`/tracker/video/reward/cs` isCompleted=true)과
    /// 매체 리워드 지급 콜백이 모두 누락된다.
    /// AOS(`MolocoAdapter.onUserRewarded`)도 동일하게 이 콜백에서 완료를 통보한다.
    func userRewarded(ad: any MolocoAd) {
        APLogger.debug("Moloco RewardVideo userRewarded")
        delegate?.rewardVideoCompleted()
    }

    func rewardedVideoStarted(ad: any MolocoAd) {
        APLogger.debug("Moloco RewardVideo started")
    }

    /// 영상 재생 완료. 리워드 지급과는 별개이며 호출되지 않을 수 있다.
    /// 완료 통보는 `userRewarded` 에서 한다. (AOS 와 동일)
    func rewardedVideoCompleted(ad: any MolocoAd) {
        APLogger.debug("Moloco RewardVideo videoCompleted")
    }
}
