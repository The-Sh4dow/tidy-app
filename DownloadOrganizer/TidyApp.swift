import SwiftUI

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var organizer = FileOrganizer()

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(organizer)
                .frame(minWidth: 680, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appSettings) {
                Button("Organizar ahora") { organizer.organizeNow() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button("Deshacer último movimiento") { organizer.undoLast() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }

        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView()
                .environmentObject(organizer)
        } label: {
            MenuBarIcon()
                .environmentObject(organizer)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
