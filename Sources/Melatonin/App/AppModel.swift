import AppKit
import Observation
import ServiceManagement
import MelatoninShared

enum AwakeDuration: Int, CaseIterable, Identifiable {
    case oneHour = 60, twoHours = 120, fourHours = 240, eightHours = 480, indefinitely = 0

    var id: Int { rawValue }
    var interval: TimeInterval? { self == .indefinitely ? nil : TimeInterval(rawValue * 60) }
    var label: String { self == .indefinitely ? "∞" : String(localized: "\(rawValue / 60)h") }
}

enum HelperStatus: Equatable {
    case checking, missing, outdated, unreachable, installing, ready
    case failed(String)

    var needsSetup: Bool {
        switch self {
        case .checking, .ready: false
        default: true
        }
    }
}

enum StopReason: Equatable {
    case lowBattery(Int), overheating, timerEnded
}

/// A short-lived message the notch shows after something changes.
struct Banner: Equatable, Identifiable {
    enum Kind: Equatable {
        case awake, asleep, stopped(StopReason), agentStarted(String), failed
        case joinedNetwork(String), offline
        /// Auto mode just switched on and is waiting for an agent.
        case autoArmed
    }

    let id = UUID()
    let kind: Kind
}

@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    // MARK: Preferences

    private(set) var duration: AwakeDuration {
        didSet { defaults.set(duration.rawValue, forKey: Keys.duration) }
    }
    var autoForAgents: Bool {
        didSet {
            defaults.set(autoForAgents, forKey: Keys.autoForAgents)
            autoPaused = false
            if autoForAgents, workingAgent == nil { show(.autoArmed) }
            reconcile()
        }
    }
    /// Percent at which to give up on battery power; 0 turns the check off.
    var batteryFloor: Int {
        didSet {
            defaults.set(batteryFloor, forKey: Keys.batteryFloor)
            checkSafety()
        }
    }
    var stopWhenHot: Bool {
        didSet {
            defaults.set(stopWhenHot, forKey: Keys.stopWhenHot)
            checkSafety()
        }
    }
    var showInNotch: Bool {
        didSet {
            defaults.set(showInNotch, forKey: Keys.showInNotch)
            NotchController.shared.setVisible(showInNotch)
        }
    }
    /// A language code from `AppLanguage.supported`, or "" to follow macOS.
    var language: String {
        didSet {
            guard language != oldValue else { return }
            AppLanguage.set(language.isEmpty ? nil : language)
            relaunch()
        }
    }
    var opensAtLogin: Bool {
        didSet {
            guard opensAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if opensAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                opensAtLogin = SMAppService.mainApp.status == .enabled
        language = AppLanguage.override ?? ""
            }
        }
    }

    // MARK: State

    private(set) var manualOn = false
    private(set) var manualUntil: Date?
    /// Set when the user turns things off while an agent is working, so auto
    /// mode doesn't immediately flip it back on.
    private(set) var autoPaused = false
    private(set) var agents: [AgentActivity] = []
    private(set) var battery = BatteryStatus.unknown
    private(set) var thermal = ProcessInfo.processInfo.thermalState
    private(set) var helperStatus = HelperStatus.checking
    /// What the helper has confirmed, not what we asked for.
    private(set) var isAwake = false {
        didSet { connection.setWatching(isAwake) }
    }
    private(set) var lastStop: StopReason?
    private(set) var lastError: String?
    private(set) var banner: Banner?

    let connection = ConnectionGuard()

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let helper = HelperClient()
    @ObservationIgnored private let scanner = AgentScanner()
    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var expiryTimer: Timer?
    @ObservationIgnored private var applying: Task<Void, Never>?
    @ObservationIgnored private var requested: Bool?

    private enum Keys {
        static let duration = "duration"
        static let autoForAgents = "autoForAgents"
        static let batteryFloor = "batteryFloor"
        static let stopWhenHot = "stopWhenHot"
        static let showInNotch = "showInNotch"
        /// Set just before a relaunch so keep-awake picks up where it left off.
        static let resumeUntil = "resumeUntil"
    }

    private init() {
        defaults.register(defaults: [
            Keys.duration: AwakeDuration.indefinitely.rawValue,
            Keys.autoForAgents: false,
            Keys.batteryFloor: 20,
            Keys.stopWhenHot: true,
            Keys.showInNotch: true,
        ])
        duration = AwakeDuration(rawValue: defaults.integer(forKey: Keys.duration)) ?? .indefinitely
        autoForAgents = defaults.bool(forKey: Keys.autoForAgents)
        batteryFloor = defaults.integer(forKey: Keys.batteryFloor)
        stopWhenHot = defaults.bool(forKey: Keys.stopWhenHot)
        showInNotch = defaults.bool(forKey: Keys.showInNotch)
        opensAtLogin = SMAppService.mainApp.status == .enabled
        language = AppLanguage.override ?? ""

        connection.join = { [weak self] ssid in
            guard let self, self.helperStatus == .ready else { throw HelperError(message: "The helper isn’t set up.") }
            try await self.helper.joinWiFi(ssid)
        }
        connection.onSwitch = { [weak self] ssid in
            self?.show(ssid.map { .joinedNetwork($0) } ?? .offline)
        }
    }

    // MARK: Derived

    var workingAgent: String? { agents.first(where: \.isWorking)?.name }
    /// Every working agent, as a localized list: "Claude Code and Hermes".
    var workingAgentList: String? {
        let names = agents.filter(\.isWorking).map(\.name)
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }
    var autoEngaged: Bool { autoForAgents && workingAgent != nil && !autoPaused }
    var wantsAwake: Bool { manualOn || autoEngaged }

    var headline: String {
        isAwake ? String(localized: "Awake") : String(localized: "Sleeps when closed")
    }

    var detail: String {
        if isAwake {
            if manualOn, let until = manualUntil {
                let time = until.formatted(date: .omitted, time: .shortened)
                return String(localized: "Until \(time) · lid can close")
            }
            if manualOn { return String(localized: "Until you turn it off · lid can close") }
            if let agents = workingAgentList { return String(localized: "While \(agents) works · lid can close") }
        }
        if helperStatus == .installing { return String(localized: "Setting up…") }
        switch lastStop {
        case .lowBattery(let percent):
            let level = "\(percent)%"
            return String(localized: "Stopped at \(level) battery")
        case .overheating: return String(localized: "Stopped because your Mac got hot")
        case .timerEnded: return String(localized: "Timer ended")
        case nil: break
        }
        if autoPaused { return String(localized: "Auto paused until agents finish") }
        if autoForAgents { return String(localized: "Turns on when an agent starts working") }
        return String(localized: "Tap the moon to stay awake")
    }

    // MARK: Lifecycle

    func start() {
        poll()
        Task {
            await refreshHelperStatus()
            resumeAfterRelaunch()
        }

        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = 2
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.thermal = ProcessInfo.processInfo.thermalState
                self?.checkSafety()
            }
        }
    }

    func shutdown() {
        helper.releaseNow()
    }

    /// Restarts the app, e.g. to apply a new language. Keep-awake resumes on
    /// the other side.
    func relaunch() {
        if manualOn {
            defaults.set(manualUntil?.timeIntervalSince1970 ?? 0, forKey: Keys.resumeUntil)
        }
        let reopen = Process()
        reopen.executableURL = URL(fileURLWithPath: "/bin/sh")
        reopen.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        try? reopen.run()
        NSApp.terminate(nil)
    }

    private func resumeAfterRelaunch() {
        guard let stamp = defaults.object(forKey: Keys.resumeUntil) as? Double else { return }
        defaults.removeObject(forKey: Keys.resumeUntil)
        let until = stamp == 0 ? nil : Date(timeIntervalSince1970: stamp)
        guard helperStatus == .ready, until.map({ $0 > .now }) ?? true else { return }
        manualOn = true
        setExpiry(until)
        reconcile()
    }

    // MARK: Actions

    func toggle() {
        wantsAwake ? turnOff() : turnOn()
    }

    func turnOn() {
        lastStop = nil
        lastError = nil
        autoPaused = false
        manualOn = true
        scheduleExpiry()
        battery = PowerMonitor.battery()
        if let reason = safetyViolation() {
            stop(reason)
            return
        }
        reconcile()
    }

    func turnOff() {
        if autoEngaged { autoPaused = true }
        clearManual()
        reconcile()
    }

    func choose(_ duration: AwakeDuration) {
        self.duration = duration
        if manualOn { scheduleExpiry() }
    }

    func setUpHelper() {
        Task { _ = await installHelper() }
    }

    func uninstallHelper() {
        Task {
            clearManual()
            autoForAgents = false
            helper.disconnect()
            isAwake = false
            requested = nil
            do {
                try await HelperInstaller.uninstall()
                helperStatus = .missing
            } catch HelperInstaller.Failure.cancelled {
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    // MARK: Polling and safety

    private func poll() {
        battery = PowerMonitor.battery()
        thermal = ProcessInfo.processInfo.thermalState
        agents = scanner.scan()
        if workingAgent == nil { autoPaused = false }
        checkSafety()
        reconcile()
    }

    private func safetyViolation() -> StopReason? {
        if batteryFloor > 0, battery.hasBattery, !battery.onPower,
           let percent = battery.percent, percent <= batteryFloor {
            return .lowBattery(percent)
        }
        if stopWhenHot, thermal == .serious || thermal == .critical {
            return .overheating
        }
        return nil
    }

    private func checkSafety() {
        guard wantsAwake, let reason = safetyViolation() else { return }
        stop(reason)
    }

    private func stop(_ reason: StopReason) {
        lastStop = reason
        if autoEngaged { autoPaused = true }
        clearManual()
        show(.stopped(reason))
        reconcile()
    }

    private func clearManual() {
        manualOn = false
        manualUntil = nil
        expiryTimer?.invalidate()
        expiryTimer = nil
    }

    private func scheduleExpiry() {
        setExpiry(duration.interval.map { Date().addingTimeInterval($0) })
    }

    private func setExpiry(_ until: Date?) {
        expiryTimer?.invalidate()
        manualUntil = until
        guard let until else { return }
        let timer = Timer(fire: until, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.manualOn else { return }
                self.lastStop = .timerEnded
                self.clearManual()
                self.show(.stopped(.timerEnded))
                self.reconcile()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        expiryTimer = timer
    }

    // MARK: Applying

    /// Brings the helper in line with `wantsAwake`, one request at a time.
    private func reconcile() {
        let target = wantsAwake
        guard target != requested else { return }
        requested = target
        let previous = applying
        applying = Task { [weak self] in
            await previous?.value
            await self?.apply(target)
        }
    }

    private func apply(_ target: Bool) async {
        guard target != isAwake else { return }
        if target, helperStatus != .ready {
            // Only ask for a password in direct response to the user.
            guard manualOn, await installHelper(), wantsAwake else {
                requested = nil
                clearManual()
                return
            }
        }
        do {
            try await helper.setSleepDisabled(target)
            isAwake = target
            lastError = nil
            if target {
                show(manualOn ? .awake : .agentStarted(workingAgentList ?? "Agent"))
            } else if lastStop == nil {
                show(.asleep)
            }
        } catch {
            requested = nil
            lastError = error.localizedDescription
            if target { clearManual() }
            show(.failed)
            await refreshHelperStatus()
        }
    }

    private func installHelper() async -> Bool {
        helperStatus = .installing
        do {
            try await HelperInstaller.install()
        } catch HelperInstaller.Failure.cancelled {
            await refreshHelperStatus()
            return false
        } catch {
            helperStatus = .failed(error.localizedDescription)
            return false
        }
        // launchd needs a moment before the new helper answers.
        helper.disconnect()
        for _ in 0..<20 {
            if await helper.version() == HelperConstants.version {
                helperStatus = .ready
                return true
            }
            try? await Task.sleep(for: .milliseconds(150))
        }
        helperStatus = .unreachable
        return false
    }

    private func refreshHelperStatus() async {
        guard helper.isInstalled else {
            helperStatus = .missing
            return
        }
        switch await helper.version() {
        case HelperConstants.version: helperStatus = .ready
        case nil: helperStatus = .unreachable
        default: helperStatus = .outdated
        }
    }

    // MARK: Banners

    private func show(_ kind: Banner.Kind) {
        let banner = Banner(kind: kind)
        self.banner = banner
        Task {
            try? await Task.sleep(for: .seconds(2.8))
            if self.banner?.id == banner.id { self.banner = nil }
        }
    }
}

#if DEBUG
extension AppModel {
    /// Freezes the model in a given state for `--snapshot` renders.
    func stage(
        awake: Bool,
        until: Date? = nil,
        banner: Banner.Kind? = nil,
        agents: [AgentActivity] = [],
        helper: HelperStatus = .ready,
        auto: Bool = false,
        battery: BatteryStatus = BatteryStatus(percent: 78, onPower: false, hasBattery: true)
    ) {
        pollTimer?.invalidate()
        isAwake = awake
        manualOn = awake && !auto
        autoForAgents = auto
        autoPaused = false
        manualUntil = until
        self.banner = banner.map { Banner(kind: $0) }
        self.agents = agents
        helperStatus = helper
        self.battery = battery
        lastStop = nil
        lastError = nil
    }
}
#endif
