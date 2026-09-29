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

        Window("Stay online", id: ConnectionSettings.windowID) {
            ConnectionSettings().environment(AppModel.shared)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.shutdown()
    }
}
