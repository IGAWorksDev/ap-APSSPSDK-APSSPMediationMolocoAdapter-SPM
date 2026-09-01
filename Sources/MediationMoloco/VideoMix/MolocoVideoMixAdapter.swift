import UIKit
import APSSPSDK
import MolocoSDK

public final class MolocoVideoMixAdapter: APSSPVideoMixAdAdapterInappBiddingProtocol {
    public var rootViewController: UIViewController?
    public var videoMixDelegate: APSSPVideoMixAdAdapterDelegate?
    public var videoMixAdType: APSSPVideoMixAdType = .RewardVideo
    private var placementDic: [String: String] = [:]
    private var interstitialAdapter: MolocoInterstitialAdapter?
    private var rewardVideoAdapter: MolocoRewardVideoAdapter?

    public init(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any?]) {
        self.placementDic = placementDic; self.rootViewController = rootViewController
        if let ct = placementDic[APSSPPlacementKey.campaignType.rawValue], let v = Int(ct), let t = APSSPVideoMixAdType(rawValue: v) { videoMixAdType = t }
    }

    public init(inappbiddingPlacementDic: [String: String], rootViewController: UIViewController?) {
        self.placementDic = inappbiddingPlacementDic; self.rootViewController = rootViewController
        if let ct = inappbiddingPlacementDic[APSSPPlacementKey.campaignType.rawValue], let v = Int(ct), let t = APSSPVideoMixAdType(rawValue: v) { videoMixAdType = t }
    }

    @MainActor public func connectVideoMixDelegate(delegate: APSSPVideoMixAdAdapterDelegate) {
        videoMixDelegate = delegate
        switch videoMixAdType {
        case .Interstitial, .InterstitialVideo:
            interstitialAdapter = MolocoInterstitialAdapter(placementDic: placementDic, rootViewController: rootViewController, info: [:])
            interstitialAdapter?.connectDelegate(delegate: self)
        case .RewardVideo:
            rewardVideoAdapter = MolocoRewardVideoAdapter(placementDic: placementDic, rootViewController: rootViewController, info: [:])
            rewardVideoAdapter?.connectDelegate(delegate: self)
        @unknown default: break
        }
    }

    public func disconnectVideoMixDelegate() { interstitialAdapter = nil; rewardVideoAdapter = nil; videoMixDelegate = nil }

    @MainActor public func present(from: UIViewController, completion: @escaping () -> Void) {
        switch videoMixAdType {
        case .Interstitial, .InterstitialVideo: interstitialAdapter?.present(from: from) { completion() }
        case .RewardVideo: rewardVideoAdapter?.present(from: from) { completion() }
        @unknown default: break
        }
    }

    public func getBiddingToken() -> String {
        var token = ""
        let semaphore = DispatchSemaphore(value: 0)
        Moloco.shared.getBidToken(params: MolocoParams(mediation: "AdPopcornSSP")) { bidToken, _ in
            token = bidToken ?? ""; semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 3)
        return token
    }
}

extension MolocoVideoMixAdapter: APSSPInterstitialAdapterDelegate {
    public func interstitialLoadSuccess() { videoMixDelegate?.videoMixAdLoadSuccess(type: videoMixAdType) }
    public func interstitialLoadFail(error: APSSPNetworkError, errorMessage: String?) { videoMixDelegate?.videoMixAdLoadFail(error: error, type: videoMixAdType, errorMessage: errorMessage) }
    public func interstitialShowSuccess(message: String) { videoMixDelegate?.videoMixAdShowSuccess(message: message, type: videoMixAdType) }
    public func interstitialShowFail(message: String) { videoMixDelegate?.videoMixAdShowFail(message: message, type: videoMixAdType) }
    public func interstitialClosed(message: String) { videoMixDelegate?.videoMixAdClosed(message: message, type: videoMixAdType) }
    public func interstitialClicked(message: String) { videoMixDelegate?.videoMixAdClicked(message: message, type: videoMixAdType) }
}

extension MolocoVideoMixAdapter: APSSPRewardVideoAdapterDelegate {
    public func rewardVideoLoadSuccess() { videoMixDelegate?.videoMixAdLoadSuccess(type: videoMixAdType) }
    public func rewardVideoLoadFail(error: APSSPNetworkError, errorMessage: String?) { videoMixDelegate?.videoMixAdLoadFail(error: error, type: videoMixAdType, errorMessage: errorMessage) }
    public func rewardVideoShowSuccess(message: String) { videoMixDelegate?.videoMixAdShowSuccess(message: message, type: videoMixAdType) }
    public func rewardVideoShowFail(message: String) { videoMixDelegate?.videoMixAdShowFail(message: message, type: videoMixAdType) }
    public func rewardVideoClosed(message: String) { videoMixDelegate?.videoMixAdClosed(message: message, type: videoMixAdType) }
    public func rewardVideoClicked(message: String) { videoMixDelegate?.videoMixAdClicked(message: message, type: videoMixAdType) }
    public func rewardVideoCompleted() { videoMixDelegate?.videoMixAdCompleteTrackingEvent(adNetworkNo: APSSPMediationCompany.Moloco.rawValue, isCompleted: true, type: videoMixAdType) }
}
