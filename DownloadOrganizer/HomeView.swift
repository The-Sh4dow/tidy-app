import SwiftUI

struct HomeView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var showStats = false
    @State private var animatePulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Panel Principal")
                            .font(.system(size: 24, weight: .bold))
                        Text(organizer.downloadsURL.path)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(organizer.downloadsURL)
                    } label: {
                        Label("Abrir carpeta", systemImage: "arrow.up.right.square")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }

                // Manual organize card
                ManualOrganizeCard()

                // Auto watch card
                AutoWatchCard()

                // Stats (if any)
                if organizer.lastRunStats.moved > 0 || organizer.lastRunStats.skipped > 0 {
                    StatsCard(moved: organizer.lastRunStats.moved,
                              skipped: organizer.lastRunStats.skipped)
                }

                // Recent activity preview
                if !organizer.moveLog.isEmpty {
                    RecentActivityCard()
                }

                Spacer(minLength: 40)
            }
            .padding(28)
        }
    }
}

// MARK: - Manual Organize Card

struct ManualOrganizeCard: View {
    @EnvironmentObject var organizer: FileOrganizer
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
                    .animation(organizer.isRunning
                               ? .linear(duration: 1).repeatForever(autoreverses: false)
                               : .default, value: animateIcon)
                    .onChange(of: organizer.isRunning) { running in
                        animateIcon = running
                    }
            }

            VStack(spacing: 6) {
                Text("Organizar Ahora")
                    .font(.system(size: 18, weight: .semibold))
                Text("Mueve todos los archivos existentes en Downloads\na sus carpetas correspondientes.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                organizer.organizeNow()
            } label: {
                HStack(spacing: 8) {
                    if organizer.isRunning {
                        ProgressView().scaleEffect(0.8)
                        Text("Organizando...")
                    } else {
                        Image(systemName: "play.fill")
                        Text("Organizar Downloads")
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(organizer.isRunning)
            .cornerRadius(10)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
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
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { organizer.isWatching },
                set: { enabled in
                    if enabled { organizer.startWatching() }
                    else { organizer.stopWatching() }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
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

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: moved, label: "Movidos", icon: "checkmark.circle.fill", color: .green)
            Divider().frame(height: 40)
            StatItem(value: skipped, label: "Omitidos", icon: "minus.circle.fill", color: .orange)
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
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Actividad Reciente")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(organizer.moveLog.count) archivos")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            ForEach(organizer.moveLog.prefix(4)) { entry in
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.fileName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text("→ \(entry.category)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
    }
}
