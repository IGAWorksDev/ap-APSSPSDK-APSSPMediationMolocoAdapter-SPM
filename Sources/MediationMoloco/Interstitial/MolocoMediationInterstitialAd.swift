import UIKit
import APSSPSDK
import MolocoSDK

final class MolocoMediationInterstitialAd: NSObject {
    var delegate: APSSPInterstitialAdapterDelegate?
    private var interstitialAd: (any MolocoInterstitial)?
    private let adUnitId: String
    private var biddingData: String?

    init(adUnitId: String, biddingData: String? = nil) {
        self.adUnitId = adUnitId
        self.biddingData = biddingData
    }

    @MainActor func load() {
        guard !adUnitId.isEmpty else {
            APLogger.error("Moloco Interstitial adUnitId is empty")
            delegate?.interstitialLoadFail(error: .nextMediation, errorMessage: "adUnitId is empty")
            return
        }
        
        let params = MolocoCreateAdParams(adUnit: adUnitId, mediation: "AdPopcornSSP")
        interstitialAd = Moloco.shared.createInterstitial(params: params)
        interstitialAd?.interstitialDelegate = self
        interstitialAd?.load(bidResponse: biddingData ?? "")
    }

    @MainActor func present(from: UIViewController, completion: () -> Void) {
        interstitialAd?.show(from: from)
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

extension MolocoMediationInterstitialAd: MolocoInterstitialDelegate {
    func didLoad(ad: any MolocoAd) { delegate?.interstitialLoadSuccess() }
    func failToLoad(ad: any MolocoAd, with error: Error?) { delegate?.interstitialLoadFail(error: .nextMediation, errorMessage: error?.localizedDescription) }
    func didShow(ad: any MolocoAd) { delegate?.interstitialShowSuccess(message: "Moloco IS show") }
    func failToShow(ad: any MolocoAd, with error: Error?) { delegate?.interstitialShowFail(message: error?.localizedDescription ?? "Moloco IS show fail") }
    func didHide(ad: any MolocoAd) { delegate?.interstitialClosed(message: "Moloco IS closed") }
    func didClick(on ad: any MolocoAd) { delegate?.interstitialClicked(message: "Moloco IS clicked") }
}
