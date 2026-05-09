import SwiftUI

struct StatsView: View {
    @EnvironmentObject var organizer: FileOrganizer

    let dayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    var maxDayCount: Int { organizer.weeklyStats.byDay.values.max() ?? 1 }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estadísticas")
                            .font(.system(size: 24, weight: .bold))
                        Text("Actividad de los últimos 7 días")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        organizer.recalcStats()
                    } label: {
                        Label("Actualizar", systemImage: "arrow.clockwise")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }

                // Top KPIs
                HStack(spacing: 16) {
                    KPICard(value: "\(organizer.weeklyStats.totalMoved)",
                            label: "Archivos\norganizados",
                            icon: "checkmark.circle.fill",
                            color: .green)
                    KPICard(value: "\(organizer.moveLog.filter { !$0.undone }.count)",
                            label: "Total\nacumulado",
                            icon: "archivebox.fill",
                            color: .blue)
                    KPICard(value: organizer.weeklyStats.topCategory ?? "—",
                            label: "Categoría\nmás activa",
                            icon: "star.fill",
                            color: .yellow)
                    KPICard(value: "\(organizer.moveLog.filter { $0.undone }.count)",
                            label: "Movimientos\ndeshecho",
                            icon: "arrow.uturn.backward.circle.fill",
                            color: .orange)
                }

                // Bar chart by day
                if !organizer.weeklyStats.byDay.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actividad por día")
                            .font(.system(size: 15, weight: .semibold))

                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(1...7, id: \.self) { day in
                                let count = organizer.weeklyStats.byDay[day] ?? 0
                                let height = maxDayCount > 0 ? CGFloat(count) / CGFloat(maxDayCount) * 120 : 0
                                VStack(spacing: 6) {
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(count > 0 ? Color.blue : Color.primary.opacity(0.08))
                                        .frame(height: max(height, 4))
                                    Text(dayNames[day - 1])
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 160)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
                    }
                }

                // Category breakdown
                if !organizer.weeklyStats.byCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Por categoría")
                            .font(.system(size: 15, weight: .semibold))

                        let total = max(organizer.weeklyStats.totalMoved, 1)
                        let sorted = organizer.weeklyStats.byCategory.sorted { $0.value > $1.value }

                        ForEach(sorted, id: \.key) { cat, count in
                            let cat_info = organizer.categories.first { $0.name == cat }
                            let pct = Double(count) / Double(total)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: cat_info?.icon ?? "folder")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: cat_info?.colorHex ?? "#007AFF"))
                                    Text(cat)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text("\(count) archivo\(count == 1 ? "" : "s")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("(\(Int(pct * 100))%)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: cat_info?.colorHex ?? "#007AFF"))
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.07)).frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(hex: cat_info?.colorHex ?? "#007AFF"))
                                            .frame(width: geo.size.width * pct, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
                }

                if organizer.weeklyStats.totalMoved == 0 {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Sin actividad esta semana")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        Text("Organiza algunos archivos para ver tus estadísticas")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(40)
                }

                Spacer(minLength: 20)
            }
            .padding(28)
        }
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
    }
}
