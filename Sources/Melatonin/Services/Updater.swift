import AppKit
import Observation
import Sparkle

/// Finds and installs new versions with Sparkle, from the appcast on the
/// project site.
@MainActor
@Observable
final class Updater: NSObject {
    static let shared = Updater()

    /// The version waiting to be installed, when Sparkle left it to us to
    /// mention.
    private(set) var available: String?

    var checksAutomatically = false {
        didSet { controller?.updater.automaticallyChecksForUpdates = checksAutomatically }
    }

    @ObservationIgnored private var controller: SPUStandardUpdaterController?

    func start() {
        let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        self.controller = controller
        checksAutomatically = controller.updater.automaticallyChecksForUpdates
    }

    func checkForUpdates() {
        NSApp.activate()
        controller?.checkForUpdates(nil)
    }

    #if DEBUG
    func stage(available: String?) {
        self.available = available
    }
    #endif
}

extension Updater: SPUUpdaterDelegate {
    /// `updateFeedURL` in the app's defaults points at another appcast, for
    /// trying an update before it's published.
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        UserDefaults.standard.string(forKey: "updateFeedURL")
    }

    nonisolated func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        MainActor.assumeIsolated {
            ActivityLog.write("Relaunching to finish an update")
            AppModel.shared.prepareForRelaunch()
        }
    }
}

extension Updater: SPUStandardUserDriverDelegate {
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    /// A window from a menu bar app opens behind whatever the user is doing,
    /// so updates found on schedule wait as a badge in the panel, and Sparkle's
    /// window opens when the user asks for it.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        false
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState
    ) {
        let version = update.displayVersionString
        MainActor.assumeIsolated {
            ActivityLog.write("Update available: \(version), \(handleShowingUpdate ? "showing Sparkle’s window" : "showing a badge")")
            if !handleShowingUpdate { available = version }
        }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        MainActor.assumeIsolated { available = nil }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        MainActor.assumeIsolated { available = nil }
    }
}
