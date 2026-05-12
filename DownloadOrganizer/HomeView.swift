import SwiftUI

struct HomeView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var showPreview = false
    @State private var previewItems: [(fileName: String, category: String, destination: String)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Header
                HStack {
                    Text("Panel Principal")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(organizer.downloadsURL)
                    } label: {
                        Label("Abrir carpeta", systemImage: "arrow.up.right.square")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }

                // Protected mode alert
                if !organizer.pendingLargeFiles.isEmpty {
                    ProtectedFilesAlert()
                }

                // Error badge
                if !organizer.errorLog.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(organizer.errorLog.count) archivo(s) no pudieron moverse — revisa el Historial")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }

                // Manual organize card
                ManualOrganizeCard(showPreview: $showPreview, previewItems: $previewItems)

                // Auto watch card
                AutoWatchCard()

                // Stats
                if organizer.lastRunStats.moved > 0 || organizer.lastRunStats.skipped > 0 {
                    StatsCard(moved: organizer.lastRunStats.moved,
                              skipped: organizer.lastRunStats.skipped,
                              errors: organizer.lastRunStats.errors)
                }

                // Recent activity
                if !organizer.moveLog.isEmpty {
                    RecentActivityCard(onViewAll: {
                        NotificationCenter.default.post(name: .init("tidy.navigate.log"), object: nil)
                    })
                }

                Spacer(minLength: 20)
            }
            .padding(28)
        }
        .sheet(isPresented: $showPreview) {
            PreviewSheet(items: previewItems) {
                showPreview = false
                organizer.organizeNow()
            } onCancel: {
                showPreview = false
            }
            .environmentObject(organizer)
        }
    }
}

// MARK: - Protected Files Alert

struct ProtectedFilesAlert: View {
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                Text("Archivos grandes — confirmación requerida")
                    .font(.system(size: 14, weight: .semibold))
            }

            ForEach(organizer.pendingLargeFiles, id: \.url) { item in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.url.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text("→ \(item.destination.lastPathComponent)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Omitir") {
                        organizer.dismissPendingFile(item)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)

                    Button("Mover") {
                        organizer.confirmPendingFile(item)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Manual Organize Card

struct ManualOrganizeCard: View {
    @EnvironmentObject var organizer: FileOrganizer
    @Binding var showPreview: Bool
    @Binding var previewItems: [(fileName: String, category: String, destination: String)]
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.15), .blue.opacity(0.05)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: organizer.isRunning ? "arrow.triangle.2.circlepath" : "folder.badge.gearshape")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(animateIcon ? 360 : 0))
                    .animation(organizer.isRunning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                               value: animateIcon)
                    .onChange(of: organizer.isRunning) { running in animateIcon = running }
            }

            VStack(spacing: 6) {
                Text("Organizar Ahora")
                    .font(.system(size: 18, weight: .semibold))
                Text(organizer.preferences.trashInsteadOfMove
                     ? "Enviará los archivos sueltos en Downloads a la Papelera."
                     : "Mueve todos los archivos sueltos en Downloads\na sus carpetas correspondientes.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button {
                    previewItems = organizer.previewOrganize()
                    showPreview = true
                } label: {
                    Label("Vista previa", systemImage: "eye")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .disabled(organizer.isRunning)

                Button {
                    organizer.organizeNow()
                } label: {
                    HStack(spacing: 8) {
                        if organizer.isRunning {
                            ProgressView().scaleEffect(0.8)
                            Text("Organizando...")
                        } else {
                            Image(systemName: organizer.preferences.trashInsteadOfMove ? "trash" : "play.fill")
                            Text(organizer.preferences.trashInsteadOfMove ? "Enviar a Papelera" : "Organizar")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(organizer.preferences.trashInsteadOfMove ? .red : .blue)
                .disabled(organizer.isRunning)
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Preview Sheet with Quick Look

struct PreviewSheet: View {
    let items: [(fileName: String, category: String, destination: String)]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var organizer: FileOrganizer
    @State private var selectedFile: URL? = nil
    @State private var showingQuickLook = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vista previa")
                        .font(.system(size: 17, weight: .semibold))
                    Text("\(items.count) archivo\(items.count == 1 ? "" : "s") se moverán")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Cancelar") { onCancel() }
                    .buttonStyle(.plain).foregroundColor(.secondary)
            }
            .padding(20)

            Divider()

            if items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40)).foregroundColor(.green)
                    Text("No hay archivos para organizar")
                        .font(.system(size: 15)).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(items, id: \.fileName) { item in
                    HStack(spacing: 12) {
                        let cat = organizer.categories.first { $0.name == item.category }
                        Image(systemName: cat?.icon ?? "folder")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: cat?.colorHex ?? "#007AFF"))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.fileName)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Text("→ \(item.destination)/")
                                .font(.system(size: 11)).foregroundColor(.secondary)
                        }

                        Spacer()

                        // Quick Look button
                        Button {
                            let fileURL = organizer.downloadsURL.appendingPathComponent(item.fileName)
                            selectedFile = fileURL
                            showingQuickLook = true
                        } label: {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Vista rápida")

                        Text(item.category)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color(hex: cat?.colorHex ?? "#007AFF").opacity(0.12))
                            .foregroundColor(Color(hex: cat?.colorHex ?? "#007AFF"))
                            .cornerRadius(6)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Button("Cancelar") { onCancel() }.buttonStyle(.bordered)
                Spacer()
                Button("Organizar \(items.count) archivo\(items.count == 1 ? "" : "s")") { onConfirm() }
                    .buttonStyle(.borderedProminent)
                    .disabled(items.isEmpty)
            }
            .padding(20)
        }
        .frame(width: 500, height: 440)
        .onChange(of: showingQuickLook) { showing in
            if showing, let url = selectedFile {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                showingQuickLook = false
            }
        }
    }
}

