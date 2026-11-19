import Foundation

struct InstalledAppReceipt: Sendable {
    let bundleIdentifier: String
    let version: String
    let signedUntil: Date?
    let jitConfirmed: Bool
}

protocol SideloadingProvider: Sendable {
    func signAndInstall(ipaURL: URL) async throws -> InstalledAppReceipt
    func refresh(bundleIdentifier: String) async throws -> InstalledAppReceipt
    func refreshAll() async throws -> [InstalledAppReceipt]
    func activateJIT(bundleIdentifier: String) async throws -> Bool
}

enum SideloadingProviderError: LocalizedError {
    case providerNotIntegrated
    case pairingRecordMissing
    case tunnelPeerUnreachable(String)
    case unsupportedPairingProtocol(String)
    case appleAuthenticationFailed(String)
    case provisioningProfileInvalid(String)
    case signingFailed(String)
    case installationFailed(String)
    case refreshFailed(String)
    case jitUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .providerNotIntegrated:
            return "The DopeStore signing and installation provider is not integrated in this build."
        case .pairingRecordMissing:
            return "No valid pairing record is available. Import a pairing record in Settings."
        case .tunnelPeerUnreachable(let detail):
            return "The device tunnel is present but the pairing endpoint is unreachable. \(detail)"
        case .unsupportedPairingProtocol(let detail):
            return "The pairing protocol is not supported by this provider. \(detail)"
        case .appleAuthenticationFailed(let detail):
            return "Apple account authentication failed. \(detail)"
        case .provisioningProfileInvalid(let detail):
            return "The provisioning profile is missing, expired, or does not match the app. \(detail)"
        case .signingFailed(let detail):
            return "The IPA could not be signed. \(detail)"
        case .installationFailed(let detail):
            return "iOS rejected the application installation. \(detail)"
        case .refreshFailed(let detail):
            return "The application could not be refreshed. \(detail)"
        case .jitUnavailable(let detail):
            return "JIT could not be enabled for this application. \(detail)"
        }
    }
}

/// Used until a reviewed provider implementing the real Apple signing and device transport is added.
/// Every operation fails explicitly; it never reports a fabricated install, refresh, or JIT success.
struct UnavailableSideloadingProvider: SideloadingProvider {
    func signAndInstall(ipaURL: URL) async throws -> InstalledAppReceipt {
        throw SideloadingProviderError.providerNotIntegrated
    }

    func refresh(bundleIdentifier: String) async throws -> InstalledAppReceipt {
        throw SideloadingProviderError.providerNotIntegrated
    }

    func refreshAll() async throws -> [InstalledAppReceipt] {
        throw SideloadingProviderError.providerNotIntegrated
    }

    func activateJIT(bundleIdentifier: String) async throws -> Bool {
        throw SideloadingProviderError.providerNotIntegrated
    }
}
