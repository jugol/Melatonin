import SwiftUI

@main
struct MelatoninApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuPanel().environment(AppModel.shared)
        } label: {
            MenuBarLabel(model: AppModel.shared)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if Snapshots.runIfRequested() { exit(0) }
        #endif
        AppModel.shared.start()
        NotchController.shared.start(model: AppModel.shared)
        Updater.shared.start()
    }

    /// Opening Melatonin again (Spotlight, Finder, Dock) shows its panel in a
    /// window, for when the menu bar icon is hidden behind the notch.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowPresenter.shared.showPanel()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.shutdown()
    }
}
