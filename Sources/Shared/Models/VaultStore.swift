import Foundation
import SwiftUI

/// Хранилище заметок (vault) — папка с `.md` файлами.
///
/// Архитектурный принцип ТЗ: ДАННЫЕ (нейтральные `.md` файлы) отделены от способа
/// синхронизации. Этот класс знает только про локальную папку. Слой синхры —
/// отдельный, подключается позже, ядро не трогает.
@MainActor
final class VaultStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published private(set) var vaultURL: URL?
    @Published var search: String = ""

    private let bookmarkKey = "vaultBookmark"
    private var scopedURL: URL?  // активный security-scoped доступ к внешней папке

    // MARK: Запуск

    /// Восстановить ранее выбранную папку, иначе создать стандартное хранилище.
    func bootstrap() {
        if restoreBookmark() { return }
        openDefaultVault()
    }

    /// Стандартное хранилище внутри Documents — работает сразу, без выбора папки.
    /// На Mac и в iOS-симуляторе пишется без дополнительных разрешений.
    private func openDefaultVault() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let vault = docs.appendingPathComponent("ZametkiGraphVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        vaultURL = vault
        seedIfEmpty(in: vault)
        reload()
    }

    // MARK: Выбор внешней папки + сохранение доступа между запусками

    func selectVault(_ url: URL) {
        scopedURL?.stopAccessingSecurityScopedResource()
        let scoped = url.startAccessingSecurityScopedResource()
        scopedURL = scoped ? url : nil
        vaultURL = url
        saveBookmark(url)
        reload()
    }

    private func saveBookmark(_ url: URL) {
        #if os(macOS)
        let options: URL.BookmarkCreationOptions = [.withSecurityScope]
        #else
        let options: URL.BookmarkCreationOptions = []
        #endif
        if let data = try? url.bookmarkData(options: options,
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
    }

    /// Возвращает true, если папка успешно восстановлена.
    private func restoreBookmark() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return false }
        var stale = false
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope]
        #else
        let options: URL.BookmarkResolutionOptions = []
        #endif
        guard let url = try? URL(resolvingBookmarkData: data,
                                 options: options,
                                 relativeTo: nil,
                                 bookmarkDataIsStale: &stale) else { return false }
        let scoped = url.startAccessingSecurityScopedResource()
        scopedURL = scoped ? url : nil
        vaultURL = url
        if stale { saveBookmark(url) }
        reload()
        return true
    }

    // MARK: Чтение папки

    func reload() {
        guard let vault = vaultURL else { notes = []; return }
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        let items = (try? fm.contentsOfDirectory(at: vault,
                                                 includingPropertiesForKeys: keys,
                                                 options: [.skipsHiddenFiles])) ?? []
        var loaded: [Note] = []
        for url in items where url.pathExtension.lowercased() == "md" {
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            loaded.append(Note(url: url, content: content, modified: modified))
        }
        notes = loaded.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: CRUD

    @discardableResult
    func createNote(title rawTitle: String) -> Note? {
        guard let vault = vaultURL else { return nil }
        let base = sanitize(rawTitle).isEmpty ? "Без названия" : sanitize(rawTitle)
        var name = base
        var n = 1
        var url = vault.appendingPathComponent("\(name).md")
        while FileManager.default.fileExists(atPath: url.path) {
            n += 1
            name = "\(base) \(n)"
            url = vault.appendingPathComponent("\(name).md")
        }
        try? "".write(to: url, atomically: true, encoding: .utf8)
        reload()
        return notes.first { $0.url == url }
    }

    func save(_ note: Note, content: String) {
        try? content.write(to: note.url, atomically: true, encoding: .utf8)
        if let idx = notes.firstIndex(of: note) {
            notes[idx].content = content
            notes[idx].modified = Date()
        }
    }

    func delete(_ note: Note) {
        try? FileManager.default.removeItem(at: note.url)
        reload()
    }

    // MARK: Связи и поиск

    /// Заметка по заголовку (целевое имя из `[[...]]`).
    func note(titled title: String) -> Note? {
        notes.first { $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame }
    }

    /// Обратные связи: какие заметки ссылаются на данную через `[[Заголовок]]`.
    func backlinks(to note: Note) -> [Note] {
        notes.filter { candidate in
            candidate.url != note.url &&
            WikiLinkParser.links(in: candidate.content).contains {
                $0.localizedCaseInsensitiveCompare(note.title) == .orderedSame
            }
        }
    }

    // MARK: Теги

    /// Теги внутри заметки.
    func tags(of note: Note) -> [String] {
        WikiLinkParser.tags(in: note.content)
    }

    /// Все теги хранилища с числом заметок, по убыванию популярности.
    var allTags: [(tag: String, count: Int)] {
        var counts: [String: (display: String, n: Int)] = [:]
        for note in notes {
            for tag in WikiLinkParser.tags(in: note.content) {
                let key = tag.lowercased()
                let prev = counts[key]
                counts[key] = (prev?.display ?? tag, (prev?.n ?? 0) + 1)
            }
        }
        let list: [(tag: String, count: Int)] = counts.values.map { ($0.display, $0.n) }
        return list.sorted { a, b in
            if a.count != b.count { return a.count > b.count }
            return a.tag.localizedCaseInsensitiveCompare(b.tag) == .orderedAscending
        }
    }

    /// Заметки, содержащие данный тег (включая вложенные `parent/child`).
    func notes(withTag tag: String) -> [Note] {
        let needle = tag.lowercased()
        return notes.filter { note in
            WikiLinkParser.tags(in: note.content).contains {
                let t = $0.lowercased()
                return t == needle || t.hasPrefix(needle + "/")
            }
        }
    }

    /// Список заметок с учётом строки поиска (по заголовку и тексту).
    var filteredNotes: [Note] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return notes }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.content.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: Вспомогательное

    private func sanitize(_ s: String) -> String {
        let bad = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        return s.components(separatedBy: bad).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func seedIfEmpty(in vault: URL) {
        let fm = FileManager.default
        let existing = (try? fm.contentsOfDirectory(atPath: vault.path)) ?? []
        guard !existing.contains(where: { $0.hasSuffix(".md") }) else { return }
        let welcome = """
        # Добро пожаловать

        Это твоё хранилище заметок. Каждая заметка — отдельный файл `.md`.

        Способы связей, как в Obsidian:
        - `[[Музыка]]` — обычная связь: [[Музыка]]
        - `[[Музыка|алиас]]` — другое имя: [[Музыка|про звук]]
        - `#теги` — например #старт #пример
        - `![[Музыка]]` — вставка заметки целиком (эмбед)

        Открой **Граф** снизу — увидишь все заметки и теги связями.
        """
        let music = """
        # Музыка

        Заметка про музыкальную тему. Сюда позже подключим Блокнот Композитора. #музыка #пример

        Связь обратно: [[Добро пожаловать]]
        """
        try? welcome.write(to: vault.appendingPathComponent("Добро пожаловать.md"),
                           atomically: true, encoding: .utf8)
        try? music.write(to: vault.appendingPathComponent("Музыка.md"),
                        atomically: true, encoding: .utf8)
    }
}
