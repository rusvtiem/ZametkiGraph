import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }

    init(hexString: String) {
        let s = hexString.trimmingCharacters(in: CharacterSet(charactersIn: " #"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(hex: UInt(v))
    }
}

/// Описание темы — как манифест темы в Obsidian: метаданные + палитра.
/// Хранится файлом `.json`, встроенные темы живут в коде, пользовательские —
/// в папке `themes/` внутри vault'а.
struct ThemePalette: Identifiable, Equatable, Codable {
    var id: String { name }

    let name: String
    let author: String
    let license: String
    let url: String
    let isDark: Bool

    // Цвета как hex-строки "#RRGGBB" — чтобы тема была обычным текстовым файлом.
    let bg: String
    let bgSidebar: String
    let bgElevated: String
    let textPrimary: String
    let textSecondary: String
    let textFaint: String
    let accent: String
    let divider: String
}

extension ThemePalette {
    var bgColor: Color { Color(hexString: bg) }
    var bgSidebarColor: Color { Color(hexString: bgSidebar) }
    var bgElevatedColor: Color { Color(hexString: bgElevated) }
    var textPrimaryColor: Color { Color(hexString: textPrimary) }
    var textSecondaryColor: Color { Color(hexString: textSecondary) }
    var textFaintColor: Color { Color(hexString: textFaint) }
    var accentColor: Color { Color(hexString: accent) }
    var dividerColor: Color { Color(hexString: divider) }
}

// MARK: - Встроенные темы (авторство ZametkiGraph, без сторонних лицензий)

extension ThemePalette {
    static let builtIn: [ThemePalette] = [obsidianDark, obsidianLight, sepia, midnight]

    static let obsidianDark = ThemePalette(
        name: "Обсидиан Тёмная", author: "ZametkiGraph",
        license: "Встроенная · свободно", url: "", isDark: true,
        bg: "#1E1E1E", bgSidebar: "#252525", bgElevated: "#2D2D2D",
        textPrimary: "#DADADA", textSecondary: "#999999", textFaint: "#6E6E6E",
        accent: "#A98BFF", divider: "#363636")

    static let obsidianLight = ThemePalette(
        name: "Обсидиан Светлая", author: "ZametkiGraph",
        license: "Встроенная · свободно", url: "", isDark: false,
        bg: "#FFFFFF", bgSidebar: "#F6F6F6", bgElevated: "#ECECEC",
        textPrimary: "#1A1A1A", textSecondary: "#5C5C5C", textFaint: "#9B9B9B",
        accent: "#7B6CD9", divider: "#E0E0E0")

    static let sepia = ThemePalette(
        name: "Сепия", author: "ZametkiGraph",
        license: "Встроенная · свободно", url: "", isDark: false,
        bg: "#F4ECD8", bgSidebar: "#EDE4CF", bgElevated: "#E3D8BE",
        textPrimary: "#4A3F2F", textSecondary: "#6F6048", textFaint: "#A2906C",
        accent: "#9A6E3F", divider: "#D9CDB0")

    static let midnight = ThemePalette(
        name: "Полночь", author: "ZametkiGraph",
        license: "Встроенная · свободно", url: "", isDark: true,
        bg: "#0D1117", bgSidebar: "#161B22", bgElevated: "#21262D",
        textPrimary: "#C9D1D9", textSecondary: "#8B949E", textFaint: "#6E7681",
        accent: "#A98BFF", divider: "#30363D")
}

// MARK: - Менеджер тем

/// Хранит активную палитру и список доступных тем (встроенные + пользовательские
/// из `themes/*.json`). Выбор сохраняется между запусками.
@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var palette: ThemePalette
    @Published private(set) var available: [ThemePalette]

    private let defaultsKey = "selectedThemeName"

    init() {
        let saved = UserDefaults.standard.string(forKey: defaultsKey)
        let start = ThemePalette.builtIn.first { $0.name == saved } ?? .obsidianDark
        self.palette = start
        self.available = ThemePalette.builtIn
    }

    func select(_ p: ThemePalette) {
        palette = p
        UserDefaults.standard.set(p.name, forKey: defaultsKey)
    }

    /// Подхватывает пользовательские темы из `<vault>/themes/*.json`.
    /// Файл — это ThemePalette в JSON. Битые файлы тихо пропускаем.
    func loadCustomThemes(from vaultURL: URL?) {
        var all = ThemePalette.builtIn
        if let vaultURL {
            let dir = vaultURL.appendingPathComponent("themes", isDirectory: true)
            let files = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.pathExtension.lowercased() == "json" {
                if let data = try? Data(contentsOf: file),
                   let p = try? JSONDecoder().decode(ThemePalette.self, from: data) {
                    all.append(p)
                }
            }
        }
        available = all
        // Если активная тема пропала (удалили файл) — откат на дефолт.
        if !all.contains(where: { $0.name == palette.name }) {
            select(.obsidianDark)
        } else if let refreshed = all.first(where: { $0.name == palette.name }) {
            palette = refreshed
        }
    }

    // Удобные акцессоры цветов активной темы.
    var bg: Color { palette.bgColor }
    var bgSidebar: Color { palette.bgSidebarColor }
    var bgElevated: Color { palette.bgElevatedColor }
    var textPrimary: Color { palette.textPrimaryColor }
    var textSecondary: Color { palette.textSecondaryColor }
    var textFaint: Color { palette.textFaintColor }
    var accent: Color { palette.accentColor }
    var divider: Color { palette.dividerColor }
}
