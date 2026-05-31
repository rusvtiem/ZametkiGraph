import SwiftUI

/// Индекс тегов хранилища и заметки по выбранному тегу.
/// Открывается листом; тап по заметке открывает её и закрывает лист.
struct TagIndexView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool
    var initialTag: String?
    var onOpenNote: (String) -> Void

    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if store.allTags.isEmpty {
                    Text("Тегов пока нет. Добавь `#тег` в текст заметки.")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    ForEach(store.allTags, id: \.tag) { item in
                        NavigationLink(value: item.tag) {
                            HStack {
                                Label("#" + item.tag, systemImage: "number")
                                Spacer()
                                Text("\(item.count)").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Теги")
            .navigationDestination(for: String.self) { tag in
                tagNotes(tag)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { isPresented = false }
                }
            }
            .onAppear {
                if let initialTag, path.isEmpty { path = [initialTag] }
            }
        }
    }

    private func tagNotes(_ tag: String) -> some View {
        List {
            let hits = store.notes(withTag: tag)
            if hits.isEmpty {
                Text("Нет заметок с этим тегом").foregroundStyle(.secondary)
            } else {
                ForEach(hits) { note in
                    Button {
                        onOpenNote(note.title)
                        isPresented = false
                    } label: {
                        Label(note.title, systemImage: "doc.text")
                    }
                }
            }
        }
        .navigationTitle("#" + tag)
    }
}
