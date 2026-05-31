import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject var store: VaultStore
    let note: Note
    @Binding var selectedID: String?

    @State private var text: String = ""

    private var outgoing: [String] { WikiLinkParser.links(in: text) }
    private var backlinks: [Note] { store.backlinks(to: note) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .onChange(of: text) { _, newValue in
                    store.save(note, content: newValue)
                }

            Divider()
            linksPanel
                .padding(12)
                .frame(maxHeight: 220)
        }
        .navigationTitle(note.title)
        .onAppear { text = note.content }
    }

    private var linksPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                linkSection(title: "Связи в заметке", icon: "arrow.up.right.square") {
                    if outgoing.isEmpty {
                        emptyHint("Напиши [[Имя заметки]] чтобы создать связь")
                    } else {
                        ForEach(outgoing, id: \.self) { name in
                            linkButton(name, exists: store.note(titled: name) != nil)
                        }
                    }
                }

                linkSection(title: "Обратные связи", icon: "arrow.down.left.square") {
                    if backlinks.isEmpty {
                        emptyHint("Пока никто не ссылается на эту заметку")
                    } else {
                        ForEach(backlinks) { src in
                            linkButton(src.title, exists: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func linkSection<Content: View>(title: String, icon: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func linkButton(_ name: String, exists: Bool) -> some View {
        Button {
            navigate(to: name)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: exists ? "doc.text" : "doc.badge.plus")
                Text(name)
                if !exists { Text("создать").font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(exists ? Color.accentColor : .secondary)
    }

    private func emptyHint(_ s: String) -> some View {
        Text(s).font(.caption).foregroundStyle(.tertiary)
    }

    /// Переход по связи: если заметка есть — открыть, если нет — создать и открыть.
    private func navigate(to name: String) {
        if let existing = store.note(titled: name) {
            selectedID = existing.id
        } else if let created = store.createNote(title: name) {
            selectedID = created.id
        }
    }
}
