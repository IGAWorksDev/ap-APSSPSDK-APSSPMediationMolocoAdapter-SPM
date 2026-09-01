import Foundation
import APSSPSDK
import MolocoSDK

public final class MolocoInitializationAdapter: APSSPInitializationProtocol {
    public init() { }

    public var sdkVersion: String? { Moloco.shared.sdkVersion }

    public func start(keys: [String: String], completion: @escaping (Bool, String?) -> Void) {
        guard let appKey = keys[APSSPInitKey.molocoAppkey.key], !appKey.isEmpty else {
            completion(false, "MolocoAppKey is nil")
            return
        }
        let params = MolocoInitParams(appKey: appKey, mediation: "adpopcorn_SDK")
        Moloco.shared.initialize(params: params) { success, error in
            completion(success, error?.localizedDescription)
        }
    }
}
