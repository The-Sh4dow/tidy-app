import Foundation
import Combine
import UserNotifications
import AppKit

// MARK: - Constants

enum TidyConstants {
    static let repoURL = "https://github.com/The-Sh4dow/tidy-app"
    static let appVersion = "1.7.0"
    static let maxLogEntries = 500
}

// MARK: - File Category

struct FileCategory: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var folderName: String
    var extensions: [String]
    var icon: String
    var colorHex: String

    static let defaults: [FileCategory] = [
        FileCategory(name: "Imágenes", folderName: "Images",
                     extensions: ["png","jpg","jpeg","gif","webp","bmp","tiff","tif","heic","heif","svg","ico","raw","cr2","nef","arw","avif","jxl"],
                     icon: "photo", colorHex: "#34C759"),
        FileCategory(name: "Documentos", folderName: "Documents",
                     extensions: ["pdf","doc","docx","txt","rtf","odt","pages","md","tex","csv","xls","xlsx","ppt","pptx","key","numbers","ics","vcf"],
                     icon: "doc.text", colorHex: "#007AFF"),
        FileCategory(name: "Videos", folderName: "Videos",
                     extensions: ["mp4","mov","avi","mkv","wmv","flv","webm","m4v","3gp","mpeg","mpg","ts","mts"],
                     icon: "film", colorHex: "#FF3B30"),
        FileCategory(name: "Audio", folderName: "Audio",
                     extensions: ["mp3","wav","aac","flac","ogg","m4a","wma","aiff","aif","opus","mid","midi"],
                     icon: "music.note", colorHex: "#FF9500"),
        FileCategory(name: "Archivos", folderName: "Archives",
                     extensions: ["zip","rar","7z","tar","gz","bz2","xz","tgz","iso","pkg","deb","rpm"],
                     icon: "archivebox", colorHex: "#8E44AD"),
        FileCategory(name: "Código", folderName: "Code",
                     extensions: ["swift","py","js","ts","html","css","json","xml","yaml","yml","sh","bash","rb","java","cpp","c","h","go","rs","php","sql","dart","kt","kts","vue","svelte","toml","env"],
                     icon: "curlybraces", colorHex: "#5AC8FA"),
        FileCategory(name: "Aplicaciones", folderName: "Apps",
                     extensions: ["app","apk","ipa","exe","msi","dmg"],
                     icon: "app.badge", colorHex: "#FF2D55"),
        FileCategory(name: "Fuentes", folderName: "Fonts",
                     extensions: ["ttf","otf","woff","woff2","eot"],
                     icon: "textformat", colorHex: "#AF52DE"),
        FileCategory(name: "Libros", folderName: "Books",
                     extensions: ["epub","mobi","azw3","djvu","fb2"],
                     icon: "books.vertical", colorHex: "#FF6B35"),
        FileCategory(name: "Diseño", folderName: "Design",
                     extensions: ["psd","ai","sketch","fig","xcf","indd","xd","afdesign","afphoto"],
                     icon: "paintbrush", colorHex: "#FF2D9A"),
    ]
}

// MARK: - Move Entry

struct MoveEntry: Identifiable {
    let id = UUID()
    let date: Date
    let fileName: String
    let category: String
    let fromPath: String
    let toPath: String
    var undone: Bool = false
}

// MARK: - Error Entry (new in v1.7)

struct ErrorEntry: Identifiable {
    let id = UUID()
    let date: Date
    let fileName: String
    let reason: String
    let filePath: String
}

// MARK: - File Rule

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

// MARK: - Preferences

struct TidyPreferences: Codable {
    var excludedExtensions: [String] = []
    var minFileSizeKB: Int = 0
    var silentMode: Bool = false
    var soundEnabled: Bool = true
    var movedTodayCount: Int = 0
    var lastResetDate: Date = Date()
    // v1.7 new
    var trashInsteadOfMove: Bool = false        // send to trash instead of organizing
    var protectedModeEnabled: Bool = true       // confirm before moving files > threshold
    var protectedModeSizeMB: Int = 100          // threshold in MB
}

// MARK: - Duplicate Entry (new in v1.7)

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let fileName: String
    let files: [URL]
}

// MARK: - File Organizer

class FileOrganizer: ObservableObject {
    @Published var categories: [FileCategory] = FileCategory.defaults
    @Published var rules: [FileRule] = []
    @Published var schedule: OrganizeSchedule = OrganizeSchedule()
    @Published var preferences: TidyPreferences = TidyPreferences()
    @Published var isWatching: Bool = false
    @Published var moveLog: [MoveEntry] = []
    @Published var errorLog: [ErrorEntry] = []
    @Published var lastRunStats: (moved: Int, skipped: Int, errors: Int) = (0, 0, 0)
    @Published var isRunning: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    @Published var hasCompletedOnboarding: Bool = false
    @Published var duplicates: [DuplicateGroup] = []
    @Published var pendingLargeFiles: [(url: URL, destination: URL)] = []
    @Published var showProtectedAlert: Bool = false

