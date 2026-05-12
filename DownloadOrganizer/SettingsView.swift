import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var newExclusion = ""
    @State private var importSuccess = false
    @State private var importError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                // Security card
                SettingsCard(title: "Seguridad", icon: "lock.shield.fill", color: .green) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Modo protegido").font(.system(size: 14))
                                Text("Pide confirmación antes de mover archivos grandes")
                                    .font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $organizer.preferences.protectedModeEnabled)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.preferences.protectedModeEnabled) { _ in organizer.saveData() }
                        }
                        if organizer.preferences.protectedModeEnabled {
                            Divider()
                            HStack {
                                Text("Umbral de tamaño").font(.system(size: 14)).foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 6) {
                                    TextField("100", value: $organizer.preferences.protectedModeSizeMB, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .onChange(of: organizer.preferences.protectedModeSizeMB) { _ in organizer.saveData() }
                                    Text("MB").foregroundColor(.secondary).font(.system(size: 13))
                                }
                            }
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Papelera en vez de mover").font(.system(size: 14))
                                Text("Envía los archivos a la Papelera en lugar de organizarlos")
                                    .font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $organizer.preferences.trashInsteadOfMove)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.preferences.trashInsteadOfMove) { _ in organizer.saveData() }
                        }
                        if organizer.preferences.trashInsteadOfMove {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.system(size: 12))
                                Text("Los archivos se enviarán a la Papelera, no a subcarpetas")
                                    .font(.system(size: 11)).foregroundColor(.orange)
                            }
                        }
                    }
                }

                // Schedule card
                SettingsCard(title: "Organización programada", icon: "clock.fill", color: .purple) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Activar programación").font(.system(size: 14))
                            Spacer()
                            Toggle("", isOn: $organizer.schedule.isEnabled)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.schedule.isEnabled) { _ in organizer.applySchedule() }
                        }
                        if organizer.schedule.isEnabled {
                            Divider()
                            HStack {
                                Text("Frecuencia").font(.system(size: 14)).foregroundColor(.secondary)
                                Spacer()
                                Picker("", selection: $organizer.schedule.frequency) {
                                    ForEach(OrganizeSchedule.Frequency.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu).frame(width: 160)
                                .onChange(of: organizer.schedule.frequency) { _ in organizer.applySchedule() }
                            }
                            HStack {
                                Text("Hora").font(.system(size: 14)).foregroundColor(.secondary)
                                Spacer()
                                Stepper("\(String(format: "%02d", organizer.schedule.hour)):00",
                                        value: $organizer.schedule.hour, in: 0...23)
                                    .onChange(of: organizer.schedule.hour) { _ in organizer.applySchedule() }
                            }
                        }
                    }
                }

                // Notifications
                SettingsCard(title: "Notificaciones y sonido", icon: "bell.fill", color: .red) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notificaciones").font(.system(size: 14))
                                Text("Aviso al organizar archivos").font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $organizer.notificationsEnabled)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.notificationsEnabled) { _ in
                                    if organizer.notificationsEnabled { organizer.requestNotificationPermission() }
                                    organizer.saveData()
                                }
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Modo silencioso").font(.system(size: 14))
                                Text("Organiza sin notificaciones").font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $organizer.preferences.silentMode)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.preferences.silentMode) { _ in organizer.saveData() }
                        }
                        Divider()
                        HStack {
                            Text("Sonido al organizar").font(.system(size: 14))
                            Spacer()
                            Toggle("", isOn: $organizer.preferences.soundEnabled)
                                .toggleStyle(.switch).labelsHidden()
                                .onChange(of: organizer.preferences.soundEnabled) { _ in organizer.saveData() }
                        }
                    }
                }

                // Exclusions
                SettingsCard(title: "Extensiones excluidas", icon: "nosign", color: .orange) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tidy nunca moverá archivos con estas extensiones")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                        if !organizer.preferences.excludedExtensions.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(organizer.preferences.excludedExtensions, id: \.self) { ext in
                                    HStack(spacing: 4) {
                                        Text(".\(ext)").font(.system(size: 11, weight: .medium, design: .monospaced))
                                        Button {
                                            organizer.preferences.excludedExtensions.removeAll { $0 == ext }
                                            organizer.saveData()
                                        } label: {
                                            Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.12)).cornerRadius(6)
                                }
                            }
                        }
                        HStack(spacing: 8) {
                            TextField("Agregar extensión (ej: log)", text: $newExclusion)
                                .textFieldStyle(.roundedBorder).font(.system(size: 13))
                                .onSubmit { addExclusion() }
                            Button("Agregar") { addExclusion() }
                                .buttonStyle(.bordered).disabled(newExclusion.isEmpty)
                        }
                    }
                }

                // Min size
                SettingsCard(title: "Tamaño mínimo de archivo", icon: "scalemass", color: .teal) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No mover archivos menores a").font(.system(size: 14))
                            Text("Evita mover archivos temporales o vacíos").font(.system(size: 11)).foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            TextField("0", value: $organizer.preferences.minFileSizeKB, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                                .onChange(of: organizer.preferences.minFileSizeKB) { _ in organizer.saveData() }
                            Text("KB").foregroundColor(.secondary).font(.system(size: 13))
                        }
                    }
                }

                // Watching
                SettingsCard(title: "Vigilancia automática", icon: "eye.fill", color: .green) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vigilar carpeta Downloads").font(.system(size: 14))
                            Text("Organiza cada vez que llega un archivo nuevo").font(.system(size: 11)).foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { organizer.isWatching },
                            set: { $0 ? organizer.startWatching() : organizer.stopWatching() }
                        ))
                        .toggleStyle(.switch).labelsHidden()
                    }
                }

                // Export/Import
                SettingsCard(title: "Configuración", icon: "arrow.up.arrow.down", color: .indigo) {
                    VStack(spacing: 10) {
                        Text("Exporta o importa tus categorías y reglas")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button { exportConfig() } label: {
                                Label("Exportar", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 13)).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            Button { importConfig() } label: {
                                Label("Importar", systemImage: "square.and.arrow.down")
                                    .font(.system(size: 13)).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        if importSuccess {
                            Label("Configuración importada correctamente", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12)).foregroundColor(.green)
                        }
                        if importError {
                            Label("Error al importar. Verifica el archivo.", systemImage: "xmark.circle.fill")
                                .font(.system(size: 12)).foregroundColor(.red)
                        }
                    }
                }

                // About
                SettingsCard(title: "Acerca de", icon: "info.circle.fill", color: .gray) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Versión").foregroundColor(.secondary).font(.system(size: 14))
                            Spacer()
                            Text(TidyConstants.appVersion).font(.system(size: 14, weight: .medium))
                        }
                        HStack {
                            Text("Plataforma").foregroundColor(.secondary).font(.system(size: 14))
                            Spacer()
                            Text("macOS 14+").font(.system(size: 14, weight: .medium))
                        }
                        Divider()
                        HStack {
                            Button("Ver en GitHub") {
                                if let url = URL(string: TidyConstants.repoURL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                            Button("Reiniciar onboarding") {
                                organizer.hasCompletedOnboarding = false
                                organizer.saveData()
                            }
                            .buttonStyle(.bordered).foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(28)
        }
    }

    private func addExclusion() {
        let clean = newExclusion.trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: ".", with: "").lowercased()
        guard !clean.isEmpty, !organizer.preferences.excludedExtensions.contains(clean) else { return }
        organizer.preferences.excludedExtensions.append(clean)
        organizer.saveData()
        newExclusion = ""
    }

    private func exportConfig() {
        guard let data = organizer.exportConfiguration() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "tidy-config.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url { try? data.write(to: url) }
    }

    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            if organizer.importConfiguration(from: data) {
                importSuccess = true; importError = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { importSuccess = false }
            } else {
                importError = true; importSuccess = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { importError = false }
            }
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
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 15, weight: .medium)).foregroundColor(color)
                }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
