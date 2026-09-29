import Foundation
import Observation

/// A saved Wi-Fi network the user wants Melatonin to fall back to.
struct FallbackNetwork: Codable, Hashable, Identifiable {
    var ssid: String
    /// A phone's hotspot. Shown with a phone icon; order in the list is still
    /// what decides priority.
    var isHotspot: Bool

    var id: String { ssid }

    /// Phone hotspots usually carry the phone's name.
    static func looksLikeHotspot(_ ssid: String) -> Bool {
        let hints = ["iphone", "ipad", "galaxy", "fold", "flip", "pixel", "hotspot", "androidap", "redmi", "xiaomi", "oneplus", "핫스팟"]
        let lowered = ssid.lowercased()
        return hints.contains { lowered.contains($0) }
    }
}

/// Keeps the Mac online while it's awake: if the internet stops answering,
/// joins the next network on the user's list until one works.
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
        case exhausted
    }

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Keys.enabled)
            refresh()
        }
    }
    var networks: [FallbackNetwork] {
        didSet { save() }
    }
    private(set) var savedNetworks: [String] = []
    private(set) var status = Status.off
    private(set) var lastChecked: Date?
    /// The network Melatonin itself joined most recently.
    private(set) var lastJoined: String?

    /// Called with the SSID after a successful switch, or nil when every
    /// network on the list failed.
    @ObservationIgnored var onSwitch: ((String?) -> Void)?
    @ObservationIgnored var join: ((String) async throws -> Void)?

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var watching = false
    @ObservationIgnored private var watchTask: Task<Void, Never>?

    private enum Keys {
        static let enabled = "connection.enabled"
        static let networks = "connection.networks"
    }

    init() {
        isEnabled = defaults.bool(forKey: Keys.enabled)
        networks = defaults.data(forKey: Keys.networks)
            .flatMap { try? JSONDecoder().decode([FallbackNetwork].self, from: $0) } ?? []
        refresh()
    }

    var summary: String {
        switch status {
        case .off: return String(localized: "Switch networks when the internet drops")
        case _ where networks.isEmpty: return String(localized: "Add networks to fall back to")
        case .standby: return String(localized: "Ready · watches while awake")
        case .online:
            if let lastJoined { return String(localized: "Online via \(lastJoined)") }
            return String(localized: "Online")
        case .offline: return String(localized: "Internet is down")
        case .switching(let ssid): return String(localized: "Joining \(ssid)…")
        case .exhausted: return String(localized: "Couldn’t reconnect")
        }
    }

    var availableToAdd: [String] {
        let chosen = Set(networks.map(\.ssid))
        return savedNetworks.filter { !chosen.contains($0) }
    }

    func add(_ ssid: String) {
        guard !networks.contains(where: { $0.ssid == ssid }) else { return }
        networks.append(FallbackNetwork(ssid: ssid, isHotspot: FallbackNetwork.looksLikeHotspot(ssid)))
    }

    func remove(_ network: FallbackNetwork) {
        networks.removeAll { $0.ssid == network.ssid }
    }

    func move(from source: IndexSet, to destination: Int) {
        networks.move(fromOffsets: source, toOffset: destination)
    }

    func toggleHotspot(_ network: FallbackNetwork) {
        guard let index = networks.firstIndex(of: network) else { return }
        networks[index].isHotspot.toggle()
    }

    func reloadSavedNetworks() {
        Task {
            savedNetworks = await Task.detached { WiFiNetworks.saved() }.value
        }
    }

    /// Melatonin only watches the connection while it's keeping the Mac awake.
    func setWatching(_ watching: Bool) {
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
        watchTask = Task { [weak self] in await self?.watch() }
    }

    private func stop(_ status: Status) {
        watchTask?.cancel()
        watchTask = nil
        self.status = status
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(networks), forKey: Keys.networks)
    }

    private func watch() async {
        var failures = 0
        while !Task.isCancelled {
            let online = await Reachability.isOnline()
            guard !Task.isCancelled else { return }
            lastChecked = .now
            if online {
                failures = 0
                status = .online
            } else {
                failures += 1
                status = .offline
                // Two misses in a row (~30 s) before touching anything.
                if failures >= 2 {
                    await failOver()
                    failures = 0
                }
            }
            try? await Task.sleep(for: .seconds(15))
        }
    }

    private func failOver() async {
        guard let join else { return }
        for network in networks {
            guard !Task.isCancelled else { return }
            status = .switching(network.ssid)
            do {
                try await join(network.ssid)
            } catch {
                continue
            }
            // Give DHCP and DNS a moment.
            for _ in 0..<6 {
                try? await Task.sleep(for: .seconds(3))
                if await Reachability.isOnline() {
                    lastJoined = network.ssid
                    lastChecked = .now
                    status = .online
                    onSwitch?(network.ssid)
                    return
                }
            }
        }
        guard !Task.isCancelled else { return }
        status = .exhausted
        onSwitch?(nil)
        // Back off before cycling through the list again.
        try? await Task.sleep(for: .seconds(90))
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

enum WiFiNetworks {
    /// The Wi-Fi networks this Mac remembers, in the system's order.
    static func saved() -> [String] {
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

#if DEBUG
extension ConnectionGuard {
    /// Freezes the guard in a given state for `--snapshot` renders.
    func stage(enabled: Bool, networks: [FallbackNetwork], status: Status, lastJoined: String? = nil) {
        isEnabled = enabled
        self.networks = networks
        self.lastJoined = lastJoined
        stop(status)
    }
}
#endif
