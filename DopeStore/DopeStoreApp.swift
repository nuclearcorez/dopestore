import SwiftUI

@main
struct DopeStoreApp: App {
    @StateObject private var library = AppLibrary()
    @StateObject private var pairingStore = PairingRecordStore()
    @StateObject private var diagnostics = DiagnosticsCenter()
    @StateObject private var connectivity = ConnectivityMonitor()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(library)
                .environmentObject(pairingStore)
                .environmentObject(diagnostics)
                .environmentObject(connectivity)
                .onOpenURL { url in
                    Task { await handleIncomingURL(url) }
                }
        }
    }

    @MainActor
    private func handleIncomingURL(_ url: URL) async {
        let ext = url.pathExtension.lowercased()
        do {
            if ext == "ipa" {
                _ = try await library.importIPA(at: url)
                diagnostics.record("IPA import", "Imported an IPA through the Files/share handoff.")
            } else {
                try pairingStore.importRecord(from: url)
                diagnostics.record("Pairing", "Imported and validated a pairing record.")
            }
        } catch {
            diagnostics.record("Import error", error.localizedDescription)
            library.lastMessage = error.localizedDescription
            pairingStore.lastError = error.localizedDescription
        }
    }
}
