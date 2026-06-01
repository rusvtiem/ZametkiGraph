import Foundation

/// Музыкальный слой поверх общего хранилища. Музыкальные заметки — это те же `.md`
/// файлы в том же vault, но с шапкой `тип: музыка`. Благодаря единому хранилищу
/// связи `[[...]]` между обычными и музыкальными заметками работают сами собой.
extension VaultStore {
    /// Все музыкальные заметки (с парсенной шапкой), отсортированы по заголовку.
    var musicNotes: [(note: Note, meta: MusicMeta)] {
        notes.compactMap { note in
            guard let parsed = MusicMeta.parse(note.content) else { return nil }
            return (note, parsed.meta)
        }
    }

    /// Музыкальные заметки данного статуса.
    func musicNotes(status: MusicStatus) -> [Note] {
        musicNotes.filter { $0.meta.status == status }.map { $0.note }
    }

    /// Метаданные музыкальной заметки (nil — если заметка не музыкальная).
    func meta(of note: Note) -> MusicMeta? {
        MusicMeta.parse(note.content)?.meta
    }

    /// Тело музыкальной заметки без шапки.
    func body(of note: Note) -> String {
        MusicMeta.parse(note.content)?.body ?? note.content
    }

    /// Создаёт новую музыкальную заметку (пустое тело + шапка-черновик).
    @discardableResult
    func createMusicNote(title: String) -> Note? {
        guard let created = createNote(title: title) else { return nil }
        let content = MusicMeta().render(body: "")
        save(created, content: content)
        return note(titled: created.title)
    }

    /// Сохраняет музыкальную заметку: пересобирает файл из метаданных и тела.
    func saveMusic(_ note: Note, meta: MusicMeta, body: String) {
        save(note, content: meta.render(body: body))
    }

    // MARK: Текстовые заметки (для Блокнота — без музыкальных идей)

    /// Все НЕ музыкальные заметки. Блокнот показывает только их — музыка живёт
    /// отдельно в Композиторе, хотя физически это один общий vault.
    var textNotes: [Note] {
        notes.filter { meta(of: $0) == nil }
    }

    /// Текстовые заметки с учётом строки поиска (для списка Блокнота).
    var filteredTextNotes: [Note] {
        filteredNotes.filter { meta(of: $0) == nil }
    }

    /// Теги Блокнота — только из текстовых заметок (без тегов музыкальных идей).
    var textTags: [(tag: String, count: Int)] {
        var counts: [String: (display: String, n: Int)] = [:]
        for note in textNotes {
            for tag in WikiLinkParser.tags(in: note.content) {
                let key = tag.lowercased()
                let prev = counts[key]
                counts[key] = (prev?.display ?? tag, (prev?.n ?? 0) + 1)
            }
        }
        return counts.values.map { ($0.display, $0.n) }.sorted { a, b in
            if a.count != b.count { return a.count > b.count }
            return a.tag.localizedCaseInsensitiveCompare(b.tag) == .orderedAscending
        }
    }

    /// Текстовые заметки с данным тегом (для индекса тегов Блокнота).
    func textNotes(withTag tag: String) -> [Note] {
        notes(withTag: tag).filter { meta(of: $0) == nil }
    }
}
