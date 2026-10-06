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

/// Some agents spend most of a task waiting on the model or on a quiet tool and
/// barely use CPU, but they write down every step of a turn, and whether the
/// turn is over.
enum AgentLogs {
    private static let home = FileManager.default.homeDirectoryForCurrentUser

    /// How long an open turn counts as work after its last write: a slow model
    /// reply, or a command that runs quietly (Claude Code allows 10 minutes).
    /// Past that, the agent is probably waiting on a permission prompt.
    static let openTurnLimit: TimeInterval = 10 * 60

    /// When each agent last logged real work; now, while a turn is still open.
    static func lastActivity(now: Date = .now) -> [String: Date] {
        seen.removeAll()
        var result: [String: Date] = [:]
        result["Hermes"] = hermes()
        result["Codex"] = latestWork(in: codexSessions(now: now), now: now, turn: codexTurn)
        result["Claude Code"] = latestWork(in: claudeTranscripts(now: now), now: now, turn: claudeTurn)
        turns = turns.filter { seen.contains($0.key) }
        return result.compactMapValues { $0 }
    }

    // MARK: Turns

    private enum Turn: Equatable {
        case open
        case finished(Date)
    }

    /// Classified turns by file, kept until the file changes.
    private static var turns: [URL: (modified: Date, turn: Turn?)] = [:]
    private static var seen: Set<URL> = []

    private static func latestWork(in files: [(url: URL, modified: Date)], now: Date, turn classify: (URL) -> Turn?) -> Date? {
        var latest: Date?
        for file in files where now.timeIntervalSince(file.modified) < openTurnLimit {
            seen.insert(file.url)
            let turn: Turn?
            if let cached = turns[file.url], cached.modified == file.modified {
                turn = cached.turn
            } else {
                turn = classify(file.url)
                turns[file.url] = (file.modified, turn)
            }
            let date: Date
            switch turn {
            case .open: date = now
            case .finished(let end): date = end
            case nil: date = file.modified
            }
            latest = max(latest ?? date, date)
        }
        return latest
    }

    // MARK: Claude Code

    /// Claude Code appends every message to ~/.claude/projects/<project>/<session>.jsonl,
    /// and a subagent's to <session>/subagents/, which may be the only file
    /// written during a long subagent run.
    private static func claudeTranscripts(now: Date) -> [(url: URL, modified: Date)] {
        var result: [(url: URL, modified: Date)] = []
        for project in folders(in: home.appending(path: ".claude/projects")) {
            for session in transcripts(in: project) {
                result.append(session)
                guard now.timeIntervalSince(session.modified) < 6 * 3600 else { continue }
                let subagents = project
                    .appending(path: session.url.deletingPathExtension().lastPathComponent)
                    .appending(path: "subagents")
                result += transcripts(in: subagents)
            }
        }
        return result
    }

    /// Tools that wait on the user, not on work.
    private static let questions: Set<String> = ["AskUserQuestion", "ExitPlanMode"]

    private static func claudeTurn(_ url: URL) -> Turn? {
        for line in lastLines(of: url) {
            guard let entry = object(line), let type = entry["type"] as? String,
                  type == "user" || type == "assistant", entry["isMeta"] as? Bool != true else { continue }
            let end = date(entry["timestamp"]) ?? .distantPast
            let message = entry["message"] as? [String: Any]
            let blocks = message?["content"] as? [[String: Any]] ?? []
            if type == "assistant" {
                if entry["isApiErrorMessage"] as? Bool == true { return .finished(end) }
                switch message?["stop_reason"] as? String {
                case nil:
                    return .open // still streaming
                case "tool_use":
                    let tools = blocks.compactMap { $0["name"] as? String }
                    return tools.contains(where: questions.contains) ? .finished(end) : .open
                default:
                    return .finished(end)
                }
            }
            let text = message?["content"] as? String
                ?? blocks.compactMap { $0["text"] as? String }.joined(separator: " ")
            if text.hasPrefix("[Request interrupted by user") || text.contains("<local-command-stdout>") {
                return .finished(end)
            }
            return .open // a prompt or a tool result, waiting on the model
        }
        return nil
    }

