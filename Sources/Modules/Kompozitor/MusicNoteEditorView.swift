import SwiftUI

/// Редактор музыкальной идеи: параметры (тональность/темп/размер/состав/статус),
/// текстовое описание (markdown со связями `[[...]]`) и обратные связи.
/// Любое изменение автосохраняется в файл.
struct MusicNoteEditorView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    let note: Note

    @State private var meta = MusicMeta()
    @State private var body_ = ""
    @State private var loaded = false

    var body: some View {
        Form {
            paramsSection
            descriptionSection
            backlinksSection
        }
        .scrollContentBackground(.hidden)
        .background(theme.bg)
        .navigationTitle(note.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: load)
        .onChange(of: meta) { _, _ in persist() }
        .onChange(of: body_) { _, _ in persist() }
    }

    // MARK: Секции

    private var paramsSection: some View {
        Section {
            field("Тональность", text: $meta.tonality, placeholder: "напр. Am")
            field("Темп (BPM)", text: $meta.tempo, placeholder: "напр. 120", number: true)
            field("Размер", text: $meta.meter, placeholder: "напр. 4/4")
            field("Состав", text: $meta.instruments, placeholder: "напр. фортепиано, скрипка")
            Picker("Статус", selection: $meta.status) {
                ForEach(MusicStatus.allCases) { s in
                    Text(s.title).tag(s)
                }
            }
        } header: {
            Text("Параметры").foregroundStyle(theme.textSecondary)
        }
        .listRowBackground(theme.bgElevated)
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $body_)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
        } header: {
            Text("Описание").foregroundStyle(theme.textSecondary)
        } footer: {
            Text("Связи `[[Заметка]]` и теги `#тема` работают как в Блокноте.")
                .foregroundStyle(theme.textFaint)
        }
        .listRowBackground(theme.bgElevated)
    }

    @ViewBuilder
    private var backlinksSection: some View {
        let backlinks = store.backlinks(to: note)
        if !backlinks.isEmpty {
            Section {
                ForEach(backlinks) { src in
                    if store.meta(of: src) != nil {
                        NavigationLink(value: src) {
                            Label(src.title, systemImage: "music.note")
                                .foregroundStyle(theme.textPrimary)
                        }
                    } else {
                        Label(src.title, systemImage: "doc.text")
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            } header: {
                Text("На эту идею ссылаются").foregroundStyle(theme.textSecondary)
            }
            .listRowBackground(theme.bgElevated)
        }
    }

    // MARK: Поле формы

    private func field(_ label: String, text: Binding<String>,
                       placeholder: String, number: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(theme.textSecondary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(theme.textPrimary)
                #if os(iOS)
                .keyboardType(number ? .numbersAndPunctuation : .default)
                #endif
        }
    }

    // MARK: Данные

    private func load() {
        guard !loaded else { return }
        if let parsed = MusicMeta.parse(note.content) {
            meta = parsed.meta
            body_ = parsed.body
        } else {
            // Заметка без музыкальной шапки — показываем тело как есть.
            body_ = note.content
        }
        loaded = true
    }

    private func persist() {
        guard loaded else { return }
        store.saveMusic(note, meta: meta, body: body_)
    }
}
