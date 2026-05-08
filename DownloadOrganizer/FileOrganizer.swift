import Foundation
import Combine

// MARK: - File Category Model

struct FileCategory: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var folderName: String
    var extensions: [String]
    var icon: String
    var colorHex: String

    static let defaults: [FileCategory] = [
        FileCategory(name: "Imágenes", folderName: "Images",
                     extensions: ["png","jpg","jpeg","gif","webp","bmp","tiff","tif","heic","heif","svg","ico","raw","cr2","nef","arw"],
                     icon: "photo", colorHex: "#34C759"),
        FileCategory(name: "Documentos", folderName: "Documents",
                     extensions: ["pdf","doc","docx","txt","rtf","odt","pages","md","tex","csv","xls","xlsx","ppt","pptx","key","numbers"],
                     icon: "doc.text", colorHex: "#007AFF"),
        FileCategory(name: "Videos", folderName: "Videos",
                     extensions: ["mp4","mov","avi","mkv","wmv","flv","webm","m4v","3gp","mpeg","mpg","ts","mts"],
                     icon: "film", colorHex: "#FF3B30"),
        FileCategory(name: "Audio", folderName: "Audio",
                     extensions: ["mp3","wav","aac","flac","ogg","m4a","wma","aiff","aif","opus","mid","midi"],
                     icon: "music.note", colorHex: "#FF9500"),
        FileCategory(name: "Archivos", folderName: "Archives",
                     extensions: ["zip","rar","7z","tar","gz","bz2","xz","tgz","dmg","iso","pkg","deb","rpm"],
                     icon: "archivebox", colorHex: "#8E44AD"),
        FileCategory(name: "Código", folderName: "Code",
                     extensions: ["swift","py","js","ts","html","css","json","xml","yaml","yml","sh","bash","rb","java","cpp","c","h","go","rs","php","sql","dart"],
                     icon: "curlybraces", colorHex: "#5AC8FA"),
        FileCategory(name: "Aplicaciones", folderName: "Apps",
                     extensions: ["app","apk","ipa","exe","msi"],
                     icon: "app.badge", colorHex: "#FF2D55"),
        FileCategory(name: "Fuentes", folderName: "Fonts",
                     extensions: ["ttf","otf","woff","woff2","eot"],
                     icon: "textformat", colorHex: "#AF52DE"),
    ]
}

// MARK: - Move Log Entry

struct MoveEntry: Identifiable {
    let id = UUID()
    let date: Date
    let fileName: String
    let category: String
    let fromPath: String
    let toPath: String
}

// MARK: - File Organizer

class FileOrganizer: ObservableObject {
    @Published var categories: [FileCategory] = FileCategory.defaults
    @Published var isWatching: Bool = false
    @Published var moveLog: [MoveEntry] = []
    @Published var lastRunStats: (moved: Int, skipped: Int) = (0, 0)
    @Published var isRunning: Bool = false

    private var watcher: DispatchSourceFileSystemObject?
    private var watcherFD: Int32 = -1
    private let queue = DispatchQueue(label: "com.downloadorganizer.watcher", qos: .utility)

    var downloadsURL: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    // MARK: - Manual Organize

    func organizeNow() {
        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performOrganize()
            DispatchQueue.main.async {
                self.lastRunStats = result
                self.isRunning = false
            }
        }
    }

    @discardableResult
    private func performOrganize() -> (moved: Int, skipped: Int) {
        let fm = FileManager.default
        var moved = 0
        var skipped = 0

        guard let files = try? fm.contentsOfDirectory(at: downloadsURL,
                                                       includingPropertiesForKeys: [.isRegularFileKey],
                                                       options: [.skipsHiddenFiles]) else {
            return (0, 0)
        }

        for fileURL in files {
            // Skip directories at root
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if isDir.boolValue { continue }

            let ext = fileURL.pathExtension.lowercased()
            guard !ext.isEmpty else { skipped += 1; continue }

            if let category = categories.first(where: { $0.extensions.contains(ext) }) {
                let destFolder = downloadsURL.appendingPathComponent(category.folderName)

                // Create folder if needed
                if !fm.fileExists(atPath: destFolder.path) {
                    try? fm.createDirectory(at: destFolder, withIntermediateDirectories: true)
                }

                var destURL = destFolder.appendingPathComponent(fileURL.lastPathComponent)

                // Handle name collision
                if fm.fileExists(atPath: destURL.path) {
                    let name = fileURL.deletingPathExtension().lastPathComponent
                    let suffix = Int.random(in: 1000...9999)
                    destURL = destFolder.appendingPathComponent("\(name)_\(suffix).\(ext)")
                }

                do {
                    try fm.moveItem(at: fileURL, to: destURL)
                    moved += 1
                    let entry = MoveEntry(date: Date(),
                                          fileName: fileURL.lastPathComponent,
                                          category: category.name,
                                          fromPath: fileURL.path,
                                          toPath: destURL.path)
                    DispatchQueue.main.async {
                        self.moveLog.insert(entry, at: 0)
                    }
                } catch {
                    skipped += 1
                }
            } else {
                skipped += 1
            }
        }
        return (moved, skipped)
    }

    // MARK: - Auto Watch

    func startWatching() {
        guard !isWatching else { return }

        watcherFD = open(downloadsURL.path, O_EVTONLY)
        guard watcherFD >= 0 else { return }

        watcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watcherFD,
            eventMask: .write,
            queue: queue
        )

        watcher?.setEventHandler { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.performOrganize()
            }
        }

        watcher?.setCancelHandler { [weak self] in
            if let fd = self?.watcherFD, fd >= 0 {
                close(fd)
                self?.watcherFD = -1
            }
        }

        watcher?.resume()
        DispatchQueue.main.async { self.isWatching = true }
    }

    func stopWatching() {
        watcher?.cancel()
        watcher = nil
        DispatchQueue.main.async { self.isWatching = false }
    }

    func clearLog() {
        moveLog.removeAll()
    }
}
