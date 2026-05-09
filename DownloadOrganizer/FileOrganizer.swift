import Foundation
import Combine
import UserNotifications

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
    var undone: Bool = false
}

// MARK: - Custom Rule

struct FileRule: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var isEnabled: Bool = true
    var condition: RuleCondition
    var conditionValue: String
    var destinationFolder: String

    enum RuleCondition: String, CaseIterable, Codable {
        case nameContains    = "Nombre contiene"
        case nameStartsWith  = "Nombre empieza con"
        case sizeGreaterThan = "Tamaño mayor a (MB)"
        case olderThanDays   = "Más antiguo que (días)"
        case extensionIs     = "Extensión es"
    }
}

// MARK: - Schedule

struct OrganizeSchedule: Codable {
    var isEnabled: Bool = false
    var frequency: Frequency = .daily
    var hour: Int = 9

    enum Frequency: String, CaseIterable, Codable {
        case hourly  = "Cada hora"
        case daily   = "Diariamente"
        case weekly  = "Semanalmente"
    }
}

// MARK: - Weekly Stats

struct WeeklyStats {
    var totalMoved: Int = 0
    var byCategory: [String: Int] = [:]
    var byDay: [Int: Int] = [:]
    var topCategory: String? { byCategory.max(by: { $0.value < $1.value })?.key }
}

// MARK: - File Organizer

class FileOrganizer: ObservableObject {
    @Published var categories: [FileCategory] = FileCategory.defaults
    @Published var rules: [FileRule] = []
    @Published var schedule: OrganizeSchedule = OrganizeSchedule()
    @Published var isWatching: Bool = false
    @Published var moveLog: [MoveEntry] = []
    @Published var lastRunStats: (moved: Int, skipped: Int) = (0, 0)
    @Published var isRunning: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var weeklyStats: WeeklyStats = WeeklyStats()

    private var watcher: DispatchSourceFileSystemObject?
    private var watcherFD: Int32 = -1
    private var scheduleTimer: Timer?
    private let queue = DispatchQueue(label: "com.tidy.watcher", qos: .utility)
    private let ud = UserDefaults.standard

    var downloadsURL: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    init() {
        loadData()
        requestNotificationPermission()
        if isWatching { startWatching() }
        applySchedule()
    }

    // MARK: - Persistence

    func loadData() {
        if let d = ud.data(forKey: "tidy.categories"),
           let v = try? JSONDecoder().decode([FileCategory].self, from: d) { categories = v }
        if let d = ud.data(forKey: "tidy.rules"),
           let v = try? JSONDecoder().decode([FileRule].self, from: d) { rules = v }
        if let d = ud.data(forKey: "tidy.schedule"),
           let v = try? JSONDecoder().decode(OrganizeSchedule.self, from: d) { schedule = v }
        notificationsEnabled = ud.bool(forKey: "tidy.notifications")
        isWatching = ud.bool(forKey: "tidy.watching")
    }

