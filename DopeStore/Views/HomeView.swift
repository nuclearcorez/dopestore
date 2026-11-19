import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var library: AppLibrary
    @EnvironmentObject private var pairingStore: PairingRecordStore
    @EnvironmentObject private var connectivity: ConnectivityMonitor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricCard("Tracked apps", value: "\(library.apps.count)", icon: "square.stack.3d.up")
                        metricCard("Pairing", value: pairingStore.summary == nil ? "Missing" : "Imported", icon: "lock.shield")
                    }
                    InfoCard(title: "Device", systemImage: "iphone") {
                        detail("Model", PlatformCapabilities.deviceModel)
                        detail("iOS", UIDevice.current.systemVersion)
                        detail("Network", connectivity.interfaceDescription)
                    }
                    InfoCard(title: "Signing", systemImage: "signature") {
                        StatusBadge(title: "Signing engine not connected", systemImage: "exclamationmark.circle", color: .orange)
                        Text("DopeStore can import and inspect IPA files, but cannot sign or install another app until a compatible signed-device bridge is integrated.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    InfoCard(title: "Refresh", systemImage: "arrow.clockwise") {
                        StatusBadge(title: "Refresh unavailable", systemImage: "pause.circle", color: .orange)
                        Text("Signing expirations are shown only when a trusted signing backend supplies them. Imported IPA files do not have a device signing expiry yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("DopeStore")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your apps. Your device.")
                .font(.title2.bold())
            Text("iOS 16.7.16-first sideloading workspace")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricCard(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(.tint)
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func detail(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