    // MARK: Codex

    /// Codex appends to a session file under ~/.codex/sessions/YYYY/MM/DD for
    /// every event in a turn.
    private static func codexSessions(now: Date) -> [(url: URL, modified: Date)] {
        let base = home.appending(path: ".codex/sessions")
        return [now, now.addingTimeInterval(-86_400)].flatMap { day in
            let parts = Calendar.current.dateComponents([.year, .month, .day], from: day)
            return transcripts(in: base.appending(path: String(format: "%04d/%02d/%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)))
        }
    }

    private static func codexTurn(_ url: URL) -> Turn? {
        for line in lastLines(of: url) {
            guard let entry = object(line), entry["type"] as? String == "event_msg",
                  let event = (entry["payload"] as? [String: Any])?["type"] as? String else { continue }
            switch event {
            case "task_started": return .open
            case "task_complete", "turn_aborted": return .finished(date(entry["timestamp"]) ?? .distantPast)
            default: continue
            }
        }
        return nil
    }

    // MARK: Hermes

    private static let hermesTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    /// Hermes logs from `agent.*` loggers only while a conversation turn runs
    /// (model calls, tool runs); when idle it only logs MCP polling.
    private static func hermes() -> Date? {
        let url = home.appending(path: ".hermes/logs/agent.log")
        guard let modified = modificationDate(of: url), Date().timeIntervalSince(modified) < 600 else { return nil }
        // "2026-09-29 15:45:00,453 INFO [20260924_165417_6716c5] agent.tool_executor: …"
        let pattern = #"^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d+ [A-Z]+ (\[[^\]]+\] )?agent\."#
        for line in lastLines(of: url, limit: 32_768)
        where line.range(of: pattern, options: .regularExpression) != nil {
            return hermesTimestamp.date(from: String(line.prefix(19)))
        }
        return nil
    }

    // MARK: Files

    private static func folders(in url: URL) -> [URL] {
        let entries = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        return entries.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
    }

    private static func transcripts(in folder: URL) -> [(url: URL, modified: Date)] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files.compactMap { file in
            guard file.pathExtension == "jsonl", let modified = modificationDate(of: file) else { return nil }
            return (file, modified)
        }
    }

    private static func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    /// The file's last complete lines, newest first. Transcript lines can be
    /// large (a whole tool result), so up to `limit` bytes are read.
    private static func lastLines(of url: URL, limit: UInt64 = 512 * 1024) -> [Substring] {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? handle.close() }
        guard let size = try? handle.seekToEnd() else { return [] }
        let start = size > limit ? size - limit : 0
        try? handle.seek(toOffset: start)
        let tail = String(decoding: handle.readDataToEndOfFile(), as: UTF8.self)
        var lines = tail.split(separator: "\n")
        if start > 0, !lines.isEmpty { lines.removeFirst() } // cut off mid-line
        return lines.reversed()
    }

    private static func object(_ line: Substring) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any]
    }

    private static let isoTimestamp: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func date(_ value: Any?) -> Date? {
        (value as? String).flatMap(isoTimestamp.date(from:))
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

        let logged = AgentLogs.lastActivity()
        for (name, date) in logged where date > (lastActive[name] ?? .distantPast) {
            lastActive[name] = date
        }

        var activities: [AgentActivity] = roots.map { name, pids in
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
            return AgentActivity(name: name, isWorking: isRecent(lastActive[name], now: now))
        }
        // An agent whose log shows work counts even if its process wasn't recognized.
        for name in logged.keys where roots[name] == nil && isRecent(lastActive[name], now: now) {
            activities.append(AgentActivity(name: name, isWorking: true))
        }
        return activities.sorted { $0.name < $1.name }
    }

    private func isRecent(_ date: Date?, now: Date) -> Bool {
        date.map { now.timeIntervalSince($0) < grace } ?? false
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
