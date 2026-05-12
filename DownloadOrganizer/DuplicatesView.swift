import SwiftUI

struct DuplicatesView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duplicados")
                        .font(.system(size: 24, weight: .bold))
                    Text("Archivos con el mismo nombre en distintas subcarpetas")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isScanning = true
                    organizer.findDuplicates()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isScanning = false }
                } label: {
                    if isScanning {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Buscando...")
                        }
                    } else {
                        Label("Buscar duplicados", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .font(.system(size: 13))
                .buttonStyle(.borderedProminent)
                .disabled(isScanning)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            if organizer.duplicates.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: isScanning ? "arrow.triangle.2.circlepath" : "doc.badge.checkmark")
                        .font(.system(size: 52))
                        .foregroundColor(.secondary.opacity(0.4))
                        .rotationEffect(.degrees(isScanning ? 360 : 0))
                        .animation(isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                   value: isScanning)
                    Text(isScanning ? "Buscando duplicados..." : "Sin duplicados encontrados")
                        .font(.system(size: 17, weight: .medium)).foregroundColor(.secondary)
                    if !isScanning {
                        Text("Pulsa \"Buscar duplicados\" para escanear\ntu carpeta Downloads y subcarpetas.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(organizer.duplicates.count) grupo\(organizer.duplicates.count == 1 ? "" : "s") de archivos duplicados")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)

                    List(organizer.duplicates) { group in
                        DuplicateGroupRow(group: group)
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

// MARK: - Duplicate Group Row

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.fileName)
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(group.files.count) copias encontradas")
                            .font(.system(size: 12)).foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded file list
            if isExpanded {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 0) {
                    ForEach(group.files, id: \.path) { fileURL in
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.leading, 14)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileURL.deletingLastPathComponent().lastPathComponent)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(fileURL.path.replacingOccurrences(
                                    of: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "",
                                    with: "~/Downloads"))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            } label: {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 12)).foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Mostrar en Finder")

                            Button {
                                try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12)).foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help("Mover a Papelera")
                        }
                        .padding(.vertical, 8)
                        .padding(.trailing, 14)

                        if fileURL != group.files.last {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}