    private let systemExclusions: Set<String> = ["ds_store","localized","tmp","temp","crdownload","part","download"]

    private var watcher: DispatchSourceFileSystemObject?
    private var watcherFD: Int32 = -1
    private var scheduleTimer: Timer?
    private let queue = DispatchQueue(label: "com.tidy.watcher", qos: .utility)
    private let ud = UserDefaults.standard

    var downloadsURL: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    var movedToday: Int {
        resetDailyCounterIfNeeded()
        return preferences.movedTodayCount
    }

    init() {
        loadData()
        migrateCategoriesToLatest()
        requestNotificationPermission()
        if isWatching { startWatching() }
        applySchedule()
    }

    // MARK: - Migration

    func migrateCategoriesToLatest() {
        var changed = false
        for defaultCat in FileCategory.defaults {
            if let idx = categories.firstIndex(where: { $0.folderName == defaultCat.folderName }) {
                let missing = defaultCat.extensions.filter { !categories[idx].extensions.contains($0) }
                if !missing.isEmpty { categories[idx].extensions.append(contentsOf: missing); changed = true }
            } else {
                categories.append(defaultCat); changed = true
            }
        }
        if changed { saveData() }
    }

    // MARK: - Persistence

    func loadData() {
        if let d = ud.data(forKey: "tidy.categories"),
           let v = try? JSONDecoder().decode([FileCategory].self, from: d) { categories = v }
        if let d = ud.data(forKey: "tidy.rules"),
           let v = try? JSONDecoder().decode([FileRule].self, from: d) { rules = v }
        if let d = ud.data(forKey: "tidy.schedule"),
           let v = try? JSONDecoder().decode(OrganizeSchedule.self, from: d) { schedule = v }
        if let d = ud.data(forKey: "tidy.preferences"),
           let v = try? JSONDecoder().decode(TidyPreferences.self, from: d) { preferences = v }
        notificationsEnabled = ud.bool(forKey: "tidy.notifications")
        isWatching = ud.bool(forKey: "tidy.watching")
        hasCompletedOnboarding = ud.bool(forKey: "tidy.onboarding")
    }

    func saveData() {
        if let d = try? JSONEncoder().encode(categories)   { ud.set(d, forKey: "tidy.categories") }
        if let d = try? JSONEncoder().encode(rules)        { ud.set(d, forKey: "tidy.rules") }
        if let d = try? JSONEncoder().encode(schedule)     { ud.set(d, forKey: "tidy.schedule") }
        if let d = try? JSONEncoder().encode(preferences)  { ud.set(d, forKey: "tidy.preferences") }
        ud.set(notificationsEnabled, forKey: "tidy.notifications")
        ud.set(isWatching, forKey: "tidy.watching")
        ud.set(hasCompletedOnboarding, forKey: "tidy.onboarding")
    }

    func exportConfiguration() -> Data? {
        struct Config: Codable {
            let categories: [FileCategory]; let rules: [FileRule]; let preferences: TidyPreferences
        }
        return try? JSONEncoder().encode(Config(categories: categories, rules: rules, preferences: preferences))
    }

    func importConfiguration(from data: Data) -> Bool {
        struct Config: Codable {
            let categories: [FileCategory]; let rules: [FileRule]; let preferences: TidyPreferences
        }
        guard let config = try? JSONDecoder().decode(Config.self, from: data) else { return false }
        categories = config.categories; rules = config.rules; preferences = config.preferences
        saveData(); return true
    }

    // MARK: - Daily counter

