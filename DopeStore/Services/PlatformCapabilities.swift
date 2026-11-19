import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct PlatformCapabilities {
    static let installationBridgeIntegrated = false
    static let signingBridgeIntegrated = false
    static let refreshBridgeIntegrated = false
    static let jitActivationIntegrated = false

    static var operatingSystemVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    static var deviceModel: String {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Unknown"
        #endif
    }
}
