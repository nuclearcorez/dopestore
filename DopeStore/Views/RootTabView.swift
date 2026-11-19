import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            AppsView()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2.fill") }
            JITView()
                .tabItem { Label("JIT", systemImage: "bolt.fill") }
            RefreshView()
                .tabItem { Label("Refresh", systemImage: "arrow.clockwise") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.38, green: 0.82, blue: 0.69))
    }
}
