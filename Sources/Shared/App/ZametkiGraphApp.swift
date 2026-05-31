import SwiftUI

@main
struct ZametkiGraphApp: App {
    @StateObject private var store = VaultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { store.bootstrap() }
        }
    }
}
