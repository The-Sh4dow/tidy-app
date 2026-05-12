import SwiftUI

struct RulesView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reglas")
                        .font(.system(size: 24, weight: .bold))
                    Text("Mueve archivos por nombre, tamaño o fecha")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    showingAdd = true
                } label: {
                    Label("Nueva regla", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            if organizer.rules.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Sin reglas personalizadas")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Crea reglas para mover archivos por nombre,\ntamaño, extensión o antigüedad.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("Crear primera regla") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach($organizer.rules) { $rule in
                            RuleRow(rule: $rule) {
                                organizer.rules.removeAll { $0.id == rule.id }
                                organizer.saveData()
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddRuleSheet { newRule in
                organizer.rules.append(newRule)
                organizer.saveData()
            }
        }
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    @Binding var rule: FileRule
    let onDelete: () -> Void
    @EnvironmentObject var organizer: FileOrganizer

    var body: some View {
        HStack(spacing: 14) {
            // Enable toggle
            Toggle("", isOn: $rule.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: rule.isEnabled) { _ in organizer.saveData() }

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 6) {
                    Text(rule.condition.rawValue)
                        .font(.system(size: 11))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    Text("\"\(rule.conditionValue)\"")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(rule.destinationFolder)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .opacity(rule.isEnabled ? 1 : 0.5)
    }
}

// MARK: - Add Rule Sheet

struct AddRuleSheet: View {
    let onSave: (FileRule) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var condition: FileRule.RuleCondition = .nameContains
    @State private var conditionValue = ""
    @State private var destinationFolder = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nueva Regla")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Cancelar") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(20)

            Divider()

            Form {
                Section("Nombre de la regla") {
                    TextField("Ej: Facturas del trabajo", text: $name)
                }
                Section("Condición") {
                    Picker("Condición", selection: $condition) {
                        ForEach(FileRule.RuleCondition.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    TextField(conditionPlaceholder, text: $conditionValue)
                }
                Section("Mover a carpeta") {
                    TextField("Ej: Facturas", text: $destinationFolder)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Guardar regla") {
                    let rule = FileRule(name: name.isEmpty ? "Regla nueva" : name,
                                       condition: condition,
                                       conditionValue: conditionValue,
                                       destinationFolder: destinationFolder.isEmpty ? "Otros" : destinationFolder)
                    onSave(rule)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(conditionValue.isEmpty)
            }
            .padding(20)
        }
        .frame(width: 400, height: 380)
    }

    var conditionPlaceholder: String {
        switch condition {
        case .nameContains:    return "Ej: factura"
        case .nameStartsWith:  return "Ej: IMG_"
        case .extensionIs:     return "Ej: pdf"
        case .sizeGreaterThan: return "Tamaño en MB (ej: 100)"
        case .olderThanDays:   return "Días (ej: 30)"
        }
    }
}
