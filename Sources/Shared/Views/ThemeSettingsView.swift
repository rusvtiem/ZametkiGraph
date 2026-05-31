import SwiftUI

/// Экран выбора темы (как «Внешний вид» в Obsidian): список доступных тем
/// с превью, отметка активной, переход на экран лицензий.
struct ThemePickerView: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(theme.available) { palette in
                        row(palette)
                    }
                } footer: {
                    Text("Свои темы: положи файл `.json` в папку `themes/` внутри хранилища заметок — появятся здесь.")
                        .font(.caption)
                }

                Section {
                    NavigationLink {
                        LicensesView(isPresented: $isPresented)
                    } label: {
                        Label("Темы и лицензии", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }
            .navigationTitle("Темы оформления")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { isPresented = false }
                }
            }
        }
    }

    private func row(_ palette: ThemePalette) -> some View {
        Button {
            theme.select(palette)
        } label: {
            HStack(spacing: 12) {
                swatch(palette)
                VStack(alignment: .leading, spacing: 2) {
                    Text(palette.name).foregroundStyle(.primary)
                    Text(palette.author).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if palette.name == theme.palette.name {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
        }
    }

    /// Мини-превью палитры: фон + полоски текста + точка акцента.
    private func swatch(_ p: ThemePalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(p.bgColor)
            VStack(alignment: .leading, spacing: 3) {
                RoundedRectangle(cornerRadius: 1).fill(p.textPrimaryColor).frame(width: 22, height: 3)
                RoundedRectangle(cornerRadius: 1).fill(p.textSecondaryColor).frame(width: 14, height: 3)
                Circle().fill(p.accentColor).frame(width: 6, height: 6)
            }
        }
        .frame(width: 40, height: 34)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(p.dividerColor, lineWidth: 1))
    }
}

/// Экран лицензий: на каждую установленную тему — автор, лицензия, ссылка.
/// Гибрид модели Obsidian (метаданные на тему) и «Блокнота Композитора»
/// (отдельный экран с текстом лицензий).
struct LicensesView: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool

    var body: some View {
        List {
            Section {
                Text("Встроенные темы созданы для ZametkiGraph и распространяются свободно. Темы, добавленные вами, показывают лицензию своего автора.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(theme.available) { p in
                Section(p.name) {
                    labeled("Автор", p.author)
                    labeled("Лицензия", p.license)
                    if !p.url.isEmpty {
                        labeled("Источник", p.url)
                    }
                }
            }
        }
        .navigationTitle("Темы и лицензии")
    }

    private func labeled(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
