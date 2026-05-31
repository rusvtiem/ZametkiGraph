import SwiftUI

/// Режим «правка»: сырой markdown в редакторе. Автосохранение в файл при изменении.
struct EditorPane: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    let note: Note
    @State private var text: String = ""

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(theme.textPrimary)
            .scrollContentBackground(.hidden)
            .background(theme.bg)
            .padding(12)
            .onAppear { text = note.content }
            .onChange(of: text) { _, newValue in
                store.save(note, content: newValue)
            }
    }
}
