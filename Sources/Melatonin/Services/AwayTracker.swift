import AppKit

/// What happened while nobody was looking at the screen.
struct AwayRecap: Equatable, Identifiable {
    struct Span: Equatable {
        let start: Date
        let end: Date
        var length: TimeInterval { end.timeIntervalSince(start) }
    }

    struct AgentTime: Equatable {
        let name: String
        let seconds: TimeInterval
    }

    let id = UUID()
    let start: Date
    let end: Date
    /// When Melatonin kept the Mac awake.
    let awake: [Span]
    /// When at least one agent was working.
    let working: [Span]
    let agents: [AgentTime]
    let reconnects: [Date]
    let failedReconnects: [Date]
    let stop: StopReason?
    let stopDate: Date?
    let batteryStart: BatteryStatus
    let batteryEnd: BatteryStatus
    let stillAwake: Bool
    let stillWorking: [String]

    var duration: TimeInterval { end.timeIntervalSince(start) }
    var awakeTime: TimeInterval { awake.reduce(0) { $0 + $1.length } }
    var awakeWholeTime: Bool { !awake.isEmpty && duration - awakeTime < 60 }
    var ranOnBattery: Bool {
        batteryStart.hasBattery && (!batteryStart.onPower || !batteryEnd.onPower)
    }
}

/// Notices when the user steps away (screen asleep or locked) and, when they
/// come back, sums up what Melatonin and the agents did in the meantime.
@MainActor
final class AwayTracker {
    /// Shorter absences aren't worth a summary. `recapMinimumSeconds` in the
    /// app's defaults overrides it, for testing.
    static var minimumAway: TimeInterval {
        let custom = UserDefaults.standard.double(forKey: "recapMinimumSeconds")
        return custom > 0 ? custom : 5 * 60
    }

    var onLeave: (() -> Void)?
    var onReturn: ((AwayRecap) -> Void)?

    private var screensAsleep = false
    private var locked = false
    private var session: Session?

    private var awakeNow = false
    private var workingNow: [String] = []
    private var batteryNow = BatteryStatus.unknown

    private struct Session {
        let start: Date
        let batteryStart: BatteryStatus
        var lastSample: Date
        var awakeSince: Date?
        var awake: [AwayRecap.Span] = []
        var workingSince: Date?
        var working: [AwayRecap.Span] = []
        var workingNames: [String]
        var agentSeconds: [String: TimeInterval] = [:]
        var reconnects: [Date] = []
        var failed: [Date] = []
        var stop: StopReason?
        var stopDate: Date?
    }

    func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()
        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.screensAsleep = true }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.screensAsleep = false }
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.locked = true }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.locked = false }
        // Time the Mac spent asleep isn't time an agent spent working.
        workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.record(isAwake: self.awakeNow, working: [], battery: self.batteryNow)
            }
        }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, _ change: @escaping (AwayTracker) -> Void) {
        center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                change(self)
                self.update()
            }
        }
    }

    private func update() {
        let away = screensAsleep || locked
        if away, session == nil {
            leave()
            onLeave?()
        } else if !away, session != nil, let recap = comeBack() {
            // Let the desktop appear before the summary does.
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                self.onReturn?(recap)
            }
        }
    }

    // MARK: Recording

    /// Called on every poll and whenever keep-awake changes.
    func record(isAwake: Bool, working: [String], battery: BatteryStatus, at now: Date = .now) {
        awakeNow = isAwake
        workingNow = working
        batteryNow = battery
        guard var session else { return }
        // Polls come every 10 s; a longer gap means the Mac slept or the app
        // was stalled, and that time isn't counted.
        let elapsed = min(now.timeIntervalSince(session.lastSample), 30)
        for name in session.workingNames { session.agentSeconds[name, default: 0] += elapsed }
        session.lastSample = now
        session.workingNames = working

        if isAwake, session.awakeSince == nil { session.awakeSince = now }
        if !isAwake, let since = session.awakeSince {
            session.awake.append(.init(start: since, end: now))
            session.awakeSince = nil
        }
        if !working.isEmpty, session.workingSince == nil { session.workingSince = now }
        if working.isEmpty, let since = session.workingSince {
            session.working.append(.init(start: since, end: now))
            session.workingSince = nil
        }
        self.session = session
    }

    func noteReconnect(_ recovered: Bool, at now: Date = .now) {
        if recovered {
            session?.reconnects.append(now)
        } else {
            session?.failed.append(now)
        }
    }

    func noteStop(_ reason: StopReason, at now: Date = .now) {
        session?.stop = reason
        session?.stopDate = now
    }

    // MARK: Sessions

    func leave(at now: Date = .now) {
        ActivityLog.write("Away: screen \(locked ? "locked" : "asleep")")
        session = Session(
            start: now,
            batteryStart: batteryNow,
            lastSample: now,
            awakeSince: awakeNow ? now : nil,
            workingSince: workingNow.isEmpty ? nil : now,
            workingNames: workingNow
        )
    }

    /// Ends the absence. Returns a recap if it was long enough and anything
    /// happened worth telling.
    func comeBack(at now: Date = .now) -> AwayRecap? {
        record(isAwake: awakeNow, working: workingNow, battery: batteryNow, at: now)
        guard var session else { return nil }
        self.session = nil
        if let since = session.awakeSince { session.awake.append(.init(start: since, end: now)) }
        if let since = session.workingSince { session.working.append(.init(start: since, end: now)) }

        let recap = AwayRecap(
            start: session.start,
            end: now,
            awake: session.awake.filter { $0.length >= 1 },
            working: session.working.filter { $0.length >= 1 },
            agents: session.agentSeconds
                .filter { $0.value >= 30 }
                .map { AwayRecap.AgentTime(name: $0.key, seconds: $0.value) }
                .sorted { $0.seconds > $1.seconds },
            reconnects: session.reconnects,
            failedReconnects: session.failed,
            stop: session.stop,
            stopDate: session.stopDate,
            batteryStart: session.batteryStart,
            batteryEnd: batteryNow,
            stillAwake: awakeNow,
            stillWorking: workingNow
        )
        let minutes = Int(recap.duration / 60)
        guard recap.duration >= Self.minimumAway, !recap.awake.isEmpty || !recap.agents.isEmpty else {
            ActivityLog.write("Back after \(minutes) min, nothing to report")
            return nil
        }
        let agents = recap.agents.map { "\($0.name) \(Int($0.seconds / 60)) min" }.joined(separator: ", ")
        ActivityLog.write("Back after \(minutes) min: awake \(Int(recap.awakeTime / 60)) min, agents [\(agents)], reconnects \(recap.reconnects.count), failed \(recap.failedReconnects.count)")
        return recap
    }
}
