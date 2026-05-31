import Foundation

/// Одна связь `[[...]]` со всеми вариантами синтаксиса Obsidian.
struct WikiLink {
    let range: Range<String.Index>  // весь токен, включая скобки (и `!` для эмбеда)
    let target: String              // имя заметки
    let heading: String?            // часть после `#`
    let alias: String?              // часть после `|`
    let isEmbed: Bool               // ведущий `!` — вставка содержимого

    /// Что показывать пользователю.
    var display: String {
        if let alias { return alias }
        if let heading { return "\(target) › \(heading)" }
        return target
    }
}

/// Разбор связей markdown — синтаксис как в Obsidian:
/// `[[Заметка]]`, `[[Заметка|алиас]]`, `[[Заметка#Заголовок]]`,
/// `![[Заметка]]` (эмбед) и `#хештеги`.
enum WikiLinkParser {
    // !?  [[ target (#heading)? (|alias)? ]]
    private static let wikiRegex = try! NSRegularExpression(
        pattern: "(!?)\\[\\[([^\\]\\[#|]+)(?:#([^\\]\\[|]+))?(?:\\|([^\\]\\[]+))?\\]\\]")

    // #тег: не внутри слова/ссылки, начинается с буквы или _, допускает вложенность a/b
    private static let tagRegex = try! NSRegularExpression(
        pattern: "(?<![\\w/#])#([\\p{L}_][\\p{L}0-9_/-]*)")

    private static let linkAllowed = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: linkAllowed) ?? s
    }

    // MARK: Связи [[...]]

    static func wikiLinks(in text: String) -> [WikiLink] {
        let ns = NSRange(text.startIndex..<text.endIndex, in: text)
        var out: [WikiLink] = []
        for m in wikiRegex.matches(in: text, range: ns) {
            guard let full = Range(m.range, in: text) else { continue }
            func grp(_ i: Int) -> String? {
                let r = m.range(at: i)
                guard r.location != NSNotFound, let rr = Range(r, in: text) else { return nil }
                let s = text[rr].trimmingCharacters(in: .whitespaces)
                return s.isEmpty ? nil : s
            }
            guard let target = grp(2) else { continue }
            out.append(WikiLink(range: full, target: target,
                                heading: grp(3), alias: grp(4),
                                isEmbed: grp(1) == "!"))
        }
        return out
    }

    /// Имена заметок, на которые ссылается текст (без дублей, в порядке появления).
    /// Используется для backlinks и графа.
    static func links(in text: String) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for l in wikiLinks(in: text) where seen.insert(l.target.lowercased()).inserted {
            out.append(l.target)
        }
        return out
    }

    // MARK: Хештеги

    static func tagMatches(in text: String) -> [(range: Range<String.Index>, tag: String)] {
        let ns = NSRange(text.startIndex..<text.endIndex, in: text)
        var out: [(Range<String.Index>, String)] = []
        for m in tagRegex.matches(in: text, range: ns) {
            guard let full = Range(m.range, in: text),
                  let inner = Range(m.range(at: 1), in: text) else { continue }
            out.append((full, String(text[inner])))
        }
        return out
    }

    /// Уникальные теги текста (порядок появления, без `#`).
    static func tags(in text: String) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for (_, tag) in tagMatches(in: text) where seen.insert(tag.lowercased()).inserted {
            out.append(tag)
        }
        return out
    }

    // MARK: Рендер в кликабельный markdown

    /// `[[...]]` и `#теги` → markdown-ссылки на схемы `zametki://open` / `zametki://tag`.
    /// Эмбеды `![[...]]` блок-уровневые — их обрабатывает MarkdownReadingView,
    /// здесь они показываются как обычная ссылка-фолбэк.
    static func markdownified(_ text: String) -> String {
        struct Tok { let range: Range<String.Index>; let md: String }
        var toks: [Tok] = []

        for l in wikiLinks(in: text) {
            let path = l.target + (l.heading.map { "#\($0)" } ?? "")
            toks.append(Tok(range: l.range,
                            md: "[\(l.display)](zametki://open?name=\(encode(path)))"))
        }
        for (r, tag) in tagMatches(in: text) {
            toks.append(Tok(range: r, md: "[#\(tag)](zametki://tag?name=\(encode(tag)))"))
        }
        guard !toks.isEmpty else { return text }

        toks.sort { $0.range.lowerBound < $1.range.lowerBound }
        var result = ""
        var idx = text.startIndex
        for t in toks where t.range.lowerBound >= idx {
            result += text[idx..<t.range.lowerBound]
            result += t.md
            idx = t.range.upperBound
        }
        result += text[idx...]
        return result
    }
}
