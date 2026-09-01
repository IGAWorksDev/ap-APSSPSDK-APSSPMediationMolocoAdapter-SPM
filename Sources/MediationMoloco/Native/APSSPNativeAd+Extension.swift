//
//  APSSPNativeAd+Extension.swift
//  MediationMoloco
//

import UIKit
import APSSPSDK

extension APSSPNativeAd {
    @objc public func bindMolocoRenderer(renderer: APSSPMolocoNativeAdRenderer) {
        if renderer.contentView == nil { renderer.contentView = renderer.nativeAdView }
        self.molocoRenderer = renderer
    }
}
