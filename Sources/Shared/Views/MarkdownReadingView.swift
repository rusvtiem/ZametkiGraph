import SwiftUI

/// Режим «чтение» (как в Obsidian): markdown отрендерен, `[[ссылки]]` и `#теги`
/// кликабельные, `![[заметка]]` вставляется блоком (эмбед).
struct MarkdownReadingView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: VaultStore
    let content: String
    let onOpen: (String) -> Void
    let onOpenTag: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    row(line, allowEmbed: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(theme.bg)
        .tint(theme.accent)
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "zametki",
                  let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "name" })?.value
            else { return .systemAction }
            if url.host == "tag" {
                onOpenTag(name)
            } else {
                // имя может содержать «#Заголовок» — для навигации берём саму заметку
                onOpen(name.components(separatedBy: "#").first ?? name)
            }
            return .handled
        })
    }

    private var lines: [String] { content.components(separatedBy: "\n") }

    @ViewBuilder
    private func row(_ line: String, allowEmbed: Bool) -> some View {
        if allowEmbed, let target = embedTarget(line.trimmingCharacters(in: .whitespaces)) {
            embedBlock(target)
        } else {
            plainRow(line)
        }
    }

    /// Рендер одной строки без эмбедов. Вынесен отдельно, чтобы разорвать
    /// взаимную рекурсию opaque-типов `row` ↔ `embedBlock` (иначе SILGen падает).
    @ViewBuilder
    private func plainRow(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Color.clear.frame(height: 2)
        } else if line.hasPrefix("# ") {
            inline(String(line.dropFirst(2))).font(.largeTitle.bold())
        } else if line.hasPrefix("## ") {
            inline(String(line.dropFirst(3))).font(.title2.bold())
        } else if line.hasPrefix("### ") {
            inline(String(line.dropFirst(4))).font(.title3.bold())
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(theme.textSecondary)
                inline(String(line.dropFirst(2)))
            }
        } else {
            inline(line)
        }
    }

    /// Если строка целиком — это `![[Заметка]]`, вернуть имя цели.
    private func embedTarget(_ trimmed: String) -> String? {
        guard trimmed.hasPrefix("![[") && trimmed.hasSuffix("]]") else { return nil }
        return WikiLinkParser.wikiLinks(in: trimmed).first { $0.isEmbed }?.target
    }

    /// Вставка содержимого другой заметки (без вложенных эмбедов — защита от рекурсии).
    @ViewBuilder
    private func embedBlock(_ target: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(target, systemImage: "doc.text.below.ecg")
                .font(.caption.bold())
                .foregroundStyle(theme.textSecondary)
            if let note = store.note(titled: target) {
                ForEach(Array(note.content.components(separatedBy: "\n").enumerated()),
                        id: \.offset) { _, l in
                    plainRow(l)
                }
            } else {
                Text("Заметка «\(target)» не найдена")
                    .font(.caption).foregroundStyle(theme.textFaint)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(theme.accent.opacity(0.4), lineWidth: 1))
    }

    private func inline(_ s: String) -> Text {
        let md = WikiLinkParser.markdownified(s)
        if let attr = try? AttributedString(
            markdown: md,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attr).foregroundColor(theme.textPrimary)
        }
        return Text(s).foregroundColor(theme.textPrimary)
    }
}
