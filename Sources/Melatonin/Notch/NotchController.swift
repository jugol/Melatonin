import AppKit
import Observation
import SwiftUI

struct NotchMetrics: Equatable {
    var notchSize: CGSize
    var hasNotch: Bool
}

enum NotchPhase: Equatable {
    /// Nothing drawn; the real notch (or nothing) shows.
    case idle
    /// Awake: small wings on either side of the notch.
    case compact
    /// A brief message after something changes.
    case banner
    /// Hovered: the full control surface.
    case expanded
}

enum NotchLayout {
    static let compactWing: CGFloat = 70
    static let bannerWing: CGFloat = 116
    /// Network names need more room than the stock two-word banners.
    static let wideBannerWing: CGFloat = 156
    static let expandedWidth: CGFloat = 470
    static let expandedBody: CGFloat = 150

    @MainActor
    static func phase(expanded: Bool, model: AppModel) -> NotchPhase {
        if expanded { return .expanded }
        if model.banner != nil { return .banner }
        return model.isAwake ? .compact : .idle
    }

    static func bannerWing(for banner: Banner?) -> CGFloat {
        if case .joinedNetwork = banner?.kind { return wideBannerWing }
        return bannerWing
    }

    static func size(for phase: NotchPhase, metrics: NotchMetrics, banner: Banner?) -> CGSize {
        let notch = metrics.notchSize
        switch phase {
        case .idle: return notch
        case .compact: return CGSize(width: notch.width + 2 * compactWing, height: notch.height)
        case .banner: return CGSize(width: notch.width + 2 * bannerWing(for: banner), height: notch.height)
        case .expanded: return CGSize(width: max(expandedWidth, notch.width + 2 * compactWing), height: notch.height + expandedBody)
        }
    }
}

@MainActor
@Observable
final class NotchState {
    var metrics = NotchMetrics(notchSize: CGSize(width: 190, height: 32), hasNotch: false)
    var isExpanded = false
}

extension NSScreen {
    var notchMetrics: NotchMetrics {
        if safeAreaInsets.top > 0, let left = auxiliaryTopLeftArea, let right = auxiliaryTopRightArea {
            let width = frame.width - left.width - right.width
            return NotchMetrics(notchSize: CGSize(width: width, height: safeAreaInsets.top), hasNotch: true)
        }
        // No notch: hang a pill of the same proportions from the menu bar.
        let menuBar = max(frame.maxY - visibleFrame.maxY, 24)
        return NotchMetrics(notchSize: CGSize(width: 180, height: menuBar), hasNotch: false)
    }
}

/// Owns the transparent panel that sits over the notch. The panel ignores the
/// mouse until the pointer actually rests on the pill, so the menu bar behind
/// it keeps working.
@MainActor
final class NotchController {
    static let shared = NotchController()

    let state = NotchState()
    private weak var model: AppModel?
    private var panel: NotchPanel?
    private var monitors: [Any] = []
    private var pendingExpand: DispatchWorkItem?
    private var pendingCollapse: DispatchWorkItem?
    private static let canvas = CGSize(width: 620, height: 260)

    func start(model: AppModel) {
        self.model = model
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.place() }
        }
        setVisible(model.showInNotch)
    }

    func setVisible(_ visible: Bool) {
        visible ? show() : hide()
    }

    private func show() {
        guard panel == nil, let model else { return }
        let panel = NotchPanel()
        let root = NotchView(state: state).environment(model)
        panel.contentView = FirstMouseHostingView(rootView: root)
        self.panel = panel
        place()
        panel.orderFrontRegardless()

        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        let global = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] _ in
            MainActor.assumeIsolated { self?.trackPointer() }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            MainActor.assumeIsolated { self?.trackPointer() }
            return event
        }
        monitors = [global, local].compactMap { $0 }
    }

    private func hide() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        panel?.orderOut(nil)
        panel = nil
        setExpanded(false)
    }

    private func place() {
        guard let panel,
              // Prefer the built-in display's notch; otherwise the primary display.
              let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.screens.first
        else { return }
        state.metrics = screen.notchMetrics
        let size = Self.canvas
        panel.setFrame(
            CGRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height, width: size.width, height: size.height),
            display: true
        )
    }

    /// The pill's current footprint in screen coordinates.
    private func hotZone() -> CGRect? {
        guard let panel, let model else { return nil }
        let phase = NotchLayout.phase(expanded: state.isExpanded, model: model)
        let size = NotchLayout.size(for: phase, metrics: state.metrics, banner: model.banner)
        let slack: CGFloat = state.isExpanded ? 16 : 3
        let frame = panel.frame
        return CGRect(
            x: frame.midX - size.width / 2 - slack,
            y: frame.maxY - size.height - slack,
            width: size.width + 2 * slack,
            height: size.height + slack + 2
        )
    }

    private func pointerInside() -> Bool {
        hotZone()?.contains(NSEvent.mouseLocation) ?? false
    }

    private func trackPointer() {
        if pointerInside() {
            pendingCollapse?.cancel()
            pendingCollapse = nil
            guard !state.isExpanded, pendingExpand == nil else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.pendingExpand = nil
                if self.pointerInside() { self.setExpanded(true) }
            }
            pendingExpand = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)
        } else {
            pendingExpand?.cancel()
            pendingExpand = nil
            guard state.isExpanded, pendingCollapse == nil else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.pendingCollapse = nil
                if !self.pointerInside() { self.setExpanded(false) }
            }
            pendingCollapse = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    private func setExpanded(_ expanded: Bool) {
        guard state.isExpanded != expanded else { return }
        state.isExpanded = expanded
        panel?.ignoresMouseEvents = !expanded
    }
}

final class NotchPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .mainMenu + 3
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovable = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Let the panel sit over the menu bar and notch instead of being pushed below them.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

/// Buttons in a non-activating panel should respond to the first click.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
