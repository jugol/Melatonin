import Foundation

/// Installs or removes the root helper with a single administrator prompt.
/// The scripts ship inside the app bundle and are readable in the repo.
enum HelperInstaller {
    enum Failure: LocalizedError {
        case cancelled
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .cancelled: String(localized: "Setup was cancelled.")
            case .failed(let message): message
            }
        }
    }

    static func install() async throws {
        try await runPrivileged(
            script: "install-helper",
            prompt: String(localized: "Melatonin needs your password once to install its helper.")
        )
    }

    static func uninstall() async throws {
        try await runPrivileged(
            script: "uninstall-helper",
            prompt: String(localized: "Melatonin needs your password to remove its helper.")
        )
    }

    private static func runPrivileged(script name: String, prompt: String) async throws {
        guard let script = Bundle.main.path(forResource: name, ofType: "sh") else {
            throw Failure.failed("Missing \(name).sh in the app bundle.")
        }
        let command = "/bin/bash \(shellQuoted(script)) \(shellQuoted(Bundle.main.bundlePath))"
        let source = "do shell script \(appleScriptQuoted(command)) with prompt \(appleScriptQuoted(prompt)) with administrator privileges"

        // osascript runs out of process so the password dialog never blocks our UI.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let errors = Pipe()
        process.standardError = errors
        process.standardOutput = Pipe()

        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
        guard status != 0 else { return }

        let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        if message.contains("-128") { throw Failure.cancelled }
        throw Failure.failed(message.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func shellQuoted(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptQuoted(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
