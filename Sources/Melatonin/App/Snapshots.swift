#if DEBUG
import AppKit
import SwiftUI

/// `Melatonin --snapshot <dir>` renders the menu panel and every notch phase
/// to PNGs, for design review and README images. Debug builds only.
@MainActor
enum Snapshots {
    static func runIfRequested() -> Bool {
        let arguments = CommandLine.arguments
        if arguments.contains("--agents") {
            // Print what the agent scanner sees every 5 s, for tuning thresholds.
            let scanner = AgentScanner()
            for round in 0..<7 {
                let agents = scanner.scan()
                if round > 0 {
                    print(agents.map { "\($0.name): \($0.isWorking ? "working" : "idle") \(Int(((scanner.lastLoad[$0.name] ?? 0) * 1000).rounded()) / 10)% CPU" })
                }
                RunLoop.main.run(until: Date().addingTimeInterval(5))
            }
            return true
        }
        guard let flag = arguments.firstIndex(of: "--snapshot"), flag + 1 < arguments.count else { return false }
        let directory = URL(fileURLWithPath: arguments[flag + 1])
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            print("notch:", screen.notchMetrics, "screen:", screen.frame.size)
        }

        let model = AppModel.shared
        let working = [AgentActivity(name: "Claude Code", isWorking: true)]
        let later = Date().addingTimeInterval(2 * 3600 - 48)

        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "dark" : "light"
            model.stage(awake: false, helper: .missing)
            render(menu(model), scheme: scheme, to: directory.appending(path: "menu-setup-\(suffix).png"))
            model.stage(awake: false, agents: [AgentActivity(name: "Claude Code", isWorking: false)])
            render(menu(model), scheme: scheme, to: directory.appending(path: "menu-off-\(suffix).png"))
            model.stage(awake: true, until: later, agents: working)
            render(menu(model), scheme: scheme, to: directory.appending(path: "menu-on-\(suffix).png"))
        }

        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "dark" : "light"
            model.stage(awake: true, agents: working + [AgentActivity(name: "Hermes", isWorking: true)], auto: true)
            render(menu(model), scheme: scheme, to: directory.appending(path: "menu-auto-\(suffix).png"))
            render(AutoExplainer().frame(width: 288).padding(12).background(.background), scheme: scheme,
                   to: directory.appending(path: "auto-explainer-\(suffix).png"))
        }
        model.stage(awake: false, auto: true)
        render(menu(model), scheme: .light, to: directory.appending(path: "menu-auto-waiting.png"))

        let backups = [
            FallbackNetwork(ssid: "Home 5G", isHotspot: false),
            FallbackNetwork(ssid: "Office", isHotspot: false),
            FallbackNetwork(ssid: "Galaxy Z Fold", isHotspot: true),
        ]
        model.stage(awake: true, until: later, agents: working)
        model.connection.stage(enabled: true, networks: backups, status: .online, lastJoined: "Office")
        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "dark" : "light"
            render(ConnectionSettings().environment(model).background(.background), scheme: scheme,
                   to: directory.appending(path: "connection-\(suffix).png"))
        }
        model.connection.stage(enabled: false, networks: [], status: .off)
        render(ConnectionSettings().environment(model).background(.background), scheme: .light,
               to: directory.appending(path: "connection-empty.png"))
        model.connection.stage(enabled: true, networks: backups, status: .online, lastJoined: "Office")

        let notch = NotchMetrics(notchSize: CGSize(width: 185, height: 32), hasNotch: true)
        let shots: [(String, Bool, () -> Void)] = [
            ("notch-compact", false, { model.stage(awake: true, until: later, agents: working) }),
            ("notch-compact-auto", false, { model.stage(awake: false, agents: working); model.stage(awake: true, agents: working) }),
            ("notch-banner", false, { model.stage(awake: true, banner: .awake) }),
            ("notch-banner-battery", false, { model.stage(awake: false, banner: .stopped(.lowBattery(20))) }),
            ("notch-banner-network", false, { model.stage(awake: true, banner: .joinedNetwork("선웅의 Z Fold8")) }),
            ("notch-expanded-on", true, { model.stage(awake: true, until: later, agents: working) }),
            ("notch-expanded-off", true, { model.stage(awake: false, agents: [AgentActivity(name: "Codex", isWorking: false)]) }),
        ]
        for (name, expanded, stage) in shots {
            stage()
            let state = NotchState()
            state.metrics = notch
            state.isExpanded = expanded
            render(desktop(notch: notch, overlay: NotchView(state: state).environment(model)), scheme: .dark,
                   to: directory.appending(path: "\(name).png"))
        }
        return true
    }

    private static func menu(_ model: AppModel) -> some View {
        MenuPanel()
            .environment(model)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(24)
            .background(Color(white: 0.5))
    }

    /// A fake desktop: wallpaper, menu bar and the hardware notch.
    private static func desktop(notch: NotchMetrics, overlay: some View) -> some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(red: 0.29, green: 0.36, blue: 0.62), Color(red: 0.62, green: 0.45, blue: 0.62)],
                           startPoint: .top, endPoint: .bottom)
            Rectangle().fill(.black.opacity(0.18)).frame(height: notch.notchSize.height)
            HStack {
                Text(verbatim: "  Finder   File   Edit   View").font(.system(size: 13, weight: .medium))
                Spacer()
                Text(verbatim: "Wed 9:41  ").font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(height: notch.notchSize.height)
            UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10)
                .fill(.black)
                .frame(width: notch.notchSize.width, height: notch.notchSize.height)
            overlay
        }
        .frame(width: 760, height: 250)
    }

    private static func render(_ view: some View, scheme: ColorScheme, to url: URL) {
        let direction: LayoutDirection = NSApp.userInterfaceLayoutDirection == .rightToLeft
            || Locale.Language(identifier: Bundle.main.preferredLocalizations.first ?? "en").characterDirection == .rightToLeft
            ? .rightToLeft : .leftToRight
        let host = NSHostingView(rootView: view.environment(\.colorScheme, scheme).environment(\.layoutDirection, direction))
        host.frame.size = host.fittingSize
        let window = NSWindow(contentRect: CGRect(x: -4000, y: -4000, width: host.frame.width, height: host.frame.height),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.contentView = host
        window.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(1.2))

        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
        window.orderOut(nil)
        print("wrote", url.lastPathComponent)
    }
}
#endif
