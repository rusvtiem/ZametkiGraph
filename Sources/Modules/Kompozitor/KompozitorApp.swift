import SwiftUI

/// Модуль «Композитор» во Вселенной — музыкальный слой поверх общего фундамента.
/// Этап 2: вкладка встроена в оболочку, корневой экран — каркас. Музыкальные функции
/// (что именно Композитор умеет) наполняются следующим этапом по отдельному ТЗ.
struct KompozitorApp: UniverseApp {
    let id = "kompozitor"
    let title = "Композитор"
    let icon = "music.note"

    func makeRootView() -> AnyView { AnyView(KompozitorRootView()) }
}

private struct KompozitorRootView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.accent)
                    Text("Композитор")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }

                Text("Музыкальный модуль Вселенной. Здесь будет работа с музыкальными идеями: темы, фрагменты, произведения — связанные между собой и с заметками из Блокнота.")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(theme.divider)

                Text("Каркас готов")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("Вкладка встроена в оболочку и переключается рядом с «Заметки». Чем наполнить Композитор первым — определяем следующим ТЗ.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.bg)
    }
}
