import SwiftUI

/// Панель связей текущей заметки (исходящие `[[...]]` + обратные backlinks).
/// Открывается как выезжающий лист, тап по связи — переход на заметку.
struct LinksPanel: View {
    @EnvironmentObject var store: VaultStore
    let note: Note?
    @Binding var selectedID: String?
    @Binding var isPresented: Bool

    private var outgoing: [String] { note.map { WikiLinkParser.links(in: $0.content) } ?? [] }
    private var backlinks: [Note] { note.map { store.backlinks(to: $0) } ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Связи").font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textFaint)
                }
                .buttonStyle(.plain)
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("Ссылается на", icon: "arrow.up.right") {
                        if outgoing.isEmpty {
                            hint("В заметке нет связей [[...]]")
                        } else {
                            ForEach(outgoing, id: \.self) { name in
                                linkRow(name, exists: store.note(titled: name) != nil)
                            }
                        }
                    }
                    section("Обратные связи", icon: "arrow.down.left") {
                        if backlinks.isEmpty {
                            hint("Никто не ссылается на эту заметку")
                        } else {
                            ForEach(backlinks) { src in
                                linkRow(src.title, exists: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
        .background(Theme.bgSidebar)
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, icon: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private func linkRow(_ name: String, exists: Bool) -> some View {
        Button {
            navigate(to: name)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: exists ? "doc.text" : "doc.badge.plus")
                Text(name)
                if !exists {
                    Text("создать").font(.caption2).foregroundStyle(Theme.textFaint)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(exists ? Theme.accent : Theme.textSecondary)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func hint(_ s: String) -> some View {
        Text(s).font(.caption).foregroundStyle(Theme.textFaint)
    }

    private func navigate(to name: String) {
        if let existing = store.note(titled: name) {
            selectedID = existing.id
        } else if let created = store.createNote(title: name) {
            selectedID = created.id
        }
        isPresented = false
    }
}
