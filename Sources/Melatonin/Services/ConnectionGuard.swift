import Foundation
import Observation

/// Keeps the Mac online while it's awake. If the internet stops answering, it
/// restarts Wi-Fi so macOS scans and rejoins the best saved network in range,
/// such as a phone's hotspot.
///
/// Joining a specific network by name isn't an option: since macOS 14,
/// processes without Location access can't see network names, so
/// `networksetup -setairportnetwork` fails with "Could not find network" even
/// for a hotspot sitting next to the Mac.
@MainActor
@Observable
final class ConnectionGuard {
    enum Status: Equatable {
        case off
        /// Enabled, but only watches while the Mac is being kept awake.
        case standby
        case online
        case offline
        case restartingWiFi
        case exhausted
    }

    struct Recovery: Equatable {
        let date: Date
        let seconds: Int
    }

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Keys.enabled)
            refresh()
        }
    }
    private(set) var status = Status.off
    private(set) var lastRecovery: Recovery?

    /// Called after Wi-Fi comes back (true) or stays down (false).
    @ObservationIgnored var onRecovery: ((Bool) -> Void)?
    @ObservationIgnored var restartWiFi: (() async throws -> Void)?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var watching = false
    @ObservationIgnored private var watchTask: Task<Void, Never>?

    private enum Keys {
        static let enabled = "connection.enabled"
    }

    init() {
        isEnabled = defaults.bool(forKey: Keys.enabled)
        refresh()
    }

    var summary: String {
        switch status {
        case .off: String(localized: "Reconnects Wi-Fi if the internet drops")
        case .standby: String(localized: "Ready · watches while awake")
        case .online: String(localized: "Online")
        case .offline: String(localized: "Internet is down")
        case .restartingWiFi: String(localized: "Restarting Wi-Fi…")
        case .exhausted: String(localized: "Couldn’t reconnect")
        }
    }

    var isRecovering: Bool { status == .restartingWiFi }

    /// Restarts Wi-Fi right away, to check that recovery works on this Mac.
    func testNow() {
        guard !isRecovering else { return }
        let previous = status
        Task {
            ActivityLog.write("Stay online: test requested by you")
            if await recover() == false, status == .exhausted, !watching {
                status = previous
            }
        }
    }

    /// Melatonin only watches the connection while it's keeping the Mac awake.
    func setWatching(_ watching: Bool) {
        guard self.watching != watching else { return }
        self.watching = watching
        refresh()
    }

    private func refresh() {
        guard isEnabled else {
            stop(.off)
            return
        }
        guard watching else {
            stop(.standby)
            return
        }
        guard watchTask == nil else { return }
        ActivityLog.write("Stay online: watching the connection")
        watchTask = Task { [weak self] in await self?.watch() }
    }

    private func stop(_ status: Status) {
        if watchTask != nil { ActivityLog.write("Stay online: stopped watching") }
        watchTask?.cancel()
        watchTask = nil
        self.status = status
    }

    private func watch() async {
        var failures = 0
        var failedRecoveries = 0
        while !Task.isCancelled {
            let online = await Reachability.isOnline()
            guard !Task.isCancelled else { return }
            if online {
                if status != .online { ActivityLog.write("Stay online: internet is reachable") }
                failures = 0
                failedRecoveries = 0
                status = .online
            } else {
                failures += 1
                if status != .offline, status != .exhausted { ActivityLog.write("Stay online: internet check failed") }
                if status != .exhausted { status = .offline }
                // Two misses in a row (~20 s) before touching Wi-Fi.
                if failures >= 2 {
                    if await recover() {
                        failedRecoveries = 0
                    } else {
                        failedRecoveries += 1
                        // Back off: 30 s, 60 s, then every 2 minutes.
                        let wait = min(30 * (1 << min(failedRecoveries - 1, 2)), 120)
                        ActivityLog.write("Stay online: still offline; trying again in \(wait) s")
                        try? await Task.sleep(for: .seconds(wait))
                    }
                    failures = 0
                }
            }
            try? await Task.sleep(for: .seconds(10))
        }
    }

    /// Restarts Wi-Fi and waits for real internet. Returns whether it came back.
    @discardableResult
    private func recover() async -> Bool {
        guard let restartWiFi else { return false }
        status = .restartingWiFi
        ActivityLog.write("Stay online: restarting Wi-Fi so macOS rejoins a saved network")
        let started = Date()
        do {
            try await restartWiFi()
        } catch {
            ActivityLog.write("Stay online: restarting Wi-Fi failed: \(error.localizedDescription)")
            status = .exhausted
            onRecovery?(false)
            return false
        }
        guard await waitUntilOnline(seconds: 40) else {
            ActivityLog.write("Stay online: no saved network with internet came back within 40 s")
            status = .exhausted
            onRecovery?(false)
            return false
        }
        let seconds = Int(Date().timeIntervalSince(started))
        ActivityLog.write("Stay online: back online after \(seconds) s")
        lastRecovery = Recovery(date: .now, seconds: seconds)
        status = .online
        onRecovery?(true)
        return true
    }

    /// Gives association, DHCP and DNS a moment to settle.
    private func waitUntilOnline(seconds: Int) async -> Bool {
        for _ in 0..<(seconds / 2) {
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return false }
            if await Reachability.isOnline() { return true }
        }
        return false
    }
}

enum Reachability {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 6
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    /// Apple's captive-portal check: a real answer means real internet, not
    /// just a Wi-Fi association or a hotel login page.
    static func isOnline() async -> Bool {
        let url = URL(string: "https://www.apple.com/library/test/success.html")!
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
        return String(decoding: data, as: UTF8.self).contains("Success")
    }
}

#if DEBUG
extension ConnectionGuard {
    /// Freezes the guard in a given state for `--snapshot` renders.
    func stage(enabled: Bool, status: Status, lastRecovery: Recovery? = nil) {
        isEnabled = enabled
        self.lastRecovery = lastRecovery
        stop(status)
    }
}
#endif
