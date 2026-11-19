import Foundation
import ZIPFoundation

struct IPAMetadataReader {
    enum ReaderError: LocalizedError {
        case archiveUnreadable
        case appInfoNotFound
        case invalidInfoPlist
        case missingBundleIdentifier

        var errorDescription: String? {
            switch self {
            case .archiveUnreadable: return "The IPA is not a readable ZIP archive."
            case .appInfoNotFound: return "No Payload/*.app/Info.plist was found in this IPA."
            case .invalidInfoPlist: return "The app's Info.plist could not be parsed."
            case .missingBundleIdentifier: return "The app bundle does not declare CFBundleIdentifier."
            }
        }
    }

    static func read(from url: URL) throws -> IPAMetadata {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ReaderError.archiveUnreadable
        }

        guard let infoEntry = archive.first(where: { entry in
            entry.path.hasPrefix("Payload/") && entry.path.hasSuffix(".app/Info.plist")
        }) else {
            throw ReaderError.appInfoNotFound
        }

        var plistData = Data()
        _ = try archive.extract(infoEntry) { chunk in
            plistData.append(chunk)
        }

        guard let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw ReaderError.invalidInfoPlist
        }

        guard let bundleID = plist["CFBundleIdentifier"] as? String, !bundleID.isEmpty else {
            throw ReaderError.missingBundleIdentifier
        }

        let displayName = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? bundleID
        return IPAMetadata(
            name: displayName,
            bundleIdentifier: bundleID,
            version: (plist["CFBundleShortVersionString"] as? String) ?? "Unknown",
            buildNumber: (plist["CFBundleVersion"] as? String) ?? "Unknown"
        )
    }
}
