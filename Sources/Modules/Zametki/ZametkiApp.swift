import SwiftUI

/// Модуль «Блокнот» во Вселенной: заметки `.md`, связи `[[...]]`, теги, граф.
/// Корневой экран — существующий `ContentView`.
struct ZametkiApp: UniverseApp {
    let id = "zametki"
    let title = "Заметки"
    let icon = "doc.text"

    func makeRootView() -> AnyView { AnyView(ContentView()) }
}
