import SwiftUI

/// Каталог Композитора: музыкальные идеи, сгруппированные по статусу.
/// Создание / открытие / удаление. Открытая идея редактируется в `MusicNoteEditorView`.
struct KatalogView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    @State private var path: [Note] = []
    @State private var askName = false
    @State private var newName = ""

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(theme.bg)
                .navigationTitle("Композитор")
                .navigationDestination(for: Note.self) { note in
                    MusicNoteEditorView(note: note)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { newName = ""; askName = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .alert("Новая музыкальная идея", isPresented: $askName) {
                    TextField("Название", text: $newName)
                    Button("Создать") { create() }
                    Button("Отмена", role: .cancel) {}
                } message: {
                    Text("Как назвать идею? Название = имя файла.")
                }
        }
        .tint(theme.accent)
        .preferredColorScheme(theme.palette.isDark ? .dark : .light)
    }

    @ViewBuilder
    private var content: some View {
        if store.musicNotes.isEmpty {
            emptyState
        } else {
            List {
                ForEach(MusicStatus.allCases) { status in
                    let items = store.musicNotes(status: status)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { note in
                                row(note)
                            }
                            .onDelete { offsets in delete(items, offsets) }
                        } header: {
                            Label(status.title, systemImage: status.icon)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.bg)
        }
    }

    private func row(_ note: Note) -> some View {
        NavigationLink(value: note) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                if let meta = store.meta(of: note) {
                    let line = summary(meta)
                    if !line.isEmpty {
                        Text(line)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowBackground(theme.bgElevated)
    }

    private func summary(_ m: MusicMeta) -> String {
        var parts: [String] = []
        if !m.tonality.isEmpty { parts.append(m.tonality) }
        if !m.tempo.isEmpty { parts.append("♩=\(m.tempo)") }
        if !m.meter.isEmpty { parts.append(m.meter) }
        if !m.instruments.isEmpty { parts.append(m.instruments) }
        return parts.joined(separator: " · ")
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.system(size: 42))
                .foregroundStyle(theme.textFaint)
            Text("Пока нет музыкальных идей")
                .foregroundStyle(theme.textSecondary)
            Button("Создать первую") { newName = ""; askName = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let created = store.createMusicNote(title: name.isEmpty ? "Новая идея" : name)
        else { return }
        // Открываем созданную идею после того, как алерт закроется: переход из
        // действия алерта iOS теряет, отложенный append отрабатывает надёжно.
        DispatchQueue.main.async { path.append(created) }
    }

    private func delete(_ items: [Note], _ offsets: IndexSet) {
        for i in offsets { store.delete(items[i]) }
    }
}
