import Foundation

/// Одна заметка = один файл `.md` в хранилище (vault).
/// Имя файла без расширения = заголовок заметки (как в Obsidian).
struct Note: Identifiable, Hashable {
    let url: URL
    var title: String
    var content: String
    var modified: Date

    /// id привязан к имени файла — стабилен пока заметку не переименовали/удалили.
    var id: String { title }

    init(url: URL, content: String, modified: Date) {
        self.url = url
        self.title = url.deletingPathExtension().lastPathComponent
        self.content = content
        self.modified = modified
    }

    static func == (lhs: Note, rhs: Note) -> Bool { lhs.url == rhs.url }
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
}
