import Foundation

/// A plain-text record of what Melatonin did and why, in
/// ~/Library/Logs/Melatonin/Melatonin.log. When something goes wrong with the
/// lid closed, this is how you find out what happened.
enum ActivityLog {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Logs/Melatonin/Melatonin.log")

    /// Off for debug snapshot renders, which stage fake states.
    nonisolated(unsafe) static var isEnabled = true

    private static let queue = DispatchQueue(label: "io.github.jugol.Melatonin.log")
    private static let limit = 2_000_000

    private static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func write(_ message: String) {
        guard isEnabled else { return }
        let line = "\(timestamp.string(from: .now))  \(message)\n"
        queue.async {
            let manager = FileManager.default
            try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let size = (try? manager.attributesOfItem(atPath: url.path))?[.size] as? Int, size > limit {
                let previous = url.appendingPathExtension("1")
                try? manager.removeItem(at: previous)
                try? manager.moveItem(at: url, to: previous)
            }
            guard let handle = try? FileHandle(forWritingTo: url) else {
                try? Data(line.utf8).write(to: url)
                return
            }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: Data(line.utf8))
        }
    }
}
