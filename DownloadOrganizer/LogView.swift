import SwiftUI

struct LogView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var searchText = ""
    @State private var selectedTab: LogTab = .moves

    enum LogTab: String, CaseIterable {
        case moves  = "Movimientos"
        case errors = "Errores"
    }

    var filteredMoves: [MoveEntry] {
        if searchText.isEmpty { return organizer.moveLog }
        return organizer.moveLog.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredErrors: [ErrorEntry] {
        if searchText.isEmpty { return organizer.errorLog }
        return organizer.errorLog.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.reason.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historial")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(organizer.moveLog.count) movimientos · \(organizer.errorLog.count) errores")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !organizer.moveLog.isEmpty || !organizer.errorLog.isEmpty {
                    Button(role: .destructive) { organizer.clearLog() } label: {
                        Label("Limpiar", systemImage: "trash")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 12)

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(LogTab.allCases, id: \.self) { tab in
                    HStack {
                        Text(tab.rawValue)
                        if tab == .errors && !organizer.errorLog.isEmpty {
                            Text("\(organizer.errorLog.count)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                    .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Buscar...", text: $searchText).textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            Divider()

            // Content
            if selectedTab == .moves {
                if organizer.moveLog.isEmpty {
                    EmptyLogView(icon: "clock.badge.checkmark", message: "Sin actividad aún",
                                 sub: "El historial aparecerá aquí cuando organices archivos.")
                } else if filteredMoves.isEmpty {
                    EmptyLogView(icon: "magnifyingglass", message: "Sin resultados",
                                 sub: "No hay movimientos que coincidan con \"\(searchText)\"")
                } else {
                    List(filteredMoves) { entry in
                        LogEntryRow(entry: entry)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            } else {
                if organizer.errorLog.isEmpty {
                    EmptyLogView(icon: "checkmark.shield.fill", message: "Sin errores",
                                 sub: "Tidy no ha encontrado ningún problema al organizar.")
                } else if filteredErrors.isEmpty {
                    EmptyLogView(icon: "magnifyingglass", message: "Sin resultados",
                                 sub: "No hay errores que coincidan con \"\(searchText)\"")
                } else {
                    List(filteredErrors) { entry in
                        ErrorEntryRow(entry: entry)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: MoveEntry
    @EnvironmentObject var organizer: FileOrganizer
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.undone ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(entry.undone ? .orange : .blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .strikethrough(entry.undone, color: .secondary)
                HStack(spacing: 6) {
                    Text(entry.category)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    Image(systemName: "arrow.right").font(.system(size: 9)).foregroundColor(.secondary)
                    Text(URL(fileURLWithPath: entry.toPath).deletingLastPathComponent().lastPathComponent)
                        .font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.date, style: .time).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                Text(entry.date, style: .date).font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
            }

            if isHovering && !entry.undone {
                Button {
                    organizer.undo(entry: entry)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(10)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Error Entry Row

struct ErrorEntryRow: View {
    let entry: ErrorEntry
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(entry.reason)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.date, style: .time).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                Text(entry.date, style: .date).font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
            }

            if isHovering {
                Button {
                    NSWorkspace.shared.selectFile(entry.filePath, inFileViewerRootedAtPath: "")
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(isHovering ? Color.red.opacity(0.04) : Color.clear)
        .cornerRadius(10)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Empty State

struct EmptyLogView: View {
    let icon: String
    let message: String
    let sub: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text(message)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
            Text(sub)
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
