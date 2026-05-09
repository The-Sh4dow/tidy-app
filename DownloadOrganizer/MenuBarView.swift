import SwiftUI

// MARK: - Menu Bar Icon

struct MenuBarIcon: View {
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: organizer.isRunning ? "arrow.triangle.2.circlepath" : "folder.badge.gearshape")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(organizer.isWatching ? Color.accentColor : .primary)
        }
    }
}

// MARK: - Menu Bar Popover

struct MenuBarView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var hovering: String? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tidy")
                        .font(.system(size: 14, weight: .semibold))
                    Text(organizer.isWatching ? "Vigilando Downloads..." : "Inactivo")
                        .font(.system(size: 11))
                        .foregroundColor(organizer.isWatching ? .green : .secondary)
                }
                Spacer()
                // Watch toggle
                Toggle("", isOn: Binding(
                    get: { organizer.isWatching },
                    set: { $0 ? organizer.startWatching() : organizer.stopWatching() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            // Quick actions
            VStack(spacing: 2) {
                MenuBarButton(
                    icon: "play.fill",
                    label: "Organizar ahora",
                    sublabel: organizer.isRunning ? "Organizando..." : nil,
                    color: .blue,
                    isLoading: organizer.isRunning
                ) {
                    organizer.organizeNow()
                }

                if let last = organizer.moveLog.first(where: { !$0.undone }) {
                    MenuBarButton(
                        icon: "arrow.uturn.backward",
                        label: "Deshacer",
                        sublabel: last.fileName,
                        color: .orange
                    ) {
                        organizer.undo(entry: last)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Stats strip
            HStack(spacing: 0) {
                StatStrip(value: "\(organizer.weeklyStats.totalMoved)", label: "esta semana", icon: "checkmark.circle.fill", color: .green)
                Divider().frame(height: 28)
                StatStrip(value: "\(organizer.moveLog.count)", label: "total", icon: "clock.fill", color: .blue)
                Divider().frame(height: 28)
                StatStrip(value: organizer.weeklyStats.topCategory ?? "—", label: "categoría top", icon: "star.fill", color: .yellow)
            }
            .padding(.vertical, 8)

            Divider()

            // Recent files
            if !organizer.moveLog.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recientes")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(organizer.moveLog.prefix(3)) { entry in
                        MenuBarRecentRow(entry: entry) {
                            organizer.undo(entry: entry)
                        }
                    }
                }
            }

            Divider()

            // Bottom actions
            HStack {
                MenuBarTextButton(label: "Abrir Tidy") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
                Spacer()
                MenuBarTextButton(label: "Abrir Downloads") {
                    NSWorkspace.shared.open(organizer.downloadsURL)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sub components

struct MenuBarButton: View {
    let icon: String
    let label: String
    var sublabel: String? = nil
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(0.15))
                        .frame(width: 30, height: 30)
                    if isLoading {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(color)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                    if let sub = sublabel {
                        Text(sub)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .disabled(isLoading)
    }
}

struct StatStrip: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MenuBarRecentRow: View {
    let entry: MoveEntry
    let onUndo: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.undone ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(entry.undone ? .orange : .blue)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.fileName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Text("→ \(entry.category)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()

            if !entry.undone && isHovered {
                Button("Deshacer") { onUndo() }
                    .font(.system(size: 10))
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { isHovered = $0 }
    }
}

struct MenuBarTextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
}