    func saveData() {
        if let d = try? JSONEncoder().encode(categories) { ud.set(d, forKey: "tidy.categories") }
        if let d = try? JSONEncoder().encode(rules)      { ud.set(d, forKey: "tidy.rules") }
        if let d = try? JSONEncoder().encode(schedule)   { ud.set(d, forKey: "tidy.schedule") }
        ud.set(notificationsEnabled, forKey: "tidy.notifications")
        ud.set(isWatching, forKey: "tidy.watching")
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { self.notificationsEnabled = granted }
        }
    }

    func sendNotification(title: String, body: String) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }

    // MARK: - Organize

    func organizeNow() {
        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performOrganize(folder: self.downloadsURL)
            DispatchQueue.main.async {
                self.lastRunStats = result
                self.isRunning = false
                self.recalcStats()
                self.saveData()
                if result.moved > 0 {
                    self.sendNotification(
                        title: "Tidy organizó \(result.moved) archivo\(result.moved == 1 ? "" : "s")",
                        body: "Tu carpeta Downloads está ordenada ✨"
                    )
                }
            }
        }
    }

    @discardableResult
    func performOrganize(folder: URL) -> (moved: Int, skipped: Int) {
        let fm = FileManager.default
        var moved = 0, skipped = 0

        guard let files = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]) else { return (0, 0) }

        for fileURL in files {
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if isDir.boolValue { continue }
            let ext = fileURL.pathExtension.lowercased()
            guard !ext.isEmpty else { skipped += 1; continue }

            if let ruleFolder = matchingRule(for: fileURL) {
                move(fileURL, to: folder.appendingPathComponent(ruleFolder), fm: fm) ? (moved += 1) : (skipped += 1)
            } else if let cat = categories.first(where: { $0.extensions.contains(ext) }) {
                move(fileURL, to: folder.appendingPathComponent(cat.folderName), fm: fm) ? (moved += 1) : (skipped += 1)
            } else {
                skipped += 1
            }
        }
        return (moved, skipped)
    }

    private func matchingRule(for fileURL: URL) -> String? {
        let fm = FileManager.default
        let name = fileURL.lastPathComponent
        let ext  = fileURL.pathExtension.lowercased()
        let attrs = try? fm.attributesOfItem(atPath: fileURL.path)
        let sizeMB = (attrs?[.size] as? Int64 ?? 0) / 1_048_576
        let age = Int(Date().timeIntervalSince(attrs?[.modificationDate] as? Date ?? Date()) / 86400)

        for rule in rules where rule.isEnabled {
            let val = rule.conditionValue.lowercased()
            switch rule.condition {
            case .nameContains:    if name.lowercased().contains(val)   { return rule.destinationFolder }
            case .nameStartsWith:  if name.lowercased().hasPrefix(val)  { return rule.destinationFolder }
            case .extensionIs:     if ext == val                         { return rule.destinationFolder }
            case .sizeGreaterThan: if let mb = Int64(val), sizeMB > mb  { return rule.destinationFolder }
            case .olderThanDays:   if let d = Int(val), age > d          { return rule.destinationFolder }
            }
        }
        return nil
    }

    @discardableResult
    private func move(_ fileURL: URL, to destFolder: URL, fm: FileManager) -> Bool {
        if !fm.fileExists(atPath: destFolder.path) {
            try? fm.createDirectory(at: destFolder, withIntermediateDirectories: true)
        }
        var dest = destFolder.appendingPathComponent(fileURL.lastPathComponent)
        if fm.fileExists(atPath: dest.path) {
            let n = fileURL.deletingPathExtension().lastPathComponent
            let e = fileURL.pathExtension
            dest = destFolder.appendingPathComponent("\(n)_\(Int.random(in: 1000...9999)).\(e)")
        }
        do {
            try fm.moveItem(at: fileURL, to: dest)
            let catName = categories.first(where: { $0.folderName == destFolder.lastPathComponent })?.name
                          ?? destFolder.lastPathComponent
            let entry = MoveEntry(date: Date(), fileName: fileURL.lastPathComponent,
                                  category: catName, fromPath: fileURL.path, toPath: dest.path)
            DispatchQueue.main.async { self.moveLog.insert(entry, at: 0) }
            return true
        } catch { return false }
    }

    // MARK: - Undo

    func undo(entry: MoveEntry) {
        let fm = FileManager.default
        let from = URL(fileURLWithPath: entry.toPath)
        let to   = URL(fileURLWithPath: entry.fromPath)
        do {
            let parent = to.deletingLastPathComponent()
            if !fm.fileExists(atPath: parent.path) { try fm.createDirectory(at: parent, withIntermediateDirectories: true) }
            try fm.moveItem(at: from, to: to)
            if let i = moveLog.firstIndex(where: { $0.id == entry.id }) { moveLog[i].undone = true }
            recalcStats()
            sendNotification(title: "Movimiento deshecho", body: "\(entry.fileName) regresó a su lugar original")
        } catch { }
    }

    func undoLast() {
        if let last = moveLog.first(where: { !$0.undone }) { undo(entry: last) }
    }

    // MARK: - Schedule

    func applySchedule() {
        scheduleTimer?.invalidate()
        scheduleTimer = nil
        guard schedule.isEnabled else { saveData(); return }
        let interval: TimeInterval
        switch schedule.frequency {
        case .hourly:  interval = 3600
        case .daily:   interval = 86400
        case .weekly:  interval = 604800
        }
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.organizeNow()
        }
        saveData()
    }

    // MARK: - Watch

    func startWatching() {
        guard !isWatching else { return }
        watcherFD = open(downloadsURL.path, O_EVTONLY)
        guard watcherFD >= 0 else { return }
        watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: watcherFD, eventMask: .write, queue: queue)
        watcher?.setEventHandler { [weak self] in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.performOrganize(folder: self.downloadsURL)
                self.recalcStats()
            }
        }
        watcher?.setCancelHandler { [weak self] in
            if let fd = self?.watcherFD, fd >= 0 { close(fd); self?.watcherFD = -1 }
        }
        watcher?.resume()
        DispatchQueue.main.async { self.isWatching = true; self.saveData() }
    }

    func stopWatching() {
        watcher?.cancel(); watcher = nil
        DispatchQueue.main.async { self.isWatching = false; self.saveData() }
    }

    // MARK: - Stats

    func recalcStats() {
        var s = WeeklyStats()
        let weekAgo = Date().addingTimeInterval(-604800)
        let recent = moveLog.filter { $0.date > weekAgo && !$0.undone }
        s.totalMoved = recent.count
        for e in recent {
            s.byCategory[e.category, default: 0] += 1
            let day = Calendar.current.component(.weekday, from: e.date)
            s.byDay[day, default: 0] += 1
        }
        weeklyStats = s
    }

    func clearLog() { moveLog.removeAll(); recalcStats() }
}