// MARK: - Auto Watch Card

struct AutoWatchCard: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var pulseAnim = false

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(organizer.isWatching ? Color.green.opacity(0.12) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                if organizer.isWatching {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulseAnim ? 1.4 : 1.0)
                        .opacity(pulseAnim ? 0 : 1)
                        .animation(.easeOut(duration: 1.2).repeatForever(), value: pulseAnim)
                        .onAppear { pulseAnim = true }
                        .onDisappear { pulseAnim = false }
                }
                Image(systemName: organizer.isWatching ? "eye.fill" : "eye.slash")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(organizer.isWatching ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Vigilancia Automática")
                    .font(.system(size: 15, weight: .semibold))
                Text(organizer.isWatching
                     ? "Organizando automáticamente al detectar nuevos archivos."
                     : "Actívalo para organizar cada vez que llegue un archivo nuevo.")
                    .font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { organizer.isWatching },
                set: { $0 ? organizer.startWatching() : organizer.stopWatching() }
            ))
            .toggleStyle(.switch).labelsHidden()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(organizer.isWatching ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1))
        .animation(.easeInOut(duration: 0.3), value: organizer.isWatching)
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let moved: Int
    let skipped: Int
    let errors: Int

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: moved, label: "Movidos", icon: "checkmark.circle.fill", color: .green)
            Divider().frame(height: 40)
            StatItem(value: skipped, label: "Omitidos", icon: "minus.circle.fill", color: .orange)
            if errors > 0 {
                Divider().frame(height: 40)
                StatItem(value: errors, label: "Errores", icon: "exclamationmark.circle.fill", color: .red)
            }
        }
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)").font(.system(size: 22, weight: .bold, design: .rounded))
                Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    @EnvironmentObject var organizer: FileOrganizer
    var onViewAll: (() -> Void)? = nil
    private let maxVisible = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Actividad Reciente")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if organizer.moveLog.count > maxVisible {
                    Button("Ver todos (\(organizer.moveLog.count))") { onViewAll?() }
                        .font(.system(size: 12)).buttonStyle(.plain).foregroundColor(.blue)
                } else {
                    Text("\(organizer.moveLog.count) archivo\(organizer.moveLog.count == 1 ? "" : "s")")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
            }

            ForEach(organizer.moveLog.prefix(maxVisible)) { entry in
                HStack(spacing: 10) {
                    Image(systemName: entry.undone ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(entry.undone ? .orange : .blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.fileName)
                            .font(.system(size: 13, weight: .medium)).lineLimit(1)
                            .strikethrough(entry.undone, color: .secondary)
                        Text("→ \(entry.category)")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
            }

            if organizer.moveLog.count > maxVisible {
                HStack {
                    Spacer()
                    Text("... y \(organizer.moveLog.count - maxVisible) más")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
    }
}
