import Foundation
import Observation

/// A saved Wi-Fi network in the user's preferred order.
struct FallbackNetwork: Codable, Hashable, Identifiable {
    var ssid: String
    /// A phone's hotspot; only changes the icon.
    var isHotspot: Bool

    var id: String { ssid }

    /// Phone hotspots usually carry the phone's name.
    static func looksLikeHotspot(_ ssid: String) -> Bool {
        let hints = ["iphone", "ipad", "galaxy", "fold", "flip", "pixel", "hotspot", "androidap", "redmi", "xiaomi", "oneplus", "핫스팟"]
        let lowered = ssid.lowercased()
        return hints.contains { lowered.contains($0) }
    }
}

/// Keeps the Mac online while it's awake. If the internet stops answering, it
/// joins the first network on the user's list that's in range, and if none of
/// them works, restarts Wi-Fi so macOS rejoins whatever saved network it can.
///
/// Joining by name needs Location access (see `WiFiAccess`); restarting Wi-Fi
/// works without it.
@MainActor
@Observable
final class ConnectionGuard {
    enum Status: Equatable {
        case off
        /// Enabled, but only watches while the Mac is being kept awake.
        case standby
        case online
        case offline
        case switching(String)
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
    var networks: [FallbackNetwork] {
        didSet { defaults.set(try? JSONEncoder().encode(networks), forKey: Keys.networks) }
    }
    private(set) var savedNetworks: [String] = []
    private(set) var status = Status.off
    private(set) var lastRecovery: Recovery?
    let wifi = WiFiAccess()

    /// Called after Wi-Fi comes back (true) or stays down (false).
    @ObservationIgnored var onRecovery: ((Bool) -> Void)?
    @ObservationIgnored var restartWiFi: (() async throws -> Void)?

    private var defaults: UserDefaults { Preferences.store }
    @ObservationIgnored private var watching = false
    @ObservationIgnored private var watchTask: Task<Void, Never>?

    private enum Keys {
        static let enabled = "connection.enabled"
        static let networks = "connection.networks"
    }

    init() {
        let defaults = Preferences.store
        isEnabled = defaults.bool(forKey: Keys.enabled)
        networks = defaults.data(forKey: Keys.networks)
            .flatMap { try? JSONDecoder().decode([FallbackNetwork].self, from: $0) } ?? []
        refresh()
    }

    var summary: String {
        switch status {
        case .off: String(localized: "Reconnects Wi-Fi if the internet drops")
        case .standby: String(localized: "Ready · watches while awake")
        case .online: wifi.current.map { String(localized: "Online via \($0)") } ?? String(localized: "Online")
        case .offline: String(localized: "Internet is down")
        case .switching(let ssid): String(localized: "Joining \(ssid)…")
        case .restartingWiFi: String(localized: "Restarting Wi-Fi…")
        case .exhausted: String(localized: "Couldn’t reconnect")
        }
    }

    var isRecovering: Bool {
        switch status {
        case .switching, .restartingWiFi: true
        default: false
        }
    }

    var availableToAdd: [String] {
        let chosen = Set(networks.map(\.ssid))
        return savedNetworks.filter { !chosen.contains($0) }
    }

    func reloadSavedNetworks() {
        Task { savedNetworks = await Task.detached { SavedNetworks.list() }.value }
    }

    func add(_ ssid: String) {
        guard !networks.contains(where: { $0.ssid == ssid }) else { return }
        networks.append(FallbackNetwork(ssid: ssid, isHotspot: FallbackNetwork.looksLikeHotspot(ssid)))
    }

    func remove(_ network: FallbackNetwork) {
        networks.removeAll { $0.ssid == network.ssid }
        WiFiPasswords.delete(network.ssid)
    }

    func move(from source: IndexSet, to destination: Int) {
        networks.move(fromOffsets: source, toOffset: destination)
    }

    func toggleHotspot(_ network: FallbackNetwork) {
        guard let index = networks.firstIndex(of: network) else { return }
        networks[index].isHotspot.toggle()
    }

    /// Joins one network right away. The user is here, so if the network needs
    /// its password, macOS may ask them to allow it.
    func connectNow(_ network: FallbackNetwork) {
        guard !isRecovering else { return }
        let previous = status
        status = .switching(network.ssid)
        Task {
            ActivityLog.write("Connect now: \(network.ssid) (asked by you)")
            if await tryJoin(network.ssid, mayAsk: true) {
                onRecovery?(true)
            } else {
                status = previous
            }
            await wifi.refresh()
        }
    }

    /// Networks on the list whose passwords Melatonin can't use yet.
    var notReady: [FallbackNetwork] {
        networks.filter { !wifi.ready.contains($0.ssid) }
    }

