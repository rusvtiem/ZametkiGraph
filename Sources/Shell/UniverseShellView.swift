import SwiftUI

/// Оболочка «Вселенной»: панель вкладок (как в браузере) + активный модуль под ней.
/// Одна активная вкладка, переключатель сверху. Общий фундамент (store/theme)
/// инжектится снаружи и доступен всем модулям через environment.
struct UniverseShellView: View {
    @EnvironmentObject var theme: ThemeManager
    let apps: [any UniverseApp]
    @State private var selectedID: String

    init(apps: [any UniverseApp]) {
        self.apps = apps
        _selectedID = State(initialValue: apps.first?.id ?? "")
    }

    private var current: (any UniverseApp)? {
        apps.first { $0.id == selectedID } ?? apps.first
    }

    var body: some View {
        VStack(spacing: 0) {
            tabStrip
            Divider().overlay(theme.divider)
            if let current {
                current.makeRootView()
                    .id(current.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyState
            }
        }
        .background(theme.bg)
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(apps, id: \.id) { app in
                    tab(app)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(theme.bgSidebar)
    }

    private func tab(_ app: any UniverseApp) -> some View {
        let active = app.id == selectedID
        return Button {
            selectedID = app.id
        } label: {
            HStack(spacing: 6) {
                Image(systemName: app.icon).font(.system(size: 13))
                Text(app.title).font(.system(size: 13, weight: active ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(active ? theme.textPrimary : theme.textSecondary)
            .background(active ? theme.accent.opacity(0.20) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 40)).foregroundStyle(theme.textFaint)
            Text("Во Вселенной пока нет приложений")
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
    }
}
