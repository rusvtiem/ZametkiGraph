import SwiftUI

/// Боковая панель (как файловый проводник Obsidian): поиск сверху + список заметок.
struct SidebarView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    @Binding var selectedID: String?
    var onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            Divider().overlay(theme.divider)
            list
        }
        .background(theme.bgSidebar)
    }

    private var header: some View {
        HStack {
            Text("Заметки")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Button {
                if let note = store.createNote(title: "Новая заметка") {
                    selectedID = note.id
                    onSelect()
                }
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(theme.textFaint)
            TextField("Поиск", text: $store.search)
                .textFieldStyle(.plain)
                .foregroundStyle(theme.textPrimary)
            if !store.search.isEmpty {
                Button { store.search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(theme.textFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(theme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(store.filteredNotes) { note in
                    row(note)
                }
                if store.filteredNotes.isEmpty {
                    Text(store.search.isEmpty ? "Пока нет заметок" : "Ничего не найдено")
                        .font(.caption)
                        .foregroundStyle(theme.textFaint)
                        .padding()
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func row(_ note: Note) -> some View {
        Button {
            selectedID = note.id
            onSelect()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)
                Text(note.title)
                    .lineLimit(1)
                    .foregroundStyle(theme.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(selectedID == note.id ? theme.accent.opacity(0.22) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                if selectedID == note.id { selectedID = nil }
                store.delete(note)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}
