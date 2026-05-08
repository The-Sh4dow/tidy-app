import SwiftUI

@main
struct DownloadOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var organizer = FileOrganizer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(organizer)
                .frame(minWidth: 600, minHeight: 480)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
