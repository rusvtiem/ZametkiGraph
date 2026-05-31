import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: VaultStore
    @State private var selectedID: String?
    @State private var showFolderPicker = false

    private var selectedNote: Note? {
        guard let id = selectedID else { return nil }
        return store.notes.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedID: $selectedID, showFolderPicker: $showFolderPicker)
        } detail: {
            if let note = selectedNote {
                NoteEditorView(note: note, selectedID: $selectedID)
                    .id(note.id)
            } else {
                ContentUnavailableState()
            }
        }
        .fileImporter(isPresented: $showFolderPicker,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.selectVault(url)
                selectedID = nil
            }
        }
    }
}

private struct ContentUnavailableState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Выбери заметку слева")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
