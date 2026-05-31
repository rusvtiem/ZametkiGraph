import SwiftUI

@main
struct ZametkiGraphApp: App {
    @StateObject private var store = VaultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    store.bootstrap()
                    #if os(macOS)
                    WindowPlacer.ensureOnScreen()
                    #endif
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
