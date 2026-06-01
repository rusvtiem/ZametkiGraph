import SwiftUI

/// Модуль «Композитор» во Вселенной — музыкальный слой поверх общего фундамента.
/// Корневой экран — каталог музыкальных идей (`KatalogView`).
struct KompozitorApp: UniverseApp {
    let id = "kompozitor"
    let title = "Композитор"
    let icon = "music.note"

    func makeRootView() -> AnyView { AnyView(KatalogView()) }
}
