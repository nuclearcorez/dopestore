import Foundation
import Combine

@MainActor
final class AppLibrary: ObservableObject {
    @Published private(set) var apps: [AppRecord] = []
    @Published var lastMessage: String?

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var importsDirectory: URL {
        documentsDirectory.appendingPathComponent("ImportedIPAs", isDirectory: true)
    }

    private var indexURL: URL {
        documentsDirectory.appendingPathComponent("app-library.json")
    }

    init() {
        try? fileManager.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
        load()
    }

    func importIPA(at sourceURL: URL) async throws -> AppRecord {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let metadata = try await Task.detached(priority: .userInitiated) {
            try IPAMetadataReader.read(from: sourceURL)
        }.value

        let storedName = "\(UUID().uuidString).ipa"
        let destination = importsDirectory.appendingPathComponent(storedName)
        try fileManager.copyItem(at: sourceURL, to: destination)
        let attributes = try fileManager.attributesOfItem(atPath: destination.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0

        let record = AppRecord(
            id: UUID(),
            name: metadata.name,
            bundleIdentifier: metadata.bundleIdentifier,
            version: metadata.version,
            buildNumber: metadata.buildNumber,
            fileName: storedName,
            fileSize: size,
            importedAt: Date(),
            signingExpiration: nil
        )

        if let existingIndex = apps.firstIndex(where: { $0.bundleIdentifier == record.bundleIdentifier && $0.version == record.version }) {
            let oldFile = fileURL(for: apps[existingIndex])
            try? fileManager.removeItem(at: oldFile)
            apps[existingIndex] = record
        } else {
            apps.insert(record, at: 0)
        }
        try persist()
        lastMessage = "Imported \(record.name)."
        return record
    }

    func remove(_ record: AppRecord) {
        apps.removeAll { $0.id == record.id }
        try? fileManager.removeItem(at: fileURL(for: record))
        do {
            try persist()
            lastMessage = "Removed \(record.name) from the DopeStore library."
        } catch {
            lastMessage = "Could not update the library: \(error.localizedDescription)"
        }
    }

    func fileURL(for record: AppRecord) -> URL {
        importsDirectory.appendingPathComponent(record.fileName)
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? decoder.decode([AppRecord].self, from: data) else {
            apps = []
            return
        }
        apps = decoded.filter { fileManager.fileExists(atPath: fileURL(for: $0).path) }
    }

    private func persist() throws {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(apps)
        try data.write(to: indexURL, options: .atomic)
    }
}
