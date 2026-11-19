import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var pairingStore: PairingRecordStore
    @EnvironmentObject private var diagnostics: DiagnosticsCenter
    @EnvironmentObject private var connectivity: ConnectivityMonitor

    @State private var showPairingImporter = false
    @State private var showPairingExporter = false
    @State private var exportDocument: PairingRecordDocument?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Pairing certificate") {
                    LabeledContent("Status", value: pairingStore.summary?.hostIdentifier ?? "Not imported")
                    if let summary = pairingStore.summary {
                        LabeledContent("Record size", value: ByteCountFormatter.string(fromByteCount: Int64(summary.byteCount), countStyle: .file))
                        LabeledContent("Imported", value: summary.importedAt.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Certificate expiry", value: summary.certificateExpiration?.formatted(date: .abbreviated, time: .shortened) ?? "Not available")
                        Button("Export original pairing record", systemImage: "square.and.arrow.up") {
                            do {
                                exportDocument = try pairingStore.exportDocument()
                                showPairingExporter = true
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        Button("Remove pairing record", role: .destructive) {
                            pairingStore.deleteRecord()
                        }
                    } else {
                        Text("Import a pairing plist from Files. The record is validated and stored in the iOS Keychain.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Import pairing record", systemImage: "square.and.arrow.down") {
                        showPairingImporter = true
                    }
                }

                Section("Connection diagnostics") {
                    LabeledContent("Network", value: connectivity.interfaceDescription)
                    LabeledContent("Tunnel interfaces", value: connectivity.utunInterfaces.isEmpty ? "None detected" : connectivity.utunInterfaces.joined(separator: ", "))
                    Text("A network interface being present does not prove that a paired-device service is reachable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")
                    LabeledContent("Minimum iOS", value: "16.0")
                }
            }
            .navigationTitle("Settings")
            .fileImporter(isPresented: $showPairingImporter, allowedContentTypes: [.propertyList, .data], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    try pairingStore.importRecord(from: url)
                    diagnostics.record("Pairing", "Imported and validated a pairing record.")
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .fileExporter(isPresented: $showPairingExporter, document: exportDocument, contentType: .propertyList, defaultFilename: "DopeStore-PairingRecord") { result in
                if case .failure(let error) = result { errorMessage = error.localizedDescription }
            }
            .alert("DopeStore", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
}