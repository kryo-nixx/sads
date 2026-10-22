import SwiftUI
import SwiftData

enum KRYTab: String, CaseIterable {
    case home = "Home"
    case album = "Album"
    case chat = "Chat"
    case map = "Map"
    case us = "Us"
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var router = AppRouter()
    @Query private var settings: [AppSettingsModel]

    var body: some View {
        TabView(selection: $router.tab) {
            HomeView().tag(KRYTab.home).tabItem { Label("Home", systemImage: router.tab == .home ? "house.fill" : "house") }
            AlbumView().tag(KRYTab.album).tabItem { Label("Album", systemImage: router.tab == .album ? "rectangle.stack.fill" : "rectangle.stack") }
            ChatView().tag(KRYTab.chat).tabItem { Label("Chat", systemImage: router.tab == .chat ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right") }
            CoupleMapView().tag(KRYTab.map).tabItem { Label("Map", systemImage: router.tab == .map ? "map.fill" : "map") }
            UsView().tag(KRYTab.us).tabItem { Label("Us", systemImage: router.tab == .us ? "person.crop.circle.fill" : "person.crop.circle") }
        }
        .environmentObject(router)
        .tint(KRYTheme.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: router.tab)
        .onAppear { SeedManager.seedIfNeeded(context) }
        .preferredColorScheme(settings.first?.theme == "Midnight" ? .dark : .light)
    }
}
