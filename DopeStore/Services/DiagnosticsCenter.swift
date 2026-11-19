import Foundation
import Combine

struct DiagnosticEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let category: String
    let message: String
    let details: String?

    init(category: String, message: String, details: String? = nil) {
        id = UUID()
        timestamp = Date()
        self.category = category
        self.message = message
        self.details = details
    }
}

@MainActor
final class DiagnosticsCenter: ObservableObject {
    @Published private(set) var events: [DiagnosticEvent] = []

    func record(_ category: String, _ message: String, details: String? = nil) {
        events.insert(DiagnosticEvent(category: category, message: message, details: details), at: 0)
        if events.count > 500 { events = Array(events.prefix(500)) }
    }

    func exportURL() throws -> URL {
        let payload = DiagnosticExport(
            createdAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            events: events
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DopeStore-Diagnostics.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}

private struct DiagnosticExport: Codable {
    let createdAt: Date
    let appVersion: String
    let osVersion: String
    let events: [DiagnosticEvent]
}
