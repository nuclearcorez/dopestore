import Foundation
import Security
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PairingRecordStore: ObservableObject {
    @Published private(set) var summary: PairingRecordSummary?
    @Published var lastError: String?

    private let keychain = PairingKeychain()

    init() {
        if let data = try? keychain.read() {
            summary = try? PairingRecordValidator.validate(data)
        }
    }

    func importRecord(from url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        let validated = try PairingRecordValidator.validate(data)
        try keychain.save(data)
        summary = validated
        lastError = nil
    }

    func exportDocument() throws -> PairingRecordDocument {
        guard let data = try keychain.read() else {
            throw PairingStoreError.noRecord
        }
        return PairingRecordDocument(data: data)
    }

    func deleteRecord() {
        do {
            try keychain.delete()
            summary = nil
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

enum PairingStoreError: LocalizedError {
    case noRecord

    var errorDescription: String? {
        "No pairing record is stored on this device. Import a valid lockdown or remote-pairing record first."
    }
}

struct PairingRecordDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.propertyList, .data] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw PairingStoreError.noRecord
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct PairingKeychain {
    private let service = "com.dopestore.pairing-record"
    private let account = "primary-device-record"

    func save(_ data: Data) throws {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func read() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        return result as? Data
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}

private struct KeychainError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown Keychain error"
        return "Keychain operation failed: \(message) (\(status))."
    }
}
