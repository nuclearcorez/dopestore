import Foundation

struct AppRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var bundleIdentifier: String
    var version: String
    var buildNumber: String
    var fileName: String
    var fileSize: Int64
    var importedAt: Date
    var signingExpiration: Date?

    var expirationStatus: ExpirationStatus {
        guard let signingExpiration else { return .unknown }
        return ExpirationPolicy.status(for: signingExpiration, now: Date())
    }
}

enum ExpirationStatus: String, Equatable {
    case valid
    case expiringSoon
    case expired
    case unknown

    var title: String {
        switch self {
        case .valid: return "Valid"
        case .expiringSoon: return "Expiring soon"
        case .expired: return "Expired"
        case .unknown: return "Unknown"
        }
    }
}

enum ExpirationPolicy {
    static func status(for expiration: Date, now: Date, warningWindow: TimeInterval = 48 * 60 * 60) -> ExpirationStatus {
        if expiration <= now { return .expired }
        if expiration.timeIntervalSince(now) <= warningWindow { return .expiringSoon }
        return .valid
    }
}

struct IPAMetadata: Equatable, Sendable {
    let name: String
    let bundleIdentifier: String
    let version: String
    let buildNumber: String
}
