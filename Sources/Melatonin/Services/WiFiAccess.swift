import AppKit
import CoreLocation
import CoreWLAN
import Observation
import Security

/// Seeing and joining Wi-Fi networks by name. Since macOS 14 that needs
/// Location access: without it, every network name comes back hidden, which is
/// why joining by name from the root helper always failed.
@MainActor
@Observable
final class WiFiAccess {
    enum Access: Equatable {
        case notAsked, denied, granted
    }

    struct WiFiError: LocalizedError {
        let message: String
        /// The network is in range but refused to join without its password.
        var needsPassword = false
        var errorDescription: String? { message }
    }

    private(set) var access: Access
    /// Networks seen in the last scan, with their signal strength (RSSI).
    private(set) var nearby: [String: Int] = [:]
    private(set) var current: String?
    private(set) var isScanning = false
    /// Networks whose saved password Melatonin can use without asking.
    private(set) var ready: Set<String> = []
    /// Set while macOS's keychain dialog is up, so the window can explain it.
    private(set) var askingPasswordFor: String?

    @ObservationIgnored private let location = LocationAuthorization()
    @ObservationIgnored private var isStaged = false

    init() {
        access = Self.access(for: location.status)
        location.onChange = { [weak self] status in
            guard let self, !self.isStaged else { return }
            let access = Self.access(for: status)
            if access != self.access { ActivityLog.write("Location access: \(access)") }
            self.access = access
            if access == .granted { Task { await self.refresh() } }
        }
    }

    func requestAccess() {
        ActivityLog.write("Location access requested (currently \(access))")
        NSApp.activate()
        location.request()
    }

    func openPrivacySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
    }

    /// Scans for nearby networks and reads the current one.
    func refresh() async {
        guard access == .granted, !isScanning, !isStaged else { return }
        isScanning = true
        let result = await Task.detached { Self.scan() }.value
        isScanning = false
        nearby = result.networks
        current = result.current
        if let error = result.error { ActivityLog.write("Wi-Fi scan failed: \(error)") }
    }

    /// Copies the password macOS saved for `ssid`. macOS asks the user to allow
    /// this once per network, so only call it while they're at the Mac.
    func checkReady(_ ssids: [String]) {
        guard !isStaged else { return }
        ready = Set(ssids.filter(WiFiPasswords.exists))
    }

    func importPassword(for ssid: String) async -> Bool {
        askingPasswordFor = ssid
        let (password, status) = await Task.detached { WiFiPasswords.fromSystem(ssid) }.value
        askingPasswordFor = nil
        guard let password else {
            ActivityLog.write("Wi-Fi: couldn’t read the saved password for \(ssid) (OSStatus \(status): \(SecCopyErrorMessageString(status, nil) as String? ?? "?"))")
            return false
        }
        WiFiPasswords.save(password, for: ssid)
        ready.insert(ssid)
        ActivityLog.write("Wi-Fi: password for \(ssid) is ready")
        return true
    }

    /// Joins `ssid` with the password Melatonin keeps for it. `userPresent`
    /// is false while the lid may be closed: then a keychain prompt nobody
    /// can answer is given up on after a few seconds instead of stalling.
    func join(_ ssid: String, userPresent: Bool = false) async throws {
        guard access == .granted else {
            throw WiFiError(message: "Location access is off, so network names are hidden.")
        }
        // Known networks may join with the credentials macOS already has; only
        // fall back to a password when that's refused.
        let password = await WiFiPasswords.load(ssid, timeout: userPresent ? 120 : 5)
        if let failure = await Task.detached(operation: { Self.associate(ssid, password: password) }).value {
            throw WiFiError(message: failure.message + (password == nil ? " (tried without a password)" : ""),
                            needsPassword: password == nil && !failure.notInRange)
        }
        current = ssid
    }

    private static func access(for status: CLAuthorizationStatus) -> Access {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: .granted
        case .denied, .restricted: .denied
        default: .notAsked
        }
    }

    nonisolated private static func scan() -> (networks: [String: Int], current: String?, error: String?) {
        guard let interface = CWWiFiClient.shared().interface() else { return ([:], nil, "No Wi-Fi interface") }
        do {
            var networks: [String: Int] = [:]
            for network in try interface.scanForNetworks(withName: nil) {
                guard let ssid = network.ssid else { continue }
                networks[ssid] = max(networks[ssid] ?? -200, network.rssiValue)
            }
            return (networks, interface.ssid(), nil)
        } catch {
            return ([:], interface.ssid(), error.localizedDescription)
        }
    }

    struct JoinFailure: Sendable {
        let message: String
        var notInRange = false
    }

    /// Returns nil once associated.
    nonisolated private static func associate(_ ssid: String, password: String?) -> JoinFailure? {
        guard let interface = CWWiFiClient.shared().interface() else { return JoinFailure(message: "No Wi-Fi interface.") }
        do {
            let candidates = try interface.scanForNetworks(withName: ssid)
            guard let network = candidates.max(by: { $0.rssiValue < $1.rssiValue }) else {
                return JoinFailure(message: "“\(ssid)” isn’t in range.", notInRange: true)
            }
            try interface.associate(to: network, password: password)
            return nil
        } catch {
            let error = error as NSError
            return JoinFailure(message: "\(error.localizedDescription) [\(error.domain) \(error.code)]")
        }
    }
}

