import SwiftUI

struct JITView: View {
    @EnvironmentObject private var library: AppLibrary

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InfoCard(title: "JIT availability", systemImage: "bolt.fill") {
                        StatusBadge(title: "Not granted", systemImage: "bolt.slash", color: .orange)
                        Text("This app cannot grant JIT to other processes through public iOS APIs. JIT activation requires a supported developer/pairing mechanism and the appropriate OS/device state.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    InfoCard(title: "Activation engine", systemImage: "cpu") {
                        Label("No JIT activation backend is integrated", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                        Text("DopeStore will not display JIT as enabled unless an activation provider confirms the target process has received the required permission.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    InfoCard(title: "Tracked apps", systemImage: "app.badge") {
                        if library.apps.isEmpty {
                            Text("Import an IPA to add it to the local library.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(library.apps) { app in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(app.name).font(.subheadline.weight(.medium))
                                        Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    StatusBadge(title: "Not detected", systemImage: "minus.circle", color: .secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("JIT")
        }
    }
}
