import Foundation
import MelatoninShared

struct HelperError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Talks to the root helper over XPC. Holding this connection open is how the
/// helper knows we're alive: if the app dies, it restores sleep on its own.
@MainActor
final class HelperClient {
    private var connection: NSXPCConnection?

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: HelperConstants.launchdPlistPath)
    }

    func version() async -> String? {
        await withCheckedContinuation { continuation in
            let once = ResumeOnce(continuation)
            let proxy = remote { _ in once.resume(nil) }
            proxy?.version { once.resume($0) }
        }
    }

    func setSleepDisabled(_ disabled: Bool) async throws {
        try await call { proxy, reply in proxy.setSleepDisabled(disabled, reply: reply) }
    }

    func restartWiFi() async throws {
        try await call(timeout: 40) { proxy, reply in proxy.restartWiFi(reply: reply) }
    }

    /// Calls the helper, giving up after `timeout` seconds so a stuck request
    /// can't stall whoever is waiting on it.
    private func call(
        timeout: TimeInterval = 20,
        _ body: (MelatoninHelperProtocol, @escaping (Bool, String?) -> Void) -> Void
    ) async throws {
        let error: String? = await withCheckedContinuation { continuation in
            let once = ResumeOnce(continuation)
            guard let proxy = remote(onError: { once.resume($0.localizedDescription) }) else {
                return once.resume("Couldn’t reach the helper.")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                once.resume("The helper didn’t answer within \(Int(timeout)) s.")
            }
            body(proxy) { ok, message in
                once.resume(ok ? nil : (message ?? "Unknown helper error"))
            }
        }
        if let error { throw HelperError(message: error) }
    }

    /// Used at quit, when there's no time for async work.
    func releaseNow() {
        guard let connection else { return }
        let proxy = connection.synchronousRemoteObjectProxyWithErrorHandler { _ in } as? MelatoninHelperProtocol
        proxy?.setSleepDisabled(false) { _, _ in }
        disconnect()
    }

    func disconnect() {
        connection?.invalidate()
        connection = nil
    }

    private func remote(onError: @escaping (Error) -> Void) -> MelatoninHelperProtocol? {
        let proxy = (connection ?? connect()).remoteObjectProxyWithErrorHandler(onError)
        return proxy as? MelatoninHelperProtocol
    }

    private func connect() -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: MelatoninHelperProtocol.self)
        connection.invalidationHandler = { [weak self, weak connection] in
            Task { @MainActor in
                if self?.connection === connection { self?.connection = nil }
            }
        }
        connection.resume()
        self.connection = connection
        return connection
    }
}

/// XPC can call both the reply and the error handler; resume only once.
private final class ResumeOnce<Value>: @unchecked Sendable {
    private var continuation: CheckedContinuation<Value, Never>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: Value) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: value)
    }
}
