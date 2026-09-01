import UIKit
import APSSPSDK
import MolocoSDK

public final class MolocoNativeAdapter: APSSPNativeAdapterInappBiddingProtocol {
    public var render: AnyObject?
    weak public var delegate: APSSPNativeViewAdapterDelegate?
    public var rootViewController: UIViewController?
    private var mediationAd: MolocoMediationNativeAdView?

    public init(placementDic: [String: String], rootViewController: UIViewController?, render: AnyObject, info: [String: Any?]) {
        let adUnitId = placementDic[APSSPPlacementKey.molocoAdUnitId.rawValue] ?? ""
        self.render = render
        self.rootViewController = rootViewController
        self.mediationAd = MolocoMediationNativeAdView(adUnitId: adUnitId, rootViewController: rootViewController, render: render)
    }
    
    public init(inappbiddingPlacementDic: [String : String], rootViewController: UIViewController?, render: AnyObject, info: [String : Any?]) {
        let adUnitId = inappbiddingPlacementDic[APSSPBiddingKey.molocoPlacementId.rawValue] ?? ""
        let biddingData = inappbiddingPlacementDic[APSSPBiddingKey.biddingData.rawValue]
        self.render = render
        self.rootViewController = rootViewController
        self.mediationAd = MolocoMediationNativeAdView(adUnitId: adUnitId, rootViewController: rootViewController, render: render, biddingData: biddingData)
    }

    public func connectDelegate(delegate: APSSPNativeViewAdapterDelegate) {
        self.delegate = delegate
        mediationAd?.delegate = self
        mediationAd?.load()
    }

    public func disconnectDelegate() {
        mediationAd?.delegate = nil
        delegate = nil
    }
    
    public func stop() {
        mediationAd?.stop()
    }
    
    public func getBiddingToken() -> String {
        mediationAd?.getBiddingToken() ?? ""
    }
}

extension MolocoNativeAdapter: APSSPNativeViewAdapterDelegate {
    public func nativeLoadSuccess() {
        delegate?.nativeLoadSuccess()
    }
    
    public func nativeLoadFail(error: APSSPNetworkError, errorMessage: String?) {
        delegate?.nativeLoadFail(error: error, errorMessage: errorMessage)
    }
    
    public func nativeClicked(message: String) {
        delegate?.nativeClicked(message: message)
    }
    
    public func nativeImpression(message: String) {
        delegate?.nativeImpression(message: message)
    }
}
