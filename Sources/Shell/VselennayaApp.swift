import SwiftUI

@main
struct VselennayaApp: App {
    @StateObject private var store = VaultStore()
    @StateObject private var theme = ThemeManager()

    /// Реестр приложений Вселенной. Новое приложение = новый модуль в этом списке.
    private let apps: [any UniverseApp] = [
        ZametkiApp(),
    ]

    var body: some Scene {
        WindowGroup {
            UniverseShellView(apps: apps)
                .environmentObject(store)
                .environmentObject(theme)
                .onAppear {
                    store.bootstrap()
                    theme.loadCustomThemes(from: store.vaultURL)
                    #if os(macOS)
                    WindowPlacer.ensureOnScreen()
                    #endif
                }
                .onChange(of: store.vaultURL) { _, url in
                    theme.loadCustomThemes(from: url)
                }
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentSize)
        #endif
    }
}

#if os(macOS)
import AppKit

/// Подстраховка от «потерянного» окна: если сохранённая позиция увела окно за
/// пределы экрана (бывает после смены layout'а), возвращаем его в центр.
enum WindowPlacer {
    static func ensureOnScreen() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.isVisible || $0.canBecomeMain }) else { return }
            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
            if window.frame.width < 200 || window.frame.height < 200 || !visible.intersects(window.frame) {
                window.setContentSize(NSSize(width: 980, height: 680))
                window.center()
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
#endif
