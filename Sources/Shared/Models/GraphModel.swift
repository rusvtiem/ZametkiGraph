import SwiftUI

enum GraphNodeKind { case note, tag }

struct GraphNode: Identifiable, Equatable {
    let id: String        // "note:<lower>" или "tag:<lower>"
    let label: String     // отображаемое имя
    let kind: GraphNodeKind
    var degree: Int = 0
}

struct GraphEdge: Equatable {
    let a: String
    let b: String
}

/// Граф хранилища: узлы = заметки + теги, рёбра = `[[связи]]` и принадлежность тегу.
struct GraphModel {
    var nodes: [GraphNode]
    var edges: [GraphEdge]

    static let empty = GraphModel(nodes: [], edges: [])

    /// Полный граф по всем заметкам.
    static func build(from notes: [Note]) -> GraphModel {
        var nodes: [String: GraphNode] = [:]
        var edges: [GraphEdge] = []
        var edgeSeen = Set<String>()

        func noteID(_ title: String) -> String { "note:" + title.lowercased() }
        func tagID(_ tag: String) -> String { "tag:" + tag.lowercased() }

        // карта заголовок(lower) → реальный заголовок, для резолва [[...]]
        var titleMap: [String: String] = [:]
        for n in notes {
            titleMap[n.title.lowercased()] = n.title
            nodes[noteID(n.title)] = GraphNode(id: noteID(n.title), label: n.title, kind: .note)
        }

        func addEdge(_ x: String, _ y: String) {
            let key = x < y ? x + "|" + y : y + "|" + x
            guard edgeSeen.insert(key).inserted else { return }
            edges.append(GraphEdge(a: x, b: y))
            nodes[x]?.degree += 1
            nodes[y]?.degree += 1
        }

        for n in notes {
            let from = noteID(n.title)
            // связи [[...]] (и эмбеды) на существующие заметки
            for target in WikiLinkParser.links(in: n.content) {
                if let real = titleMap[target.lowercased()] {
                    let to = noteID(real)
                    if to != from { addEdge(from, to) }
                }
            }
            // теги
            for tag in WikiLinkParser.tags(in: n.content) {
                let tid = tagID(tag)
                if nodes[tid] == nil {
                    nodes[tid] = GraphNode(id: tid, label: "#" + tag, kind: .tag)
                }
                addEdge(from, tid)
            }
        }

        return GraphModel(nodes: Array(nodes.values), edges: edges)
    }

    /// Локальный граф вокруг заметки: соседи в пределах `depth` шагов.
    func localGraph(around centerTitle: String, depth: Int) -> GraphModel {
        let centerID = "note:" + centerTitle.lowercased()
        guard nodes.contains(where: { $0.id == centerID }) else { return .empty }

        var adjacency: [String: Set<String>] = [:]
        for e in edges {
            adjacency[e.a, default: []].insert(e.b)
            adjacency[e.b, default: []].insert(e.a)
        }

        var keep: Set<String> = [centerID]
        var frontier: Set<String> = [centerID]
        for _ in 0..<max(depth, 1) {
            var next: Set<String> = []
            for id in frontier {
                for nb in adjacency[id] ?? [] where !keep.contains(nb) {
                    keep.insert(nb); next.insert(nb)
                }
            }
            frontier = next
            if frontier.isEmpty { break }
        }

        let keptNodes = nodes.filter { keep.contains($0.id) }
        let keptEdges = edges.filter { keep.contains($0.a) && keep.contains($0.b) }
        return GraphModel(nodes: keptNodes, edges: keptEdges)
    }
}

// MARK: - Силовая раскладка

/// Простая силовая раскладка: узлы отталкиваются, рёбра-пружины притягивают,
/// слабое центрирование держит граф в кадре. Шагаем покадрово из TimelineView.
final class GraphLayout {
    let nodes: [GraphNode]
    let edges: [(Int, Int)]
    private let idIndex: [String: Int]
    private(set) var pos: [CGPoint]
    private var vel: [CGPoint]
    private(set) var settled = false

    var pinned: Int?
    var pinPoint: CGPoint = .zero

    init(model: GraphModel, centerID: String? = nil) {
        nodes = model.nodes
        let map = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })
        idIndex = map
        edges = model.edges.compactMap { e in
            guard let a = map[e.a], let b = map[e.b] else { return nil }
            return (a, b)
        }
        let n = max(nodes.count, 1)
        pos = nodes.enumerated().map { i, _ in
            let ang = Double(i) / Double(n) * 2 * .pi
            return CGPoint(x: cos(ang) * 130, y: sin(ang) * 130)
        }
        vel = Array(repeating: .zero, count: nodes.count)
        if let centerID, let c = map[centerID] { pos[c] = .zero }
    }

    func index(of id: String) -> Int? { idIndex[id] }

    func setPin(_ i: Int) { pinned = i; settled = false }
    func clearPin() { pinned = nil; settled = false }
    func wake() { settled = false }

    /// Ближайший узел к точке (в координатах графа), если в радиусе.
    func nearestNode(to p: CGPoint, within radius: CGFloat) -> Int? {
        var best: Int?
        var bestD = radius * radius
        for i in pos.indices {
            let dx = pos[i].x - p.x, dy = pos[i].y - p.y
            let d2 = dx * dx + dy * dy
            if d2 < bestD { bestD = d2; best = i }
        }
        return best
    }

    func step() {
        let count = nodes.count
        guard count > 1, !settled || pinned != nil else { return }
        var force = Array(repeating: CGPoint.zero, count: count)

        let repulse: CGFloat = 2600
        for i in 0..<count {
            for j in (i + 1)..<count {
                var dx = pos[i].x - pos[j].x
                var dy = pos[i].y - pos[j].y
                var d2 = dx * dx + dy * dy
                if d2 < 0.01 {
                    dx = .random(in: -1...1); dy = .random(in: -1...1); d2 = 1
                }
                let d = sqrt(d2)
                let f = repulse / d2
                force[i].x += dx / d * f; force[i].y += dy / d * f
                force[j].x -= dx / d * f; force[j].y -= dy / d * f
            }
        }

        let k: CGFloat = 0.025
        let rest: CGFloat = 95
        for (a, b) in edges {
            let dx = pos[b].x - pos[a].x
            let dy = pos[b].y - pos[a].y
            let d = max(sqrt(dx * dx + dy * dy), 0.01)
            let f = (d - rest) * k
            force[a].x += dx / d * f; force[a].y += dy / d * f
            force[b].x -= dx / d * f; force[b].y -= dy / d * f
        }

        let center: CGFloat = 0.006
        let damping: CGFloat = 0.82
        let maxV: CGFloat = 28
        var maxSpeed: CGFloat = 0
        for i in 0..<count {
            if i == pinned { pos[i] = pinPoint; vel[i] = .zero; continue }
            force[i].x -= pos[i].x * center
            force[i].y -= pos[i].y * center
            vel[i].x = (vel[i].x + force[i].x) * damping
            vel[i].y = (vel[i].y + force[i].y) * damping
            let speed = sqrt(vel[i].x * vel[i].x + vel[i].y * vel[i].y)
            if speed > maxV { vel[i].x *= maxV / speed; vel[i].y *= maxV / speed }
            pos[i].x += vel[i].x
            pos[i].y += vel[i].y
            maxSpeed = max(maxSpeed, speed)
        }
        // Граф «успокоился» — прекращаем считать, пока не разбудят (драг/пересборка).
        if pinned == nil, maxSpeed < 0.08 { settled = true }
    }
}
