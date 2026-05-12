import SwiftUI

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var organizer = FileOrganizer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(organizer)
                .frame(minWidth: 720, minHeight: 520)
                .sheet(isPresented: Binding(
                    get: { !organizer.hasCompletedOnboarding },
                    set: { if !$0 { organizer.hasCompletedOnboarding = true; organizer.saveData() } }
                )) {
                    OnboardingView()
                        .environmentObject(organizer)
                }
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

        MenuBarExtra {
            MenuBarView()
                .environmentObject(organizer)
        } label: {
            MenuBarLabel()
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
