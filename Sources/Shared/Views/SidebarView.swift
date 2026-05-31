import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: VaultStore
    @Binding var selectedID: String?
    @Binding var showFolderPicker: Bool

    var body: some View {
        List(selection: $selectedID) {
            ForEach(store.filteredNotes) { note in
                NavigationLink(value: note.id) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title).lineLimit(1)
                        Text(preview(note))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        delete(note)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
        .searchable(text: $store.search, prompt: "Поиск по заметкам")
        .navigationTitle("Заметки")
        .toolbar {
            ToolbarItem {
                Button {
                    if let note = store.createNote(title: "Новая заметка") {
                        selectedID = note.id
                    }
                } label: {
                    Label("Новая заметка", systemImage: "square.and.pencil")
                }
            }
            ToolbarItem {
                Button {
                    showFolderPicker = true
                } label: {
                    Label("Выбрать папку", systemImage: "folder")
                }
            }
        }
    }

    private func delete(_ note: Note) {
        if selectedID == note.id { selectedID = nil }
        store.delete(note)
    }

    private func preview(_ note: Note) -> String {
        let firstLine = note.content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first.map(String.init) ?? ""
        return firstLine.replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
