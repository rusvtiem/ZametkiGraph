import SwiftUI

/// Режим «правка»: сырой markdown в редакторе. Автосохранение в файл при изменении.
struct EditorPane: View {
    @EnvironmentObject var store: VaultStore
    let note: Note
    @State private var text: String = ""

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(Theme.textPrimary)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .padding(12)
            .onAppear { text = note.content }
            .onChange(of: text) { _, newValue in
                store.save(note, content: newValue)
            }
    }
}
