//
//  MolocoUnifiedNativeAdapter.swift
//  MediationMoloco
//
//  Created by Odin on 2026/07/06.
//

import UIKit
import APSSPSDK


/// Moloco 통합형 네이티브 광고 Adapter.
/// InApp Bidding 지원을 위해 APSSPUnifiedNativeAdapterInAppBiddingProtocol을 conform합니다.
final public class MolocoUnifiedNativeAdapter: NSObject, APSSPUnifiedNativeAdapterInAppBiddingProtocol {
    
    public weak var delegate: APSSPUnifiedNativeAdapterDelegate?
    public weak var rootViewController: UIViewController?
    public var viewBinder: APSSPMediationViewBinder
    public var config: APSSPNativeAdConfig?
    
    private var mediationView: MolocoMediationUnifiedNativeAdView
    
    
    // MARK: - Waterfall 초기화
    
    public required init(placementDic: [String: String],
                         rootViewController: UIViewController?,
                         viewBinder: APSSPMediationViewBinder,
                         config: APSSPNativeAdConfig?,
                         info: [String: Any?]) {
        let adUnitId = placementDic[APSSPPlacementKey.molocoAdUnitId.rawValue] ?? ""
        let biddingData = placementDic[APSSPBiddingKey.biddingData.rawValue] ?? ""
        self.rootViewController = rootViewController
        self.viewBinder = viewBinder
        self.config = config
        self.mediationView = MolocoMediationUnifiedNativeAdView(
            adUnitId: adUnitId,
            biddingData: biddingData,
            rootViewController: rootViewController,
            viewBinder: viewBinder,
            config: config
        )
        super.init()
    }
    
    
    // MARK: - InApp Bidding 초기화
    
    public required init(inappBiddingPlacementDic: [String: String],
                         rootViewController: UIViewController?,
                         viewBinder: APSSPMediationViewBinder,
                         config: APSSPNativeAdConfig?,
                         info: [String: Any?]) {
        let adUnitId = inappBiddingPlacementDic[APSSPBiddingKey.molocoPlacementId.rawValue] ?? ""
        let biddingData = inappBiddingPlacementDic[APSSPBiddingKey.biddingData.rawValue] ?? ""
        self.rootViewController = rootViewController
        self.viewBinder = viewBinder
        self.config = config
        self.mediationView = MolocoMediationUnifiedNativeAdView(
            adUnitId: adUnitId,
            biddingData: biddingData,
            rootViewController: rootViewController,
            viewBinder: viewBinder,
            config: config
        )
        super.init()
    }
    
    
    // MARK: - APSSPUnifiedNativeAdapterProtocol
    
    public func connectDelegate(delegate: APSSPUnifiedNativeAdapterDelegate) {
        self.delegate = delegate
        mediationView.delegate = self
        mediationView.load()
    }
    
    public func disconnectDelegate() { mediationView.delegate = nil; delegate = nil }
    public func stop() { mediationView.stop() }
    
    
    // MARK: - APSSPUnifiedNativeAdapterInAppBiddingProtocol
    
    public func getBiddingToken() -> String {
        return mediationView.getBiddingToken()
    }
}


// MARK: - APSSPUnifiedNativeAdapterDelegate
extension MolocoUnifiedNativeAdapter: APSSPUnifiedNativeAdapterDelegate {
    public func unifiedNativeLoadSuccess() { delegate?.unifiedNativeLoadSuccess() }
    public func unifiedNativeLoadFail(error: APSSPNetworkError, errorMessage: String?) { delegate?.unifiedNativeLoadFail(error: error, errorMessage: errorMessage) }
    public func unifiedNativeClicked(message: String) { delegate?.unifiedNativeClicked(message: message) }
    public func unifiedNativeImpression(message: String) { delegate?.unifiedNativeImpression(message: message) }
}
