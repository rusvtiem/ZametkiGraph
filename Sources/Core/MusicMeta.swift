import Foundation

/// Статус музыкальной идеи.
enum MusicStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "черновик"
    case inProgress = "в работе"
    case done = "готово"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .draft: return "pencil.line"
        case .inProgress: return "hammer"
        case .done: return "checkmark.seal"
        }
    }
}

/// Музыкальные метаданные заметки. Хранятся в шапке `.md` файла (frontmatter),
/// как в Obsidian — обычный текст, читается где угодно. Тело заметки (markdown
/// со связями `[[...]]` и тегами `#`) лежит после шапки и не дублируется здесь.
struct MusicMeta: Equatable {
    var tonality: String = ""      // тональность, напр. "Am", "C-dur"
    var tempo: String = ""         // темп, напр. "120" (BPM)
    var meter: String = ""         // размер, напр. "4/4"
    var instruments: String = ""   // состав, напр. "фортепиано, скрипка"
    var status: MusicStatus = .draft

    /// Маркер музыкальной заметки в шапке: `тип: музыка`.
    static let typeKey = "тип"
    static let typeValue = "музыка"
}

// MARK: - Frontmatter (шапка файла)

extension MusicMeta {
    /// Разбирает content на шапку (ключ: значение) и тело. Музыкальной считается
    /// заметка с `тип: музыка` в шапке — иначе возвращает nil.
    static func parse(_ content: String) -> (meta: MusicMeta, body: String)? {
        let (fields, body) = Frontmatter.split(content)
        guard fields[typeKey]?.lowercased() == typeValue else { return nil }

        var m = MusicMeta()
        m.tonality = fields["тональность"] ?? ""
        m.tempo = fields["темп"] ?? ""
        m.meter = fields["размер"] ?? ""
        m.instruments = fields["состав"] ?? ""
        if let s = fields["статус"], let st = MusicStatus(rawValue: s) { m.status = st }
        return (m, body)
    }

    /// Собирает полный content файла: шапка с музыкальными полями + тело.
    /// Пустые поля в шапку не пишем — файл остаётся чистым.
    func render(body: String) -> String {
        var fields: [(String, String)] = [(MusicMeta.typeKey, MusicMeta.typeValue)]
        if !tonality.isEmpty { fields.append(("тональность", tonality)) }
        if !tempo.isEmpty { fields.append(("темп", tempo)) }
        if !meter.isEmpty { fields.append(("размер", meter)) }
        if !instruments.isEmpty { fields.append(("состав", instruments)) }
        fields.append(("статус", status.rawValue))
        return Frontmatter.join(fields: fields, body: body)
    }
}

/// Минимальный парсер frontmatter в стиле Obsidian: блок между двумя строками `---`
/// в начале файла, внутри — простые пары `ключ: значение`. Без вложенности и списков —
/// этого хватает для музыкальных полей и сохраняет файл человекочитаемым.
enum Frontmatter {
    static func split(_ content: String) -> (fields: [String: String], body: String) {
        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return ([:], content)
        }
        var fields: [String: String] = [:]
        var i = 1
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                let body = lines[(i + 1)...].joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
                return (fields, body)
            }
            if let colon = line.firstIndex(of: ":") {
                let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colon)...])
                    .trimmingCharacters(in: .whitespaces)
                if !key.isEmpty { fields[key] = value }
            }
            i += 1
        }
        // Открытая, но не закрытая шапка — считаем, что её нет.
        return ([:], content)
    }

    static func join(fields: [(String, String)], body: String) -> String {
        var head = "---\n"
        for (k, v) in fields { head += "\(k): \(v)\n" }
        head += "---\n\n"
        return head + body
    }
}
