import UIKit
import APSSPSDK
import MolocoSDK

@objc
public final class APSSPMolocoNativeAdRenderer: NSObject, APSSPNativeRenderer {
    @objc public var contentView: UIView?
    @objc public var nativeAdView: UIView?
    @objc public var iconView: UIImageView?
    @objc public var mainImageView: UIImageView?
    @objc public var titleLbl: UILabel?
    @objc public var descriptionLbl: UILabel?
    @objc public var sponsorLbl: UILabel?
    @objc public var ctaBtn: UIButton?
    @objc public var ratingLbl: UILabel?
    @objc public var videoContainerView: UIView?
}


final class MolocoMediationNativeAdView: NSObject {
    weak var delegate: APSSPNativeViewAdapterDelegate?
    private var nativeAd: (any MolocoNativeAd)?
    private let adUnitId: String
    private var biddingData: String?
    private weak var rootViewController: UIViewController?
    private var molocoRenderer: APSSPMolocoNativeAdRenderer?
    private var impressionTimer: Timer?
    private var isImpressed = false

    init(adUnitId: String, rootViewController: UIViewController?, render: AnyObject?, biddingData: String? = nil) {
        self.adUnitId = adUnitId
        self.biddingData = biddingData
        self.rootViewController = rootViewController
        super.init()
        
        if let render = render as? APSSPMolocoNativeAdRenderer {
            self.molocoRenderer = render
        }
    }

    func load() {
        guard !adUnitId.isEmpty else {
            APLogger.error("Moloco Native adUnitId is empty")
            delegate?.nativeLoadFail(error: .nextMediation, errorMessage: "adUnitId is empty")
            return
        }
        
        Task { @MainActor in
            let params = MolocoCreateAdParams(adUnit: adUnitId, mediation: "AdPopcornSSP")
            nativeAd = Moloco.shared.createNativeAd(params: params)
            nativeAd?.delegate = self
            nativeAd?.load(bidResponse: biddingData ?? "")
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
    
    private func setupData() {
        guard let molocoRenderer, let assets = nativeAd?.assets else {
            APLogger.error("Moloco renderer or assets is nil")
            delegate?.nativeLoadFail(error: .nextMediation, errorMessage: "Moloco renderer or assets is nil")
            return
        }
        
        // assets 바인딩
        molocoRenderer.titleLbl?.text = assets.title
        molocoRenderer.descriptionLbl?.text = assets.description
        molocoRenderer.sponsorLbl?.text = assets.sponsorText
        molocoRenderer.ctaBtn?.setTitle(assets.ctaTitle, for: .normal)
        molocoRenderer.iconView?.image = assets.appIcon
        molocoRenderer.mainImageView?.image = assets.mainImage
        
        if assets.rating > 0 {
            molocoRenderer.ratingLbl?.text = String(format: "%.1f", assets.rating)
        }
        
        // videoView가 있으면 videoContainerView에 추가
        if let videoView = assets.videoView, let container = molocoRenderer.videoContainerView {
            videoView.frame = container.bounds
            videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(videoView)
        }
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
              let adView = molocoRenderer?.nativeAdView,
              adView.window != nil,
              !adView.isHidden,
              adView.alpha > 0,
              isViewActuallyVisible(adView) else { return }
        
        isImpressed = true
        stopImpressionTimer()
        nativeAd?.handleImpression()
    }
    
    private func isViewActuallyVisible(_ view: UIView) -> Bool {
        guard let window = view.window else { return false }
        var visibleRect = view.convert(view.bounds, to: window)
        guard visibleRect.width > 0, visibleRect.height > 0 else { return false }
        
        var current: UIView? = view.superview
        while let sv = current {
            if sv.clipsToBounds || sv is UIScrollView {
                let svRect = sv.convert(sv.bounds, to: window)
                visibleRect = visibleRect.intersection(svRect)
                if visibleRect.isNull || visibleRect.height <= 0 { return false }
            }
            current = sv.superview
        }
        return window.bounds.intersects(visibleRect)
    }
    
    private func stopImpressionTimer() {
        impressionTimer?.invalidate()
        impressionTimer = nil
    }
    
    // MARK: - Click Tracking
    
    private func setupClickTracking() {
        guard let contentView = molocoRenderer?.nativeAdView else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAdTapped))
        contentView.addGestureRecognizer(tap)
        contentView.isUserInteractionEnabled = true
    }
    
    @objc private func handleAdTapped() {
        nativeAd?.handleClick()
    }
}

extension MolocoMediationNativeAdView: MolocoNativeAdDelegate {
    func didLoad(ad: any MolocoAd) {
        DispatchQueue.main.async { [weak self] in
            self?.setupData()
            self?.startImpressionTracking()
            self?.setupClickTracking()
            self?.delegate?.nativeLoadSuccess()
        }
    }
    
    func failToLoad(ad: any MolocoAd, with error: Error?) {
        delegate?.nativeLoadFail(error: .nextMediation, errorMessage: error?.localizedDescription)
    }
    
    func didShow(ad: any MolocoAd) { }
    func failToShow(ad: any MolocoAd, with error: Error?) { }
    func didHide(ad: any MolocoAd) { }
    func didClick(on ad: any MolocoAd) { }
    
    func didHandleImpression(ad: any MolocoAd) {
        delegate?.nativeImpression(message: "Moloco Native impression")
    }
    
    func didHandleClick(ad: any MolocoAd) {
        delegate?.nativeClicked(message: "Moloco Native clicked")
    }
}