    func checkReady() {
        wifi.checkReady(networks.map(\.ssid))
    }

    /// Lets Melatonin use the passwords macOS saved, one dialog per network.
    func allowSavedPasswords() {
        Task {
            for network in notReady {
                guard await wifi.importPassword(for: network.ssid) else { break }
            }
        }
    }

    /// Restarts Wi-Fi right away, to check that the fallback works on this Mac.
    func testNow() {
        guard !isRecovering else { return }
        let previous = status
        Task {
            ActivityLog.write("Stay online: Wi-Fi restart requested by you")
            if await restart() == false, status == .exhausted, !watching {
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
            if isRecovering {
                failures = 0
                try? await Task.sleep(for: .seconds(5))
                continue
            }
            let online = await Reachability.isOnline()
            guard !Task.isCancelled else { return }
            if isRecovering { continue }
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

    /// Tries the user's networks in order, then falls back to restarting Wi-Fi.
    /// Returns whether the internet came back.
    private func recover() async -> Bool {
        if wifi.access == .granted, !networks.isEmpty {
            await wifi.refresh()
            let inRange = networks.filter { wifi.nearby[$0.ssid] != nil }
            ActivityLog.write("Stay online: in range from your list: \(inRange.map(\.ssid).joined(separator: ", ").ifEmpty("none"))")
            for network in inRange {
                guard !Task.isCancelled else { return false }
                if await tryJoin(network.ssid) {
                    onRecovery?(true)
                    return true
                }
            }
        } else if !networks.isEmpty {
            ActivityLog.write("Stay online: Location access is off, so your list can't be used; restarting Wi-Fi instead")
        }
        guard !Task.isCancelled else { return false }
        return await restart()
    }

    /// Joins `ssid`, then waits for real internet.
    private func tryJoin(_ ssid: String, mayAsk: Bool = false) async -> Bool {
        status = .switching(ssid)
        let started = Date()
        do {
            try await wifi.join(ssid, userPresent: mayAsk)
        } catch let error as WiFiAccess.WiFiError where error.needsPassword && mayAsk {
            ActivityLog.write("Stay online: \(ssid) needs its saved password; asking you to allow it")
            guard await wifi.importPassword(for: ssid) else { return false }
            do {
                try await wifi.join(ssid, userPresent: true)
            } catch {
                ActivityLog.write("Stay online: couldn’t join \(ssid): \(error.localizedDescription)")
                return false
            }
        } catch {
            ActivityLog.write("Stay online: couldn’t join \(ssid): \(error.localizedDescription)")
            return false
        }
        guard await waitUntilOnline(seconds: 20) else {
            ActivityLog.write("Stay online: joined \(ssid) but the internet isn’t reachable")
            return false
        }
        let seconds = Int(Date().timeIntervalSince(started))
        ActivityLog.write("Stay online: online via \(ssid) after \(seconds) s")
        lastRecovery = Recovery(date: .now, seconds: seconds)
        status = .online
        return true
    }

    /// Restarts Wi-Fi and waits for real internet. Returns whether it came back.
    @discardableResult
    private func restart() async -> Bool {
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
        await wifi.refresh()
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

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

enum SavedNetworks {
    /// The Wi-Fi networks this Mac remembers, in the system's order.
    static func list() -> [String] {
        guard let device = device() else { return [] }
        return networksetup(["-listpreferredwirelessnetworks", device])
            .split(separator: "\n")
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func device() -> String? {
        let lines = networksetup(["-listallhardwareports"]).split(separator: "\n")
        guard let port = lines.firstIndex(where: { $0.hasSuffix(": Wi-Fi") }), port + 1 < lines.count else { return nil }
        return lines[port + 1].split(separator: ":").last?.trimmingCharacters(in: .whitespaces)
    }

    private static func networksetup(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}

enum Reachability {
    /// Apple's captive-portal check: a real answer means real internet, not
    /// just a Wi-Fi association or a hotel login page. Each check uses a fresh
    /// session so a connection left over from the previous network can't fail it.
    static func isOnline() async -> Bool {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 6
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let url = URL(string: "https://www.apple.com/library/test/success.html")!
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
        return String(decoding: data, as: UTF8.self).contains("Success")
    }
}

#if DEBUG
extension ConnectionGuard {
    /// Freezes the guard in a given state for `--snapshot` renders.
    func stage(enabled: Bool, status: Status, lastRecovery: Recovery? = nil, networks: [FallbackNetwork]) {
        isEnabled = enabled
        self.networks = networks
        self.lastRecovery = lastRecovery
        stop(status)
    }
}
#endif
