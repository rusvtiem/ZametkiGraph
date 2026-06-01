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
    @State private var expanded: Param?

    /// Параметр с барабаном-выбором.
    private enum Param { case tonality, tempo, meter }

    /// Значение «не задано» в барабане (наверху списка → пустое поле).
    private static let none = "—"

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
            wheelRow("Тональность", param: .tonality, text: $meta.tonality, options: MusicMeta.tonalities)
            wheelRow("Темп (BPM)", param: .tempo, text: $meta.tempo, options: MusicMeta.tempos)
            wheelRow("Размер", param: .meter, text: $meta.meter, options: MusicMeta.meters)
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

    // MARK: Барабан-выбор (тональность / темп / размер)

    /// Строка-параметр: тап раскрывает барабан со значениями. «—» = пусто.
    @ViewBuilder
    private func wheelRow(_ label: String, param: Param,
                          text: Binding<String>, options base: [String]) -> some View {
        Button {
            withAnimation { expanded = (expanded == param) ? nil : param }
        } label: {
            HStack {
                Text(label).foregroundStyle(theme.textSecondary)
                Spacer()
                Text(text.wrappedValue.isEmpty ? Self.none : text.wrappedValue)
                    .foregroundStyle(expanded == param ? theme.accent : theme.textPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if expanded == param {
            Picker(label, selection: wheelBinding(text)) {
                ForEach(wheelOptions(base, current: text.wrappedValue), id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.wheel)
            .frame(maxHeight: 150)
            #else
            .pickerStyle(.menu)
            #endif
        }
    }

    /// Маппинг пустого значения на «—» и обратно для выбора в барабане.
    private func wheelBinding(_ text: Binding<String>) -> Binding<String> {
        Binding(
            get: { text.wrappedValue.isEmpty ? Self.none : text.wrappedValue },
            set: { text.wrappedValue = ($0 == Self.none) ? "" : $0 }
        )
    }

    /// Список для барабана: «—» сверху + значения. Если у заметки старое значение
    /// вне списка (введено текстом раньше) — добавляем его, чтобы не потерять.
    private func wheelOptions(_ base: [String], current: String) -> [String] {
        var opts = [Self.none] + base
        if !current.isEmpty && !base.contains(current) { opts.insert(current, at: 1) }
        return opts
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
                       placeholder: String) -> some View {
        HStack {
            Text(label).foregroundStyle(theme.textSecondary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(theme.textPrimary)
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
