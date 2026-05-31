import SwiftUI

/// Режим «чтение» (как в Obsidian): markdown отрендерен, `[[ссылки]]` —
/// кликабельные. Тап по ссылке вызывает `onOpen` с именем целевой заметки.
struct MarkdownReadingView: View {
    let content: String
    let onOpen: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    row(line)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Theme.bg)
        .tint(Theme.accent)
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "zametki" else { return .systemAction }
            if let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "name" })?.value {
                onOpen(name)
            }
            return .handled
        })
    }

    private var lines: [String] { content.components(separatedBy: "\n") }

    @ViewBuilder
    private func row(_ line: String) -> some View {
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Color.clear.frame(height: 2)
        } else if line.hasPrefix("# ") {
            inline(String(line.dropFirst(2))).font(.largeTitle.bold())
        } else if line.hasPrefix("## ") {
            inline(String(line.dropFirst(3))).font(.title2.bold())
        } else if line.hasPrefix("### ") {
            inline(String(line.dropFirst(4))).font(.title3.bold())
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(Theme.textSecondary)
                inline(String(line.dropFirst(2)))
            }
        } else {
            inline(line)
        }
    }

    private func inline(_ s: String) -> Text {
        let md = WikiLinkParser.markdownified(s)
        if let attr = try? AttributedString(
            markdown: md,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attr).foregroundColor(Theme.textPrimary)
        }
        return Text(s).foregroundColor(Theme.textPrimary)
    }
}