    private func resetDailyCounterIfNeeded() {
        if !Calendar.current.isDateInToday(preferences.lastResetDate) {
            preferences.movedTodayCount = 0
            preferences.lastResetDate = Date()
            saveData()
        }
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { self.notificationsEnabled = granted }
        }
    }

    func sendNotification(title: String, body: String) {
        guard notificationsEnabled && !preferences.silentMode else { return }
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }

    private func playSound() {
        guard preferences.soundEnabled else { return }
        NSSound.beep()
    }

    // MARK: - Security: Validate destination

    private func isValidDestination(_ url: URL) -> Bool {
        // Only allow destinations inside Downloads
        let downloadsPath = downloadsURL.standardizedFileURL.path
        let destPath = url.standardizedFileURL.path
        return destPath.hasPrefix(downloadsPath)
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
                self.preferences.movedTodayCount += result.moved
                self.saveData()
                if result.moved > 0 {
                    self.playSound()
                    self.sendNotification(
                        title: "Tidy organizó \(result.moved) archivo\(result.moved == 1 ? "" : "s")",
                        body: result.errors > 0 ? "\(result.errors) archivo(s) no pudieron moverse." : "Tu carpeta Downloads está ordenada ✨"
                    )
                }
            }
        }
    }

    @discardableResult
    func performOrganize(folder: URL) -> (moved: Int, skipped: Int, errors: Int) {
        let fm = FileManager.default
        var moved = 0, skipped = 0, errors = 0

        guard let files = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]) else {
            logError(fileName: folder.lastPathComponent, reason: "No se pudo leer la carpeta", path: folder.path)
            return (0, 0, 1)
        }

        for fileURL in files {
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if isDir.boolValue { continue }

            let ext = fileURL.pathExtension.lowercased()
            let fileName = fileURL.lastPathComponent

            // Skip system files
            guard !ext.isEmpty, !systemExclusions.contains(ext), !fileName.hasPrefix(".") else {
                skipped += 1; continue
            }

            // Skip user-excluded extensions
            if preferences.excludedExtensions.contains(ext) { skipped += 1; continue }

            // Skip files below minimum size
            if preferences.minFileSizeKB > 0 {
                let attrs = (try? fm.attributesOfItem(atPath: fileURL.path))
                let sizeKB = Int((attrs?[.size] as? Int64 ?? 0) / 1024)
                if sizeKB < preferences.minFileSizeKB { skipped += 1; continue }
            }

            // Determine destination
            var destFolder: URL?
            if let ruleFolder = matchingRule(for: fileURL) {
                let dest = folder.appendingPathComponent(ruleFolder)
                destFolder = isValidDestination(dest) ? dest : nil
                if destFolder == nil {
                    logError(fileName: fileName, reason: "Destino de regla fuera de Downloads — bloqueado por seguridad", path: fileURL.path)
                    errors += 1; continue
                }
            } else if let cat = categories.first(where: { $0.extensions.contains(ext) }) {
                destFolder = folder.appendingPathComponent(cat.folderName)
            }

            guard let destination = destFolder else { skipped += 1; continue }

            // Protected mode — check file size
            if preferences.protectedModeEnabled {
                let attrs = (try? fm.attributesOfItem(atPath: fileURL.path))
                let sizeMB = Int((attrs?[.size] as? Int64 ?? 0) / 1_048_576)
                if sizeMB >= preferences.protectedModeSizeMB {
                    DispatchQueue.main.async {
                        self.pendingLargeFiles.append((url: fileURL, destination: destination))
                        self.showProtectedAlert = true
                    }
                    skipped += 1; continue
                }
            }

            // Move or trash
            let result = preferences.trashInsteadOfMove
                ? trashFile(fileURL, fm: fm)
                : moveFile(fileURL, to: destination, fm: fm)

            switch result {
            case .success: moved += 1
            case .failure(let reason):
                logError(fileName: fileName, reason: reason, path: fileURL.path)
                errors += 1
            }
        }
        return (moved, skipped, errors)
    }

    enum MoveResult { case success; case failure(String) }

    private func moveFile(_ fileURL: URL, to destFolder: URL, fm: FileManager) -> MoveResult {
        do {
            if !fm.fileExists(atPath: destFolder.path) {
                try fm.createDirectory(at: destFolder, withIntermediateDirectories: true)
            }
            var dest = destFolder.appendingPathComponent(fileURL.lastPathComponent)
            if fm.fileExists(atPath: dest.path) {
                let n = fileURL.deletingPathExtension().lastPathComponent
                let e = fileURL.pathExtension
                dest = destFolder.appendingPathComponent("\(n)_\(Int.random(in: 1000...9999)).\(e)")
            }
            try fm.moveItem(at: fileURL, to: dest)
            let catName = categories.first(where: { $0.folderName == destFolder.lastPathComponent })?.name
                          ?? destFolder.lastPathComponent
            let entry = MoveEntry(date: Date(), fileName: fileURL.lastPathComponent,
                                  category: catName, fromPath: fileURL.path, toPath: dest.path)
            DispatchQueue.main.async {
                self.moveLog.insert(entry, at: 0)
                if self.moveLog.count > TidyConstants.maxLogEntries {
                    self.moveLog = Array(self.moveLog.prefix(TidyConstants.maxLogEntries))
                }
            }
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func trashFile(_ fileURL: URL, fm: FileManager) -> MoveResult {
        do {
            var trashedURL: NSURL?
            try fm.trashItem(at: fileURL, resultingItemURL: &trashedURL)
            let entry = MoveEntry(date: Date(), fileName: fileURL.lastPathComponent,
                                  category: "Papelera", fromPath: fileURL.path, toPath: trashedURL?.path ?? "Trash")
            DispatchQueue.main.async { self.moveLog.insert(entry, at: 0) }
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    // Confirm pending large files
    func confirmPendingFile(_ item: (url: URL, destination: URL)) {
        let fm = FileManager.default
        _ = moveFile(item.url, to: item.destination, fm: fm)
        pendingLargeFiles.removeAll { $0.url == item.url }
        preferences.movedTodayCount += 1
        recalcStats()
        saveData()
    }

    func dismissPendingFile(_ item: (url: URL, destination: URL)) {
        pendingLargeFiles.removeAll { $0.url == item.url }
    }

    private func logError(fileName: String, reason: String, path: String) {
        let entry = ErrorEntry(date: Date(), fileName: fileName, reason: reason, filePath: path)
        DispatchQueue.main.async {
            self.errorLog.insert(entry, at: 0)
            if self.errorLog.count > 100 { self.errorLog = Array(self.errorLog.prefix(100)) }
        }
    }

    // MARK: - Preview

    func previewOrganize() -> [(fileName: String, category: String, destination: String)] {
        let fm = FileManager.default
        var preview: [(fileName: String, category: String, destination: String)] = []
        guard let files = try? fm.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]) else { return [] }

        for fileURL in files {
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if isDir.boolValue { continue }
            let ext = fileURL.pathExtension.lowercased()
            let fileName = fileURL.lastPathComponent
            guard !ext.isEmpty, !systemExclusions.contains(ext), !fileName.hasPrefix(".") else { continue }
            if preferences.excludedExtensions.contains(ext) { continue }

            if let ruleFolder = matchingRule(for: fileURL) {
                preview.append((fileName: fileName, category: "Regla", destination: ruleFolder))
            } else if let cat = categories.first(where: { $0.extensions.contains(ext) }) {
                preview.append((fileName: fileName, category: cat.name, destination: cat.folderName))
            }
        }
        return preview
    }

    // MARK: - Duplicates (new in v1.7)

    func findDuplicates() {
        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            var nameMap: [String: [URL]] = [:]

            guard let enumerator = fm.enumerator(
                at: self.downloadsURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]) else { return }

            for case let fileURL as URL in enumerator {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
                if isDir.boolValue { continue }
                let name = fileURL.lastPathComponent
                nameMap[name, default: []].append(fileURL)
            }

            let groups = nameMap
                .filter { $0.value.count > 1 }
                .map { DuplicateGroup(fileName: $0.key, files: $0.value) }
                .sorted { $0.fileName < $1.fileName }

            DispatchQueue.main.async { self.duplicates = groups }
        }
    }

    // MARK: - Rules

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

    // MARK: - Undo

    func undo(entry: MoveEntry) {
        let fm = FileManager.default
        let from = URL(fileURLWithPath: entry.toPath)
        let to   = URL(fileURLWithPath: entry.fromPath)
        do {
            let parent = to.deletingLastPathComponent()
            if !fm.fileExists(atPath: parent.path) {
                try fm.createDirectory(at: parent, withIntermediateDirectories: true)
            }
            try fm.moveItem(at: from, to: to)
            if let i = moveLog.firstIndex(where: { $0.id == entry.id }) { moveLog[i].undone = true }
            preferences.movedTodayCount = max(0, preferences.movedTodayCount - 1)
            recalcStats(); saveData()
            sendNotification(title: "Movimiento deshecho", body: "\(entry.fileName) regresó a su lugar")
        } catch {
            logError(fileName: entry.fileName, reason: "No se pudo deshacer: \(error.localizedDescription)", path: entry.fromPath)
        }
    }

    func undoLast() {
        if let last = moveLog.first(where: { !$0.undone }) { undo(entry: last) }
    }

    // MARK: - Schedule

    func applySchedule() {
        scheduleTimer?.invalidate(); scheduleTimer = nil
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
                let result = self.performOrganize(folder: self.downloadsURL)
                if result.moved > 0 {
                    self.preferences.movedTodayCount += result.moved
                    self.playSound()
                    self.recalcStats()
                    self.saveData()
                    self.sendNotification(
                        title: "Tidy organizó \(result.moved) archivo\(result.moved == 1 ? "" : "s")",
                        body: result.errors > 0 ? "\(result.errors) error(es) — revisa el Historial" : "Tu carpeta Downloads está ordenada ✨"
                    )
                }
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

    func clearLog() { moveLog.removeAll(); errorLog.removeAll(); recalcStats() }
}
