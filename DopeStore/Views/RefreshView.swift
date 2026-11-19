import SwiftUI

struct RefreshView: View {
    @EnvironmentObject private var library: AppLibrary
    @EnvironmentObject private var diagnostics: DiagnosticsCenter

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InfoCard(title: "Refresh service", systemImage: "arrow.clockwise.circle") {
                        StatusBadge(title: "Backend not connected", systemImage: "pause.circle", color: .orange)
                        Text("A working refresh operation needs Apple account authentication, a signing/provisioning engine, and a reachable paired-device installation service. Those operations are not exposed by public iOS APIs to a standalone app.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    InfoCard(title: "Expiration monitor", systemImage: "calendar.badge.clock") {
                        if library.apps.isEmpty {
                            Text("No IPA files imported yet.").foregroundStyle(.secondary)
                        } else {
                            ForEach(library.apps) { app in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(app.name).font(.subheadline.weight(.medium))
                                        Spacer()
                                        StatusBadge(title: app.expirationStatus.title, systemImage: "questionmark.circle", color: .secondary)
                                    }
                                    Text(app.signingExpiration.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "No signed expiration available")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Button {
                        diagnostics.record("Refresh request", "Refresh was not started because no signing/installation backend is configured.")
                    } label: {
                        Label("Refresh all", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    Text("Refresh controls remain disabled until a real signing and installation provider is connected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Refresh")
        }
    }
}
