import Foundation
import MelatoninShared

// Runs as root under launchd. It flips `pmset disablesleep` on request and
// flips it back the moment the app that asked goes away — quit, crash, or
// force-kill — so a Mac is never left unable to sleep by accident.

/// Runs a tool and returns its exit status and combined output. A tool still
/// running after `timeout` seconds is terminated, so nothing can wedge the helper.
func run(_ executable: String, _ arguments: [String], timeout: TimeInterval = 30) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do { try process.run() } catch { return (-1, error.localizedDescription) }
    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
        if process.isRunning { process.terminate() }
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(decoding: data, as: UTF8.self)
    if process.terminationReason == .uncaughtSignal {
        return (-1, "Timed out after \(Int(timeout)) s. \(output)")
    }
    return (process.terminationStatus, output)
}

enum Power {
    private static func pmset(_ arguments: [String]) -> (status: Int32, output: String) {
        run("/usr/bin/pmset", arguments)
    }

    /// Returns an error message, or nil on success.
    static func setSleepDisabled(_ disabled: Bool) -> String? {
        let result = pmset(["-a", "disablesleep", disabled ? "1" : "0"])
        guard result.status != 0 else { return nil }
        let message = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? "pmset exited with \(result.status)" : message
    }

    static var isSleepDisabled: Bool {
        // `pmset -g` lists "SleepDisabled  1" while sleep is disabled.
        pmset(["-g"]).output.split(separator: "\n").contains { line in
            let fields = line.split(whereSeparator: \.isWhitespace)
            return fields.first == "SleepDisabled" && fields.last == "1"
        }
    }
}

enum WiFi {
    private static func networksetup(_ arguments: [String], timeout: TimeInterval = 15) -> (status: Int32, output: String) {
        run("/usr/sbin/networksetup", arguments, timeout: timeout)
    }

    /// The Wi-Fi interface, usually en0.
    static var device: String? {
        let lines = networksetup(["-listallhardwareports"]).output.split(separator: "\n")
        guard let port = lines.firstIndex(where: { $0.hasSuffix(": Wi-Fi") }), port + 1 < lines.count else { return nil }
        return lines[port + 1].split(separator: ":").last?.trimmingCharacters(in: .whitespaces)
    }

    static func savedNetworks(on device: String) -> [String] {
        networksetup(["-listpreferredwirelessnetworks", device]).output
            .split(separator: "\n")
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Joins a network from the user's saved list, using its stored password.
    /// Returns an error message, or nil on success.
    static func join(_ ssid: String) -> String? {
        guard let device else { return "No Wi-Fi interface found." }
        guard savedNetworks(on: device).contains(ssid) else { return "“\(ssid)” isn’t a saved network." }
        // networksetup exits 0 even when joining fails; any output is an error.
        let result = networksetup(["-setairportnetwork", device, ssid], timeout: 25)
        let message = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.status == 0 && message.isEmpty { return nil }
        return message.isEmpty ? "networksetup exited with \(result.status)" : message
    }

    /// Turns Wi-Fi off and on. macOS then scans and joins the best network it
    /// already knows, which works even where joining by name is refused.
    static func restart() -> String? {
        guard let device else { return "No Wi-Fi interface found." }
        let off = networksetup(["-setairportpower", device, "off"])
        Thread.sleep(forTimeInterval: 2)
        let on = networksetup(["-setairportpower", device, "on"])
        let failures = [off, on].filter { $0.status != 0 }.map { $0.output.trimmingCharacters(in: .whitespacesAndNewlines) }
        return failures.isEmpty ? nil : failures.joined(separator: " ")
    }
}

/// Exists while sleep is disabled on our behalf, so a helper that restarts
/// (reboot, crash, reinstall) knows it has something to undo.
enum Marker {
    private static let url = URL(fileURLWithPath: "/Library/Application Support/Melatonin/sleep-disabled")

    static var exists: Bool { FileManager.default.fileExists(atPath: url.path) }

    static func set(_ present: Bool) {
        if present {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: url.path, contents: nil)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

/// One per connected app instance.
final class Session: NSObject, MelatoninHelperProtocol {
    unowned let service: HelperService
    var wantsSleepDisabled = false

    init(service: HelperService) {
        self.service = service
    }

    func version(reply: @escaping (String) -> Void) {
        reply(HelperConstants.version)
    }

    func setSleepDisabled(_ disabled: Bool, reply: @escaping (Bool, String?) -> Void) {
        service.update(self, wantsSleepDisabled: disabled, reply: reply)
    }

    func isSleepDisabled(reply: @escaping (Bool) -> Void) {
        reply(Power.isSleepDisabled)
    }

    // Wi-Fi work can take a while; keep it off the connection's queue so a
    // sleep request never waits behind it.
    func joinWiFi(_ ssid: String, reply: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global().async {
            let error = WiFi.join(ssid)
            reply(error == nil, error)
        }
    }

    func restartWiFi(reply: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global().async {
            let error = WiFi.restart()
            reply(error == nil, error)
        }
    }
}

final class HelperService: NSObject, NSXPCListenerDelegate {
    private let queue = DispatchQueue(label: "\(HelperConstants.label).sessions")
    private var sessions: [ObjectIdentifier: Session] = [:]

    /// Undoes a disable we left behind: after a crash or reboot at launch, and
    /// when launchd stops us (uninstall, update).
    func restoreSleep() {
        queue.sync {
            guard Marker.exists else { return }
            if Power.setSleepDisabled(false) == nil {
                Marker.set(false)
            }
        }
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(HelperConstants.clientRequirement)

        let session = Session(service: self)
        let id = ObjectIdentifier(session)
        connection.exportedInterface = NSXPCInterface(with: MelatoninHelperProtocol.self)
        connection.exportedObject = session
        connection.invalidationHandler = { [weak self] in self?.end(id) }
        queue.sync { sessions[id] = session }
        connection.resume()
        return true
    }

    func update(_ session: Session, wantsSleepDisabled: Bool, reply: @escaping (Bool, String?) -> Void) {
        queue.sync {
            session.wantsSleepDisabled = wantsSleepDisabled
            let error = apply()
            reply(error == nil, error)
        }
    }

    private func end(_ id: ObjectIdentifier) {
        queue.sync {
            guard let session = sessions.removeValue(forKey: id), session.wantsSleepDisabled else { return }
            _ = apply()
        }
    }

    /// Sleep stays disabled while at least one connected app asks for it.
    private func apply() -> String? {
        let disabled = sessions.values.contains { $0.wantsSleepDisabled }
        if let error = Power.setSleepDisabled(disabled) {
            return error
        }
        Marker.set(disabled)
        return nil
    }
}

let service = HelperService()
service.restoreSleep()

signal(SIGTERM, SIG_IGN)
let termination = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
termination.setEventHandler {
    service.restoreSleep()
    exit(0)
}
termination.resume()

let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
listener.delegate = service
listener.resume()
dispatchMain()
