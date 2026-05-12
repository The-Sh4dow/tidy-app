import SwiftUI

struct ContentView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home       = "Inicio"
        case categories = "Categorías"
        case rules      = "Reglas"
        case duplicates = "Duplicados"
        case stats      = "Estadísticas"
        case log        = "Historial"
        case settings   = "Ajustes"

        var icon: String {
            switch self {
            case .home:       return "house.fill"
            case .categories: return "folder.fill"
            case .rules:      return "slider.horizontal.3"
            case .duplicates: return "doc.on.doc.fill"
            case .stats:      return "chart.bar.fill"
            case .log:        return "clock.fill"
            case .settings:   return "gearshape.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab)
                .frame(width: 210)
            Divider()
            Group {
                switch selectedTab {
                case .home:       HomeView()
                case .categories: CategoriesView()
                case .rules:      RulesView()
                case .duplicates: DuplicatesView()
                case .stats:      StatsView()
                case .log:        LogView()
                case .settings:   SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .init("tidy.navigate.log"))) { _ in
            selectedTab = .log
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App header
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Tidy")
                    .font(.system(size: 20, weight: .bold))
                Text("v1.7")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            .padding(.bottom, 20)

            // General section
            SectionLabel("GENERAL")
            VStack(spacing: 2) {
                ForEach([ContentView.Tab.home, .categories, .rules], id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab,
                                badge: nil) { selectedTab = tab }
                }
            }
            .padding(.horizontal, 10)

            // Tools section
            SectionLabel("HERRAMIENTAS")
            VStack(spacing: 2) {
                SidebarItem(tab: .duplicates, isSelected: selectedTab == .duplicates,
                            badge: organizer.duplicates.isEmpty ? nil : "\(organizer.duplicates.count)") {
                    selectedTab = .duplicates
                }
            }
            .padding(.horizontal, 10)

            // Analysis section
            SectionLabel("ANÁLISIS")
            VStack(spacing: 2) {
                ForEach([ContentView.Tab.stats, .log], id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab,
                                badge: tab == .log && !organizer.errorLog.isEmpty ? "!" : nil) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            Divider()

            SidebarItem(tab: .settings, isSelected: selectedTab == .settings, badge: nil) {
                selectedTab = .settings
            }
            .padding(.horizontal, 10)

            // Status bar
            HStack(spacing: 8) {
                Circle()
                    .fill(organizer.isWatching ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text(organizer.isWatching ? "Vigilando" : "Inactivo")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                Spacer()
                if organizer.movedToday > 0 {
                    Text("\(organizer.movedToday) hoy")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}

struct SidebarItem: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(badge == "!" ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .padding(.vertical, 7).padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
