import Darwin
import Foundation

struct AgentActivity: Identifiable, Equatable {
    let name: String
    var isWorking: Bool
    var id: String { name }
}

/// Coding agents we recognize, by executable name. Matching is exact and
/// case-sensitive so the Claude desktop app ("Claude") isn't mistaken for
/// Claude Code ("claude").
enum AgentCatalog {
    static let executables: [String: String] = [
        "claude": "Claude Code",
        "codex": "Codex",
        "opencode": "OpenCode",
        "opencode-cli": "OpenCode",
        "hermes": "Hermes",
        "gemini": "Gemini CLI",
        "cursor-agent": "Cursor Agent",
        "amp": "Amp",
        "goose": "Goose",
        "crush": "Crush",
    ]

    /// Agents that run inside an interpreter (node, bun, python), recognized by
    /// what's on their command line.
    static let scripts: [(fragment: String, name: String)] = [
        ("@anthropic-ai/claude-code", "Claude Code"),
        ("@anthropic-ai/claude-agent-sdk", "Claude Code"),
        ("@openai/codex", "Codex"),
        ("opencode-ai", "OpenCode"),
        ("/.hermes/hermes-agent", "Hermes"),
        ("hermes_cli", "Hermes"),
        ("@google/gemini-cli", "Gemini CLI"),
        ("@sourcegraph/amp", "Amp"),
    ]

    /// Apps that drive other agents. Work by an agent they launched is credited
    /// to the app, so Codex running inside T3 Code shows up as T3 Code.
    static let hosts: [(prefix: String, name: String)] = [
        ("T3 Code", "T3 Code"),
    ]

    /// Share of one CPU core an agent must use to count as working.
    static let defaultActivity = 0.015
    /// Agents with busy background services need a higher bar. Hermes keeps a
    /// messaging gateway running that idles at around 2%.
    static let activity: [String: Double] = [
        "Hermes": 0.06,
    ]

    static func match(_ process: ProcessRecord) -> String? {
        if let name = executables[process.name] { return name }
        guard isInterpreter(process.name),
              let arguments = ProcessTable.arguments(of: process.pid) else { return nil }
        return scripts.first { arguments.contains($0.fragment) }?.name
    }

    static func host(of pid: pid_t, in table: [pid_t: ProcessRecord]) -> String? {
        var current = table[pid]?.ppid
        for _ in 0..<32 {
            guard let id = current, id > 1, let process = table[id] else { return nil }
            if let host = hosts.first(where: { process.name.hasPrefix($0.prefix) }) { return host.name }
            current = process.ppid
        }
        return nil
    }

    private static func isInterpreter(_ name: String) -> Bool {
        name == "node" || name == "bun" || name == "deno" || name.hasPrefix("python")
    }
}

/// Decides whether each running agent is actually doing something. An agent
/// sitting at its prompt uses almost no CPU; one that's streaming, editing or
/// running tools (its child processes count too) uses plenty.
final class AgentScanner {
    /// How long an agent stays "working" after its last burst — covers pauses
    /// while it waits on the model.
    var grace: TimeInterval = 180

    /// Share of a core each agent used since the previous scan, for diagnostics.
    private(set) var lastLoad: [String: Double] = [:]
    private var previousCPU: [pid_t: UInt64] = [:]
    private var previousScan: Date?
    private var lastActive: [String: Date] = [:]