#if DEBUG
extension WiFiAccess {
    /// Fakes a granted scan for `--snapshot` renders.
    func stage(nearby: [String: Int], current: String?, ready: Set<String>) {
        isStaged = true
        access = .granted
        self.nearby = nearby
        self.current = current
        self.ready = ready
    }
}
#endif

/// Wraps CLLocationManager, whose delegate must be an NSObject.
private final class LocationAuthorization: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onChange: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var status: CLAuthorizationStatus { manager.authorizationStatus }

    func request() {
        manager.requestWhenInUseAuthorization()
        // On macOS the prompt sometimes only appears once location is actually
        // requested. Stop as soon as there's an answer; the location itself is
        // never read.
        manager.startUpdatingLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { self.manager.stopUpdatingLocation() }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status != .notDetermined { manager.stopUpdatingLocation() }
        DispatchQueue.main.async { self.onChange?(status) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
    }
}

/// Wi-Fi passwords Melatonin may use, kept in the login keychain.
///
/// macOS ties each item to the exact build that saved it unless the app is
/// signed with a Team ID, so a new build may be asked for the keychain password
/// on its first read, whatever the query says. Reads that could prompt
/// therefore only happen when joining, and with a timeout.
enum WiFiPasswords {
    private static let service = "io.github.jugol.Melatonin.wifi"
    /// Off for `--snapshot` renders, which must never touch the keychain.
    nonisolated(unsafe) static var isEnabled = true

    private static func query(_ ssid: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: ssid]
    }

    /// Whether a password is stored, without reading it (so never prompts).
    static func exists(_ ssid: String) -> Bool {
        guard isEnabled else { return false }
        var request = query(ssid)
        request[kSecReturnAttributes as String] = true
        return SecItemCopyMatching(request as CFDictionary, nil) == errSecSuccess
    }

    /// The password, or nil if there's none or reading it took longer than
    /// `timeout` (a keychain prompt is waiting).
    static func load(_ ssid: String, timeout: TimeInterval) async -> String? {
        guard isEnabled else { return nil }
        return await withCheckedContinuation { continuation in
            let once = Once()
            DispatchQueue.global(qos: .userInitiated).async {
                let password = load(ssid)
                if once.claim() { continuation.resume(returning: password) }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard once.claim() else { return }
                ActivityLog.write("Wi-Fi: the keychain didn’t answer for \(ssid) within \(Int(timeout)) s")
                continuation.resume(returning: nil)
            }
        }
    }

    private static func load(_ ssid: String) -> String? {
        var request = query(ssid)
        request[kSecReturnData as String] = true
        request[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        var result: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ password: String, for ssid: String) {
        guard isEnabled else { return }
        SecItemDelete(query(ssid) as CFDictionary)
        var item = query(ssid)
        item[kSecValueData as String] = Data(password.utf8)
        item[kSecAttrLabel as String] = "Melatonin Wi-Fi: \(ssid)"
        SecItemAdd(item as CFDictionary, nil)
    }

    static func delete(_ ssid: String) {
        SecItemDelete(query(ssid) as CFDictionary)
    }

    /// The password macOS saved when the user joined this network, and the
    /// status of the last lookup. Reading it shows macOS's own approval dialog.
    static func fromSystem(_ ssid: String) -> (String?, OSStatus) {
        guard isEnabled else { return (nil, errSecItemNotFound) }
        var status = errSecItemNotFound
        for domain in [CWKeychainDomain.system, .user] {
            var password: NSString?
            status = CWKeychainFindWiFiPassword(domain, Data(ssid.utf8), &password)
            if status == errSecSuccess, let password { return (password as String, status) }
        }
        return (nil, status)
    }
}

/// Lets exactly one of several racing callbacks through.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func claim() -> Bool {
        lock.withLock {
            defer { done = true }
            return !done
        }
    }
}
