import SwiftUI

struct LogView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var searchText = ""

    var filtered: [MoveEntry] {
        if searchText.isEmpty { return organizer.moveLog }
        return organizer.moveLog.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historial")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(organizer.moveLog.count) archivos organizados")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !organizer.moveLog.isEmpty {
                    Button(role: .destructive) {
                        organizer.clearLog()
                    } label: {
                        Label("Limpiar", systemImage: "trash")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Search
            if !organizer.moveLog.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar archivo o categoría...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
            }

            Divider()

            if organizer.moveLog.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 52))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Sin actividad aún")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("El historial aparecerá aquí cuando organices\narchivos manualmente o de forma automática.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else if filtered.isEmpty {
                VStack {
                    Spacer()
                    Text("Sin resultados para \"\(searchText)\"")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(filtered) { entry in
                    LogEntryRow(entry: entry)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: MoveEntry
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue.opacity(0.7))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.category)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(URL(fileURLWithPath: entry.toPath).deletingLastPathComponent().lastPathComponent)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.date, style: .time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(entry.date, style: .date)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            if isHovering {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.toPath)])
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(10)
        .onHover { isHovering = $0 }
    }
}