    func scan(now: Date = .now) -> [AgentActivity] {
        let table = ProcessTable.snapshot()
        let isFirstScan = previousCPU.isEmpty
        let elapsed = max(previousScan.map { now.timeIntervalSince($0) } ?? 0, 1)
        defer {
            previousCPU = table.mapValues(\.cpu)
            previousScan = now
        }

        var children: [pid_t: [pid_t]] = [:]
        var roots: [String: [pid_t]] = [:]
        for process in table.values {
            children[process.ppid, default: []].append(process.pid)
            if let name = AgentCatalog.match(process) {
                let credited = AgentCatalog.host(of: process.pid, in: table) ?? name
                roots[credited, default: []].append(process.pid)
            }
        }

        return roots.map { name, pids in
            var burned: UInt64 = 0
            var visited = Set<pid_t>()
            var stack = pids
            while let pid = stack.popLast() {
                guard visited.insert(pid).inserted, let process = table[pid] else { continue }
                if let before = previousCPU[pid] {
                    burned += process.cpu > before ? process.cpu - before : 0
                } else if !isFirstScan {
                    burned += process.cpu // started since the last scan
                }
                stack += children[pid] ?? []
            }
            let load = Double(burned) / 1e9 / elapsed
            lastLoad[name] = load
            if load >= AgentCatalog.activity[name, default: AgentCatalog.defaultActivity] { lastActive[name] = now }
            let working = lastActive[name].map { now.timeIntervalSince($0) < grace } ?? false
            return AgentActivity(name: name, isWorking: working)
        }
        .sorted { $0.name < $1.name }
    }
}

struct ProcessRecord {
    let pid: pid_t
    let ppid: pid_t
    let name: String
    /// Total CPU time in nanoseconds.
    let cpu: UInt64
}

enum ProcessTable {
    private static let timebase: (numer: UInt64, denom: UInt64) = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return (UInt64(info.numer), UInt64(info.denom))
    }()

    static func snapshot() -> [pid_t: ProcessRecord] {
        let capacity = Int(proc_listallpids(nil, 0)) + 64
        var pids = [pid_t](repeating: 0, count: capacity)
        let count = Int(proc_listallpids(&pids, Int32(capacity * MemoryLayout<pid_t>.size)))

        var table: [pid_t: ProcessRecord] = [:]
        for pid in pids.prefix(max(0, count)) where pid > 0 {
            var bsd = proc_bsdinfo()
            let bsdSize = Int32(MemoryLayout<proc_bsdinfo>.size)
            guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsd, bsdSize) == bsdSize else { continue }
            let name = withUnsafeBytes(of: bsd.pbi_comm) { bytes in
                String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
            }

            var task = proc_taskinfo()
            let taskSize = Int32(MemoryLayout<proc_taskinfo>.size)
            var cpu: UInt64 = 0
            if proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &task, taskSize) == taskSize {
                // Task times are in Mach absolute units on Apple silicon.
                cpu = (task.pti_total_user + task.pti_total_system) * timebase.numer / timebase.denom
            }
            table[pid] = ProcessRecord(pid: pid, ppid: pid_t(bsd.pbi_ppid), name: name, cpu: cpu)
        }
        return table
    }

    /// Reused across calls; the kernel wants room for the largest possible
    /// argument block.
    private static var argumentBuffer: [UInt8] = {
        var mib: [Int32] = [CTL_KERN, KERN_ARGMAX]
        var argmax: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctl(&mib, 2, &argmax, &size, nil, 0)
        return [UInt8](repeating: 0, count: Int(max(argmax, 4096)))
    }()

    /// The process's arguments joined by spaces. The environment, which follows
    /// them in the same block, is left out so PATH entries can't cause matches.
    static func arguments(of pid: pid_t) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = argumentBuffer.count
        guard sysctl(&mib, 3, &argumentBuffer, &size, nil, 0) == 0, size > 4 else { return nil }
        return argumentBuffer.withUnsafeBufferPointer { buffer in
            // Layout: argc, executable path, NUL padding, argv..., environment...
            let argc = Int(UnsafeRawBufferPointer(buffer).load(as: Int32.self))
            var index = 4
            while index < size, buffer[index] != 0 { index += 1 }
            while index < size, buffer[index] == 0 { index += 1 }
            var arguments: [String] = []
            var start = index
            while index < size, arguments.count < argc {
                if buffer[index] == 0 {
                    arguments.append(String(decoding: buffer[start..<index], as: UTF8.self))
                    start = index + 1
                }
                index += 1
            }
            return arguments.joined(separator: " ")
        }
    }
}
