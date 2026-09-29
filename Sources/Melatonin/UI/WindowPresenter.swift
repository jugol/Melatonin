import AppKit
import SwiftUI

/// Opens Melatonin's windows from anywhere: the notch, the menu, or a relaunch.
/// The menu bar icon can end up hidden behind the notch when the menu bar is
/// crowded, so the full panel must be reachable without it.
@MainActor
final class WindowPresenter {
    static let shared = WindowPresenter()
    private var windows: [String: NSWindow] = [:]

    /// The same controls as the menu bar panel, in a regular window.
    func showPanel() {
        show(id: "panel", title: "Melatonin") {
            MenuPanel()
        }
    }

    func showConnection() {
        show(id: "connection", title: String(localized: "Stay online")) {
            ConnectionSettings()
        }
    }

    private func show<Content: View>(id: String, title: String, @ViewBuilder content: () -> Content) {
        if let window = windows[id] {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        // Size the window once, then let the content scroll. Resizing the window
        // to follow the content crashes AppKit while the lamp animates: every
        // frame asks for another constraints pass until AppKit gives up.
        let view = content()
        let measure = NSHostingView(rootView: view.environment(AppModel.shared))
        let size = CGSize(width: measure.fittingSize.width, height: min(measure.fittingSize.height, 760))
        let hosting = NSHostingView(rootView: ScrollView { view }
            .scrollBounceBehavior(.basedOnSize)
            .environment(AppModel.shared))
        hosting.sizingOptions = []

        let window = NSWindow(contentRect: CGRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.contentView = hosting
        window.contentMinSize = CGSize(width: size.width, height: 240)
        window.contentMaxSize = CGSize(width: size.width, height: 2000)
        window.title = title
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        windows[id] = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
