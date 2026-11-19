import Foundation
#if canImport(Security)
import Security
#endif

struct PairingRecordSummary: Equatable {
    let hostIdentifier: String?
    let importedAt: Date
    let certificateExpiration: Date?
    let byteCount: Int
}

struct PairingRecordValidator {
    enum ValidationError: LocalizedError {
        case malformedPropertyList
        case missingIdentity
        case missingPairingMaterial

        var errorDescription: String? {
            switch self {
            case .malformedPropertyList: return "The file is not a valid XML or binary property list."
            case .missingIdentity: return "The pairing record has no recognizable HostID, DeviceID, or UDID field."
            case .missingPairingMaterial: return "The file does not contain recognizable pairing certificates or escrow material."
            }
        }
    }

    static func validate(_ data: Data) throws -> PairingRecordSummary {
        let value: Any
        do {
            value = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw ValidationError.malformedPropertyList
        }

        guard let dictionary = value as? [String: Any] else {
            throw ValidationError.malformedPropertyList
        }

        let keys = Set(allKeys(in: dictionary))
        let identityKeys: Set<String> = ["HostID", "DeviceID", "UDID", "UniqueDeviceID"]
        let materialKeys: Set<String> = [
            "HostCertificate", "DeviceCertificate", "RootCertificate",
            "HostPrivateKey", "RootPrivateKey", "EscrowBag", "PairingTicket"
        ]

        guard !keys.isDisjoint(with: identityKeys) else { throw ValidationError.missingIdentity }
        guard !keys.isDisjoint(with: materialKeys) else { throw ValidationError.missingPairingMaterial }

        let hostIdentifier = (dictionary["HostID"] as? String)
            ?? (dictionary["DeviceID"] as? String)
            ?? (dictionary["UDID"] as? String)
            ?? (dictionary["UniqueDeviceID"] as? String)

        let certificateExpiration = certificateData(in: dictionary)
            .compactMap(certificateNotAfter)
            .min()

        return PairingRecordSummary(
            hostIdentifier: hostIdentifier,
            importedAt: Date(),
            certificateExpiration: certificateExpiration,
            byteCount: data.count
        )
    }

    private static func allKeys(in dictionary: [String: Any]) -> [String] {
        var result: [String] = []
        for (key, value) in dictionary {
            result.append(key)
            if let nested = value as? [String: Any] {
                result.append(contentsOf: allKeys(in: nested))
            } else if let array = value as? [[String: Any]] {
                array.forEach { result.append(contentsOf: allKeys(in: $0)) }
            }
        }
        return result
    }

    private static func certificateData(in dictionary: [String: Any]) -> [Data] {
        var result: [Data] = []
        for (key, value) in dictionary {
            let lower = key.lowercased()
            if lower.contains("certificate"), let data = value as? Data {
                result.append(data)
            }
            if let nested = value as? [String: Any] {
                result.append(contentsOf: certificateData(in: nested))
            }
        }
        return result
    }

    private static func certificateNotAfter(_ data: Data) -> Date? {
        #if canImport(Security)
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else { return nil }
        let requested = [kSecOIDX509V1ValidityNotAfter] as CFArray
        let values = SecCertificateCopyValues(certificate, requested, nil) as? [CFString: Any]
        let validity = values?[kSecOIDX509V1ValidityNotAfter] as? [CFString: Any]
        return validity?[kSecPropertyKeyValue] as? Date
        #else
        return nil
        #endif
    }
}
