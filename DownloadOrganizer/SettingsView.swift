import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ajustes")
                            .font(.system(size: 24, weight: .bold))
                        Text("Personaliza cómo funciona Tidy")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Schedule card
                SettingsCard(title: "Organización programada", icon: "clock.fill", color: .purple) {
                    VStack(spacing: 14) {
                        HStack {
                            Text("Activar programación")
                                .font(.system(size: 14))
                            Spacer()
                            Toggle("", isOn: $organizer.schedule.isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: organizer.schedule.isEnabled) { _ in
                                    organizer.applySchedule()
                                }
                        }

                        if organizer.schedule.isEnabled {
                            Divider()
                            HStack {
                                Text("Frecuencia")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("", selection: $organizer.schedule.frequency) {
                                    ForEach(OrganizeSchedule.Frequency.allCases, id: \.self) { f in
                                        Text(f.rawValue).tag(f)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)
                                .onChange(of: organizer.schedule.frequency) { _ in
                                    organizer.applySchedule()
                                }
                            }

                            HStack {
                                Text("Hora de inicio")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Stepper("\(String(format: "%02d", organizer.schedule.hour)):00",
                                        value: $organizer.schedule.hour, in: 0...23)
                                    .onChange(of: organizer.schedule.hour) { _ in
                                        organizer.applySchedule()
                                    }
                            }
                        }
                    }
                }

                // Notifications card
                SettingsCard(title: "Notificaciones", icon: "bell.fill", color: .red) {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Notificar al organizar")
                                    .font(.system(size: 14))
                                Text("Aviso cuando Tidy mueve archivos automáticamente")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $organizer.notificationsEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: organizer.notificationsEnabled) { _ in
                                    if organizer.notificationsEnabled {
                                        organizer.requestNotificationPermission()
                                    }
                                    organizer.saveData()
                                }
                        }

                        if organizer.notificationsEnabled {
                            Divider()
                            Button {
                                organizer.sendNotification(
                                    title: "Tidy organizó 5 archivos",
                                    body: "Tu carpeta Downloads está ordenada ✨"
                                )
                            } label: {
                                Label("Enviar notificación de prueba", systemImage: "paperplane")
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Watching card
                SettingsCard(title: "Vigilancia automática", icon: "eye.fill", color: .green) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Vigilar carpeta Downloads")
                                .font(.system(size: 14))
                            Text("Organiza cada vez que llega un archivo nuevo")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { organizer.isWatching },
                            set: { $0 ? organizer.startWatching() : organizer.stopWatching() }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }

                // About card
                SettingsCard(title: "Acerca de", icon: "info.circle.fill", color: .gray) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Versión")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Spacer()
                            Text("1.5.0")
                                .font(.system(size: 14, weight: .medium))
                        }
                        HStack {
                            Text("Plataforma")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Spacer()
                            Text("macOS 14+")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Divider()
                        HStack {
                            Button("Ver en GitHub") {
                                NSWorkspace.shared.open(URL(string: "https://github.com/The-Sh4dow/tidy-app")!)
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(28)
        }
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
