//
//  MolocoMediationUnifiedNativeAdView.swift
//  MediationMoloco
//
//  Created by Odin on 2026/07/06.
//

import UIKit
import MolocoSDK
import APSSPSDK


final class MolocoMediationUnifiedNativeAdView: NSObject {
    
    weak var delegate: APSSPUnifiedNativeAdapterDelegate?
    
    private let adUnitId: String
    private let biddingData: String
    private weak var rootViewController: UIViewController?
    private let viewBinder: APSSPMediationViewBinder
    private let config: APSSPNativeAdConfig?
    
    private var nativeAd: (any MolocoNativeAd)?
    private var impressionTimer: Timer?
    private var isImpressed = false
    
    
    init(adUnitId: String, biddingData: String, rootViewController: UIViewController?, viewBinder: APSSPMediationViewBinder, config: APSSPNativeAdConfig?) {
        self.adUnitId = adUnitId
        self.biddingData = biddingData
        self.rootViewController = rootViewController
        self.viewBinder = viewBinder
        self.config = config
    }
    
    func load() {
        guard !adUnitId.isEmpty else {
            delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: "Moloco adUnitId is empty")
            return
        }
        
        Task { @MainActor in
            let params = MolocoCreateAdParams(adUnit: adUnitId, mediation: "AdPopcornSSP")
            nativeAd = Moloco.shared.createNativeAd(params: params)
            nativeAd?.delegate = self
            nativeAd?.load(bidResponse: biddingData)
        }
    }
    
    func stop() {
        stopImpressionTimer()
        nativeAd?.delegate = nil
        nativeAd?.destroy()
        nativeAd = nil
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
    
    private func bindToViewBinder() {
        guard let assets = nativeAd?.assets else {
            delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: "Moloco assets is nil")
            return
        }
        
        viewBinder.titleLabel?.text = assets.title
        viewBinder.bodyLabel?.text = assets.description
        viewBinder.ctaButton?.setTitle(assets.ctaTitle, for: .normal)
        viewBinder.iconImageView?.image = assets.appIcon
        
        // 옵셔널
        var visibleKeys = Set<String>()
        let sponsor = assets.sponsorText
        if !sponsor.isEmpty {
            viewBinder.sponsoredLabel?.text = sponsor
            visibleKeys.insert("sponsored")
        }
        if let mainImage = assets.mainImage {
            viewBinder.mainImageView?.image = mainImage
            visibleKeys.insert("mainImage")
        }
        viewBinder.hideOptionalViews(except: visibleKeys)
        
        // videoView → mediaContainerView
        if let videoView = assets.videoView {
            viewBinder.insertMediaView(videoView)
        } else if let mainImage = assets.mainImage, viewBinder.mainImageView == nil {
            // mainImageView 없으면 mediaContainerView에 이미지 뷰 생성
            let imageView = UIImageView(image: mainImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            viewBinder.insertMediaView(imageView)
        }
        
        // click tracking
        setupClickTracking()
        // impression tracking
        startImpressionTracking()
    }
    
    // MARK: - Click Tracking
    
    private func setupClickTracking() {
        guard let container = viewBinder.containerView else { return }
        container.gestureRecognizers?.forEach { container.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAdTapped))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
    }
    
    @objc private func handleAdTapped() {
        nativeAd?.handleClick()
    }
    
    // MARK: - Impression Tracking
    
    private func startImpressionTracking() {
        guard !isImpressed else { return }
        impressionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkViewability()
        }
    }
    
    private func checkViewability() {
        guard !isImpressed,
              let container = viewBinder.containerView,
              container.window != nil,
              !container.isHidden,
              container.alpha > 0 else { return }
        
        isImpressed = true
        stopImpressionTimer()
        nativeAd?.handleImpression()
    }
    
    private func stopImpressionTimer() {
        impressionTimer?.invalidate()
        impressionTimer = nil
    }
}

extension MolocoMediationUnifiedNativeAdView: MolocoNativeAdDelegate {
    func didLoad(ad: any MolocoAd) {
        DispatchQueue.main.async { [weak self] in
            self?.bindToViewBinder()
            self?.delegate?.unifiedNativeLoadSuccess()
        }
    }
    
    func failToLoad(ad: any MolocoAd, with error: Error?) {
        delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: error?.localizedDescription ?? "Moloco load failed")
    }
    
    func didShow(ad: any MolocoAd) {}
    func failToShow(ad: any MolocoAd, with error: Error?) {}
    func didHide(ad: any MolocoAd) {}
    func didClick(on ad: any MolocoAd) {}
    
    func didHandleImpression(ad: any MolocoAd) {
        delegate?.unifiedNativeImpression(message: "Moloco UnifiedNative impression")
    }
    
    func didHandleClick(ad: any MolocoAd) {
        delegate?.unifiedNativeClicked(message: "Moloco UnifiedNative clicked")
    }
}
