import Foundation

/// Разбор связей `[[Имя заметки]]` внутри markdown — синтаксис как в Obsidian.
enum WikiLinkParser {
    private static let regex = try! NSRegularExpression(pattern: "\\[\\[([^\\]\\[]+)\\]\\]")

    /// Все имена заметок, на которые ссылается данный текст (без дублей, в порядке появления).
    static func links(in text: String) -> [String] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var result: [String] = []
        var seen = Set<String>()
        for match in regex.matches(in: text, range: range) {
            guard let r = Range(match.range(at: 1), in: text) else { continue }
            let name = text[r].trimmingCharacters(in: .whitespaces)
            if !name.isEmpty, seen.insert(name).inserted {
                result.append(name)
            }
        }
        return result
    }

    /// Диапазоны вхождений `[[...]]` — для кликабельной подсветки в редакторе/просмотре.
    /// Возвращает (диапазон всего токена включая скобки, имя цели).
    static func matches(in text: String) -> [(range: Range<String.Index>, target: String)] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var result: [(Range<String.Index>, String)] = []
        for match in regex.matches(in: text, range: range) {
            guard let full = Range(match.range, in: text),
                  let inner = Range(match.range(at: 1), in: text) else { continue }
            let name = text[inner].trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { result.append((full, name)) }
        }
        return result
    }

    private static let linkAllowed = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

    /// Превращает `[[Имя]]` в markdown-ссылку `[Имя](zametki://open?name=...)`,
    /// чтобы SwiftUI-рендер показал кликабельную ссылку в режиме чтения.
    static func markdownified(_ text: String) -> String {
        let ms = matches(in: text)
        guard !ms.isEmpty else { return text }
        var result = ""
        var idx = text.startIndex
        for m in ms {
            result += text[idx..<m.range.lowerBound]
            let enc = m.target.addingPercentEncoding(withAllowedCharacters: linkAllowed) ?? m.target
            result += "[\(m.target)](zametki://open?name=\(enc))"
            idx = m.range.upperBound
        }
        result += text[idx...]
        return result
    }
}
