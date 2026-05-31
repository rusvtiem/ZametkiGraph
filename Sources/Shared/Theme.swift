import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// Палитра в духе тёмной темы Obsidian.
enum Theme {
    static let bg = Color(hex: 0x1E1E1E)          // основной фон редактора
    static let bgSidebar = Color(hex: 0x252525)   // боковая панель
    static let bgElevated = Color(hex: 0x2D2D2D)  // поля поиска / кнопки
    static let textPrimary = Color(hex: 0xDADADA)
    static let textSecondary = Color(hex: 0x999999)
    static let textFaint = Color(hex: 0x6E6E6E)
    static let accent = Color(hex: 0xA98BFF)       // фиолетовый акцент Obsidian
    static let divider = Color(hex: 0x363636)
}
