import SwiftUI
import UniformTypeIdentifiers

struct AppsView: View {
    @EnvironmentObject private var library: AppLibrary
    @EnvironmentObject private var diagnostics: DiagnosticsCenter
    @State private var showingImporter = false
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if library.apps.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 38))
                            .foregroundStyle(.secondary)
                        Text("No imported apps").font(.headline)
                        Text("Import an IPA from Files or use the iOS share sheet to send one to DopeStore.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { showingImporter = true }) { Label("Import IPA", systemImage: "plus") }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else {
                    List {
                        Section {
                            ForEach(library.apps) { app in
                                appRow(app)
                            }
                            .onDelete { offsets in
                                offsets.map { library.apps[$0] }.forEach(library.remove)
                            }
                        } header: {
                            Text("Imported IPA library")
                        } footer: {
                            Text("These are files stored inside DopeStore. They are not proof that the apps are installed on iOS.")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingImporter = true } label: { Image(systemName: "plus") }
                        .disabled(isImporting)
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importIPA(url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .alert("Import failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .overlay {
                if isImporting {
                    ProgressView("Inspecting IPA…")
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    @ViewBuilder
    private func appRow(_ app: AppRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name).font(.headline)
                    Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Menu {
                    ShareLink(item: library.fileURL(for: app)) { Label("Share IPA", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { library.remove(app) } label: { Label("Remove", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
            HStack(spacing: 8) {
                Text("Version \(app.version) (\(app.buildNumber))")
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: app.fileSize, countStyle: .file))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            StatusBadge(title: "Not installed by DopeStore", systemImage: "tray", color: .orange)
            Text("Signing expiry: unknown — this IPA has not been signed by a connected backend.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func importIPA(_ url: URL) {
        guard url.pathExtension.lowercased() == "ipa" else {
            errorMessage = "Choose a file with the .ipa extension."
            return
        }
        isImporting = true
        Task {
            do {
                let record = try await library.importIPA(at: url)
                diagnostics.record("IPA import", "Imported \(record.bundleIdentifier) version \(record.version).")
            } catch {
                errorMessage = error.localizedDescription
                diagnostics.record("IPA import failed", error.localizedDescription)
            }
            isImporting = false
        }
    }
}
