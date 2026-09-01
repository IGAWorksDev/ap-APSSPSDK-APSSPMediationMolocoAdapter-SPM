import UIKit
import APSSPSDK
import MolocoSDK

@objc(APSSPMolocoAdapterFactory)
public final class MolocoAdapterFactory: NSObject, APSSPAdapterFactory {

    public static var networkID: Int { 42 }

    public static var sdkVersion: String? { MolocoInitializationAdapter().sdkVersion }
    public static var adapterVersion: String? { "4.8.0.0" }

    // MARK: - Standard

    public static func makeInitializationAdapter() -> AnyObject? {
        return MolocoInitializationAdapter()
    }

    public static func makeBannerAdapter(placementDic: [String: String], bannerType: APSSPBannerSize, rootViewController: UIViewController?, info: [String: Any]) -> AnyObject? {
        return MolocoBannerAdapter(placementDic: placementDic, bannerType: bannerType, rootViewController: rootViewController, info: info)
    }

    public static func makeInterstitialAdapter(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any]) -> AnyObject? {
        return MolocoInterstitialAdapter(placementDic: placementDic, rootViewController: rootViewController, info: info)
    }

    public static func makeRewardVideoAdapter(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any]) -> AnyObject? {
        return MolocoRewardVideoAdapter(placementDic: placementDic, rootViewController: rootViewController, info: info)
    }

    public static func makeNativeAdapter(placementDic: [String: String], rootViewController: UIViewController?, render: AnyObject, info: [String: Any]) -> AnyObject? {
        return MolocoNativeAdapter(placementDic: placementDic, rootViewController: rootViewController, render: render, info: info)
    }

    public static func makeVideoMixAdapter(placementDic: [String: String], rootViewController: UIViewController?, info: [String: Any]) -> AnyObject? {
        return MolocoVideoMixAdapter(placementDic: placementDic, rootViewController: rootViewController, info: info)
    }

    // MARK: - Bidding

    public static func makeBiddingBannerAdapter(placementDic: [String: String], bannerType: APSSPBannerSize, rootViewController: UIViewController?) -> AnyObject? {
        return MolocoBannerAdapter(inappbiddingPlacementDic: placementDic, bannerType: bannerType, rootViewController: rootViewController)
    }

    public static func makeBiddingInterstitialAdapter(placementDic: [String: String], rootViewController: UIViewController?) -> AnyObject? {
        return MolocoInterstitialAdapter(inappbiddingPlacementDic: placementDic, rootViewController: rootViewController)
    }

    public static func makeBiddingRewardVideoAdapter(placementDic: [String: String], rootViewController: UIViewController?) -> AnyObject? {
        return MolocoRewardVideoAdapter(inappbiddingPlacementDic: placementDic, rootViewController: rootViewController)
    }

    public static func makeBiddingNativeAdapter(placementDic: [String: String], rootViewController: UIViewController?, render: AnyObject, info: [String: Any]) -> AnyObject? {
        return MolocoNativeAdapter(inappbiddingPlacementDic: placementDic, rootViewController: rootViewController, render: render, info: info)
    }

    public static func makeBiddingVideoMixAdapter(placementDic: [String: String], rootViewController: UIViewController?) -> AnyObject? {
        return MolocoVideoMixAdapter(inappbiddingPlacementDic: placementDic, rootViewController: rootViewController)
    }

    public static func makeUnifiedNativeAdapter(placementDic: [String: String], rootViewController: UIViewController?, viewBinder: APSSPMediationViewBinder, config: APSSPNativeAdConfig?, info: [String: Any]) -> AnyObject? {
        return MolocoUnifiedNativeAdapter(placementDic: placementDic, rootViewController: rootViewController, viewBinder: viewBinder, config: config, info: info)
    }

    public static func makeBiddingUnifiedNativeAdapter(placementDic: [String: String], rootViewController: UIViewController?, viewBinder: APSSPMediationViewBinder, config: APSSPNativeAdConfig?, info: [String: Any]) -> AnyObject? {
        return MolocoUnifiedNativeAdapter(inappBiddingPlacementDic: placementDic, rootViewController: rootViewController, viewBinder: viewBinder, config: config, info: info)
    }
}
