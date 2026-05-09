import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var organizer: FileOrganizer
    @State private var selectedCategory: FileCategory?
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Categorías")
                        .font(.system(size: 24, weight: .bold))
                    Text("Define qué extensiones van a cada carpeta")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Nueva categoría", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            // List
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach($organizer.categories) { $category in
                        CategoryRow(category: $category) {
                            organizer.categories.removeAll { $0.id == category.id }
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCategorySheet { newCategory in
                organizer.categories.append(newCategory)
            }
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    @Binding var category: FileCategory
    let onDelete: () -> Void
    @State private var isExpanded = false
    @State private var newExtension = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: category.colorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: category.colorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .semibold))
                    Text("📁 \(category.folderName)  •  \(category.extensions.count) extensiones")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Extension pills preview
                HStack(spacing: 4) {
                    ForEach(category.extensions.prefix(3), id: \.self) { ext in
                        Text(".\(ext)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: category.colorHex).opacity(0.12))
                            .foregroundColor(Color(hex: category.colorHex))
                            .cornerRadius(4)
                    }
                    if category.extensions.count > 3 {
                        Text("+\(category.extensions.count - 3)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            // Expanded detail
            if isExpanded {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    // All extensions
                    FlowLayout(spacing: 6) {
                        ForEach(category.extensions, id: \.self) { ext in
                            ExtensionTag(ext: ext) {
                                category.extensions.removeAll { $0 == ext }
                            }
                        }
                    }

                    // Add extension
                    HStack(spacing: 8) {
                        TextField("Agregar extensión (ej: webp)", text: $newExtension)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit { addExtension() }
                        Button("Agregar") { addExtension() }
                            .buttonStyle(.bordered)
                            .disabled(newExtension.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private func addExtension() {
        let clean = newExtension.trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: ".", with: "")
                                .lowercased()
        guard !clean.isEmpty, !category.extensions.contains(clean) else { return }
        category.extensions.append(clean)
        newExtension = ""
    }
}

// MARK: - Extension Tag

struct ExtensionTag: View {
    let ext: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(".\(ext)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            Button { onRemove() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.07))
        .cornerRadius(6)
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    let onSave: (FileCategory) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var folderName = ""
    @State private var extensionsText = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "#007AFF"

    let icons = ["folder","doc.text","photo","film","music.note","archivebox",
                 "curlybraces","app.badge","textformat","globe","shippingbox"]
    let colors = ["#007AFF","#34C759","#FF3B30","#FF9500","#8E44AD","#5AC8FA","#FF2D55","#AF52DE"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Nueva Categoría")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Cancelar") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(20)

            Divider()

            Form {
                Section("Información") {
                    TextField("Nombre (ej: Imágenes)", text: $name)
                    TextField("Nombre de carpeta (ej: Images)", text: $folderName)
                    TextField("Extensiones separadas por coma (ej: png, jpg, gif)", text: $extensionsText)
                }

                Section("Ícono") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.15) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle().fill(Color(hex: color)).frame(width: 28, height: 28)
                                    if selectedColor == color {
                                        Circle().stroke(Color.primary, lineWidth: 2).frame(width: 34, height: 34)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Guardar") {
                    let exts = extensionsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
                               .replacingOccurrences(of: ".", with: "").lowercased() }
                        .filter { !$0.isEmpty }
                    let cat = FileCategory(name: name,
                                           folderName: folderName.isEmpty ? name : folderName,
                                           extensions: exts,
                                           icon: selectedIcon,
                                           colorHex: selectedColor)
                    onSave(cat)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || extensionsText.isEmpty)
            }
            .padding(20)
        }
        .frame(width: 440, height: 520)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Color extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
