import Foundation

/// Recent clipboard text, newest first. Kept in memory only.
public struct ClipboardHistory: Sendable, Equatable {
    public struct Entry: Sendable, Equatable, Identifiable {
        public var id: UUID
        public var text: String
        public var copied: Date
        public var sourceApp: String?

        public init(id: UUID = UUID(), text: String, copied: Date, sourceApp: String? = nil) {
            self.id = id
            self.text = text
            self.copied = copied
            self.sourceApp = sourceApp
        }
    }

    public private(set) var entries: [Entry] = []
    public var capacity: Int

    public init(capacity: Int = 24) {
        self.capacity = capacity
    }

    /// Adds a copy. Blank text is ignored; copying something again moves it to the top instead of repeating it.
    public mutating func add(_ text: String, at date: Date, from app: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Very long copies are kept whole but compared and stored at a sane size.
        let stored = text.count > 20_000 ? String(text.prefix(20_000)) : text
        entries.removeAll { $0.text == stored }
        entries.insert(Entry(text: stored, copied: date, sourceApp: app), at: 0)
        if entries.count > capacity { entries.removeLast(entries.count - capacity) }
    }

    public mutating func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
    }

    public mutating func clear() {
        entries.removeAll()
    }
}

/// A countdown that knows where it is at any moment without ticking.
public struct Countdown: Sendable, Equatable {
    public var total: TimeInterval
    public var ends: Date?
    /// Set while paused: what was left when it stopped.
    public var pausedRemaining: TimeInterval?

    public init(total: TimeInterval, starting date: Date) {
        self.total = max(total, 1)
        ends = date.addingTimeInterval(self.total)
    }

    public func remaining(at date: Date) -> TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let ends else { return 0 }
        return max(ends.timeIntervalSince(date), 0)
    }

    /// 1 when it starts, 0 when it rings.
    public func fraction(at date: Date) -> Double {
        remaining(at: date) / total
    }

    public var isPaused: Bool { pausedRemaining != nil }

    public func isFinished(at date: Date) -> Bool {
        !isPaused && remaining(at: date) <= 0
    }

    public mutating func pause(at date: Date) {
        guard !isPaused else { return }
        pausedRemaining = remaining(at: date)
        ends = nil
    }

    public mutating func resume(at date: Date) {
        guard let left = pausedRemaining else { return }
        ends = date.addingTimeInterval(left)
        pausedRemaining = nil
    }

    /// "4:05", or "1:02:03" past an hour; rounds up so it reads 0:00 only when it rings.
    public static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        let hours = total / 3600, minutes = total / 60 % 60, rest = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }
}

public enum MeetingLink {
    private static let hosts = ["meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "whereby.com", "meet.jit.si", "webex.com", "facetime.apple.com"]

    /// The first video call link in an event's URL, location or notes.
    public static func find(in texts: [String?]) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        for text in texts.compactMap({ $0 }) {
            let range = NSRange(text.startIndex..., in: text)
            for match in detector?.matches(in: text, range: range) ?? [] {
                guard let url = match.url, let host = url.host?.lowercased() else { continue }
                if hosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return url }
            }
        }
        return nil
    }
}
