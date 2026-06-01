import SwiftUI

/// Граф связей (как в Obsidian): узлы-заметки и узлы-теги, силовая раскладка.
/// Жесты: перетаскивание узла, панорама фона, зум щипком, тап по узлу — открыть.
struct GraphView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool

    /// nil → глобальный граф; иначе локальный вокруг этой заметки.
    var centerTitle: String?
    var onOpenNote: (String) -> Void
    var onOpenTag: (String) -> Void

    @State private var layout: GraphLayout?
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var dragMode: DragMode = .none

    private enum DragMode: Equatable { case none, pan, node(Int) }

    private var centerID: String? { centerTitle.map { "note:" + $0.lowercased() } }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    theme.bg.ignoresSafeArea()
                    if let layout, !layout.nodes.isEmpty {
                        TimelineView(.animation) { _ in
                            Canvas { ctx, size in
                                layout.step()
                                draw(ctx, size: size, layout: layout)
                            }
                        }
                    } else {
                        emptyState
                    }
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(size: geo.size))
                .simultaneousGesture(magnification)
            }
            .navigationTitle(centerTitle == nil ? "Граф" : "Граф · \(centerTitle!)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { isPresented = false }
                }
            }
        }
        .onAppear(perform: buildLayout)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 40)).foregroundStyle(theme.textFaint)
            Text(centerTitle == nil ? "Пока нет связей для графа"
                                    : "У этой заметки пока нет связей")
                .foregroundStyle(theme.textSecondary)
        }
    }

    // MARK: Построение

    private func buildLayout() {
        let full = GraphModel.build(from: store.textNotes)
        let model = centerTitle.map { full.localGraph(around: $0, depth: 2) } ?? full
        layout = GraphLayout(model: model, centerID: centerID)
        scale = 1; baseScale = 1; offset = .zero
    }

    // MARK: Координаты

    private func toGraph(_ s: CGPoint, _ size: CGSize) -> CGPoint {
        let cx = size.width / 2 + offset.width
        let cy = size.height / 2 + offset.height
        return CGPoint(x: (s.x - cx) / scale, y: (s.y - cy) / scale)
    }

    private func toScreen(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + offset.width + p.x * scale,
                y: size.height / 2 + offset.height + p.y * scale)
    }

    // MARK: Отрисовка

    private func draw(_ ctx: GraphicsContext, size: CGSize, layout: GraphLayout) {
        // рёбра
        var path = Path()
        for (a, b) in layout.edges {
            path.move(to: toScreen(layout.pos[a], size))
            path.addLine(to: toScreen(layout.pos[b], size))
        }
        ctx.stroke(path, with: .color(theme.divider), lineWidth: 1)

        let tagColor = theme.palette.isDark
            ? Color(hexString: "#E5C07B") : Color(hexString: "#C07A2B")
        let showLabels = scale > 0.55

        for (i, node) in layout.nodes.enumerated() {
            let p = toScreen(layout.pos[i], size)
            let isCenter = node.id == centerID
            let r = (isCenter ? 8 : 5) + min(CGFloat(node.degree) * 1.4, 11)
            let color = node.kind == .tag ? tagColor : theme.accent
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            ctx.fill(Circle().path(in: rect), with: .color(color))
            if isCenter {
                ctx.stroke(Circle().path(in: rect.insetBy(dx: -2, dy: -2)),
                           with: .color(theme.textPrimary), lineWidth: 1.5)
            }
            if showLabels {
                let text = Text(node.label)
                    .font(.system(size: 9))
                    .foregroundColor(node.kind == .tag ? tagColor : theme.textSecondary)
                ctx.draw(text, at: CGPoint(x: p.x, y: p.y + r + 7), anchor: .top)
            }
        }
    }

    // MARK: Жесты

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { v in scale = min(max(baseScale * v, 0.25), 4) }
            .onEnded { _ in baseScale = scale }
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard let layout else { return }
                if dragMode == .none {
                    let g = toGraph(v.startLocation, size)
                    if let i = layout.nearestNode(to: g, within: 26 / scale) {
                        dragMode = .node(i); layout.setPin(i)
                    } else {
                        dragMode = .pan; baseOffset = offset
                    }
                }
                switch dragMode {
                case .pan:
                    offset = CGSize(width: baseOffset.width + v.translation.width,
                                    height: baseOffset.height + v.translation.height)
                case .node:
                    layout.pinPoint = toGraph(v.location, size)
                case .none:
                    break
                }
            }
            .onEnded { v in
                if case .node(let i) = dragMode, let layout {
                    layout.clearPin()
                    let moved = hypot(v.translation.width, v.translation.height)
                    if moved < 8 { open(layout.nodes[i]) }
                }
                dragMode = .none
            }
    }

    private func open(_ node: GraphNode) {
        isPresented = false
        switch node.kind {
        case .note: onOpenNote(node.label)
        case .tag:  onOpenTag(String(node.label.dropFirst()))  // убрать «#»
        }
    }
}
