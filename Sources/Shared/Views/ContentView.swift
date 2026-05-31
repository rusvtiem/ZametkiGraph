import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: VaultStore
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedID: String?
    @State private var drawerOpen = false
    @State private var readingMode = false
    @State private var showLinks = false
    @State private var showThemes = false
    @State private var showTags = false
    @State private var tagToShow: String?
    @State private var showGraph = false
    @State private var graphCenter: String?  // nil — глобальный граф, иначе локальный вокруг заметки

    private let drawerWidth: CGFloat = 300

    private var note: Note? {
        guard let id = selectedID else { return nil }
        return store.notes.first { $0.id == id }
    }

    var body: some View {
        sizedRoot
    }

    @ViewBuilder
    private var sizedRoot: some View {
        #if os(macOS)
        root.frame(minWidth: 820, minHeight: 560)
        #else
        root
        #endif
    }

    private var root: some View {
        ZStack(alignment: .leading) {
            theme.bg.ignoresSafeArea()

            mainColumn
                .overlay(dimOverlay)

            drawer
                .frame(width: drawerWidth)
                .offset(x: drawerOpen ? 0 : -drawerWidth - 1)
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.86), value: drawerOpen)
        .preferredColorScheme(theme.palette.isDark ? .dark : .light)
        .tint(theme.accent)
        .gesture(edgeDrag)
        .sheet(isPresented: $showLinks) {
            LinksPanel(note: note, selectedID: $selectedID, isPresented: $showLinks)
        }
        .sheet(isPresented: $showThemes) {
            ThemePickerView(isPresented: $showThemes)
        }
        .sheet(isPresented: $showGraph) {
            GraphView(isPresented: $showGraph,
                      centerTitle: graphCenter,
                      onOpenNote: { open($0) },
                      onOpenTag: { openTag($0) })
        }
        .sheet(isPresented: $showTags) {
            TagIndexView(isPresented: $showTags,
                         initialTag: tagToShow,
                         onOpenNote: { open($0) })
        }
        .onAppear { selectFirstIfNeeded(store.notes) }
        .onChange(of: store.notes) { _, notes in selectFirstIfNeeded(notes) }
    }

    // MARK: Основная колонка

    private var mainColumn: some View {
        VStack(spacing: 0) {
            topBar
            Divider().overlay(theme.divider)
            content
            Divider().overlay(theme.divider)
            bottomBar
        }
        .background(theme.bg)
    }

    @ViewBuilder
    private var content: some View {
        if let note {
            if readingMode {
                MarkdownReadingView(content: note.content,
                                    onOpen: { open($0) },
                                    onOpenTag: { openTag($0) })
            } else {
                EditorPane(note: note).id(note.id)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 42))
                .foregroundStyle(theme.textFaint)
            Text("Нет открытой заметки")
                .foregroundStyle(theme.textSecondary)
            Button("Открыть список") { openDrawer() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
    }

    // MARK: Верхняя панель

    private var topBar: some View {
        ZStack {
            Text(note?.title ?? "ZametkiGraph")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 90)

            HStack {
                barButton("line.3.horizontal") { toggleDrawer() }
                Spacer()
                if note != nil {
                    barButton(readingMode ? "pencil" : "book") { readingMode.toggle() }
                }
                Menu {
                    if note != nil {
                        Button { readingMode.toggle() } label: {
                            Label(readingMode ? "Режим правки" : "Режим чтения",
                                  systemImage: readingMode ? "pencil" : "book")
                        }
                        Button { showLinks = true } label: {
                            Label("Связи", systemImage: "link")
                        }
                        Button { openLocalGraph() } label: {
                            Label("Граф этой заметки", systemImage: "point.3.connected.trianglepath.dotted")
                        }
                        Divider()
                    }
                    Button { openGlobalGraph() } label: {
                        Label("Граф", systemImage: "circle.hexagongrid")
                    }
                    Button { openTags() } label: {
                        Label("Теги", systemImage: "number")
                    }
                    Button { showThemes = true } label: {
                        Label("Темы оформления", systemImage: "paintpalette")
                    }
                    if let note {
                        Divider()
                        Button(role: .destructive) { delete(note) } label: {
                            Label("Удалить заметку", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.bg)
    }

    // MARK: Нижняя панель

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomButton("square.and.pencil", "Новая") { newNote() }
            bottomButton("magnifyingglass", "Поиск") { openDrawer() }
            bottomButton(readingMode ? "pencil" : "book", readingMode ? "Правка" : "Чтение") {
                if note != nil { readingMode.toggle() }
            }
            bottomButton("link", "Связи") { if note != nil { showLinks = true } }
            bottomButton("circle.hexagongrid", "Граф") { openGlobalGraph() }
        }
        .padding(.vertical, 6)
        .background(theme.bg)
    }

    // MARK: Drawer

    private var drawer: some View {
        SidebarView(selectedID: $selectedID, onSelect: { closeDrawer() })
    }

    private var dimOverlay: some View {
        Color.black
            .opacity(drawerOpen ? 0.45 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(drawerOpen)
            .onTapGesture { closeDrawer() }
    }

    // MARK: Кнопки

    private func barButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.textSecondary)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
    }

    private func bottomButton(_ icon: String, _ label: String,
                              _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label).font(.system(size: 10))
            }
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: Действия

    private var edgeDrag: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { v in
                if !drawerOpen, v.startLocation.x < 40, v.translation.width > 60 {
                    openDrawer()
                } else if drawerOpen, v.translation.width < -60 {
                    closeDrawer()
                }
            }
    }

    private func toggleDrawer() { drawerOpen ? closeDrawer() : openDrawer() }
    private func openDrawer() { drawerOpen = true }
    private func closeDrawer() { drawerOpen = false }

    private func newNote() {
        if let created = store.createNote(title: "Новая заметка") {
            selectedID = created.id
            readingMode = false
        }
    }

    private func open(_ name: String) {
        // имя из [[Заметка#Заголовок]] — для навигации берём саму заметку
        let title = name.components(separatedBy: "#").first.map {
            $0.trimmingCharacters(in: .whitespaces)
        } ?? name
        guard !title.isEmpty else { return }
        if let existing = store.note(titled: title) {
            selectedID = existing.id
        } else if let created = store.createNote(title: title) {
            selectedID = created.id
        }
        readingMode = true
    }

    private func openTag(_ tag: String) {
        tagToShow = tag
        showTags = true
    }

    private func openTags() {
        tagToShow = nil
        showTags = true
    }

    private func openGlobalGraph() {
        graphCenter = nil
        showGraph = true
    }

    private func openLocalGraph() {
        graphCenter = note?.title
        showGraph = true
    }

    private func delete(_ note: Note) {
        if selectedID == note.id { selectedID = nil }
        store.delete(note)
    }

    private func selectFirstIfNeeded(_ notes: [Note]) {
        if selectedID == nil || !notes.contains(where: { $0.id == selectedID }) {
            selectedID = notes.first?.id
        }
    }
}
