//
//  MolocoMediationUnifiedNativeAdView.swift
//  MediationMoloco
//
//  Created by Odin on 2026/07/06.
//

import UIKit
import MolocoSDK
import APSSPSDK


/// SDK가 부착한 탭 제스처를 식별하기 위한 마커 클래스.
///
/// 코어의 `APSSPUnifiedNativeTapGesture`는 internal이라 다른 모듈에서 사용할 수 없어
/// 동일한 역할의 마커를 어댑터 내부에 둔다.
/// 매체가 직접 붙인 제스처를 지우지 않고 **우리가 붙인 것만** 정리하기 위해 사용한다.
private final class MolocoUnifiedNativeTapGesture: UITapGestureRecognizer {}


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

    /// 신규(레시피) 방식에서 생성한 매체 화면
    private var contentView: APSSPUnifiedNativeAdView?

    /// 임프레션 측정 대상 뷰 (신규 방식은 contentView, 기존 방식은 containerView)
    private var impressionTargetView: UIView? {
        contentView ?? viewBinder.containerView
    }

    
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
        contentView?.removeFromSuperview()
        contentView = nil
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
    
    /// 신규(레시피) 방식 — 매체 화면을 생성해 placeholder에 부착하고 데이터를 바인딩한다.
    ///
    /// Moloco는 업체 컨테이너 클래스도, 뷰 등록(register) API도 제공하지 않는다.
    /// 따라서 클릭/임프레션은 어댑터가 직접 처리한다.
    /// - Returns: 바인딩 성공 여부. `false`면 이미 loadFail을 통지한 상태다.
    private func bindToContentView() -> Bool {
        guard let assets = nativeAd?.assets else {
            delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: "Moloco assets is nil")
            return false
        }

        guard let placeholder = viewBinder.resolvedPlaceholder else {
            delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: "Moloco placeholder is nil")
            return false
        }

        guard let content = viewBinder.makeContentView() else {
            delegate?.unifiedNativeLoadFail(error: .nextMediation, errorMessage: "Moloco contentView 생성 실패")
            return false
        }
        self.contentView = content

        // 1. 화면 부착 (컨테이너 클래스가 없으므로 wrap 없이 바로 부착)
        APSSPUnifiedNativeAssembler.attach(content, to: placeholder)

        // 2. 데이터 바인딩
        content.titleLabel?.text = assets.title
        content.bodyLabel?.text = assets.description
        content.ctaButton?.setTitle(assets.ctaTitle, for: .normal)
        content.iconImageView?.image = assets.appIcon

        // 3. 옵셔널 뷰
        var visibleKeys = Set<APSSPUnifiedNativeAdView.OptionalKey>()
        let sponsor = assets.sponsorText
        if !sponsor.isEmpty {
            content.sponsoredLabel?.text = sponsor
            visibleKeys.insert(.sponsored)
        }
        if let mainImage = assets.mainImage, let mainImageView = content.mainImageView {
            mainImageView.image = mainImage
            visibleKeys.insert(.mainImage)
        }
        content.hideOptionalViews(except: visibleKeys)

        // 4. 미디어 슬롯 — videoView 우선, 없으면 mainImage로 UIImageView 생성해 삽입
        if let videoView = assets.videoView {
            if !APSSPUnifiedNativeAssembler.fillSlot(content.mediaContainerView, with: videoView) {
                APLogger.error("Moloco UnifiedNative: mediaContainerView가 없습니다. XIB에 빈 컨테이너를 배치하세요.")
            }
        } else if let mainImage = assets.mainImage, content.mainImageView == nil {
            let imageView = UIImageView(image: mainImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            APSSPUnifiedNativeAssembler.fillSlot(content.mediaContainerView, with: imageView)
        }

        // 광고에 없는 에셋(CTA/아이콘 등)의 필수 뷰를 숨긴다 — XIB placeholder가 그대로 남는 것을 방지.
        // 미디어 슬롯 채우기까지 끝난 뒤에 호출해야 mediaContainer가 빈 것으로 오판되지 않는다.
        content.hideEmptyViews()

        // 5. 클릭
        //    UIButton은 터치를 자체 소비하므로 상위 탭 제스처가 발동하지 않는다.
        //    따라서 CTA 버튼은 target을, 나머지 영역은 탭 제스처로 처리한다.
        content.ctaButton?.addTarget(self, action: #selector(handleAdTapped), for: .touchUpInside)
        attachClickGesture(to: content)

        // 6. 임프레션
        startImpressionTracking()

        return true
    }

    /// APSSP-LEGACY: ViewBinder 참조 방식. 신규 ContentView 방식으로 대체됨 — 다음 메이저에서 제거 대상.
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
    
    /// 클릭 제스처 부착. 매체가 붙인 제스처를 지우지 않도록 우리가 붙인 것만 관리한다.
    private func attachClickGesture(to view: UIView) {
        view.gestureRecognizers?
            .filter { $0 is MolocoUnifiedNativeTapGesture }
            .forEach { view.removeGestureRecognizer($0) }

        let tapGesture = MolocoUnifiedNativeTapGesture(target: self, action: #selector(handleAdTapped))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
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
              let container = impressionTargetView,
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
            guard let self else { return }
            if self.viewBinder.isContentViewMode {
                APLogger.debug("Moloco UnifiedNative → 매체 XIB (신규 구조)")
                // 실패 시 내부에서 loadFail을 통지하므로 success를 보내지 않는다
                guard self.bindToContentView() else { return }
            } else {
                self.bindToViewBinder()
            }
            self.delegate?.unifiedNativeLoadSuccess()
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
