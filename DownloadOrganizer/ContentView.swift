import SwiftUI

struct ContentView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Inicio"
        case categories = "Categorías"
        case log = "Historial"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .categories: return "folder.fill"
            case .log: return "clock.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(selectedTab: $selectedTab)
                .frame(width: 200)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .home:       HomeView()
                case .categories: CategoriesView()
                case .log:        LogView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
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
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Download\nOrganizer")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Nav items
            VStack(spacing: 2) {
                ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Auto-watch status
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack(spacing: 8) {
                    Circle()
                        .fill(organizer.isWatching ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(organizer.isWatching ? Color.green.opacity(0.3) : .clear)
                                .frame(width: 14, height: 14)
                        )
                    Text(organizer.isWatching ? "Vigilando..." : "Inactivo")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SidebarItem: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
