import CoreGraphics
import Foundation

/// Decides whether an app covers the notch's screen in full screen, from the on-screen window list.
public enum FullScreen {
    public struct Window: Equatable, Sendable {
        public var layer: Int
        public var bounds: CGRect
        public var ownerPID: Int32

        public init(layer: Int, bounds: CGRect, ownerPID: Int32) {
            self.layer = layer
            self.bounds = bounds
            self.ownerPID = ownerPID
        }
    }

    /// True when the frontmost app has a normal window exactly covering the screen, menu bar included: that is a
    /// full-screen Space or a presentation, where the island should step aside.
    public static func isActive(windows: [Window], screen: CGRect, frontmostPID: Int32?) -> Bool {
        guard let frontmostPID else { return false }
        return windows.contains { window in
            window.layer == 0 && window.ownerPID == frontmostPID
                && abs(window.bounds.width - screen.width) < 1 && abs(window.bounds.height - screen.height) < 1
                && abs(window.bounds.minX - screen.minX) < 1
        }
    }
}

/// Follows downloads in progress from the names in a folder: browsers write `.download`, `.crdownload` or `.part`
/// files, then rename them when they finish.
public struct DownloadTracker: Sendable, Equatable {
    public enum Event: Equatable, Sendable {
        case started(String)
        case finished(String)
        case cancelled(String)
    }

    public static let partialExtensions = ["download", "crdownload", "part", "partial"]
    private(set) public var inProgress: Set<String> = []

    public init() {}

    /// The final name of a partial file: "Report.pdf.download" gives "Report.pdf".
    public static func finalName(of partial: String) -> String? {
        let url = URL(fileURLWithPath: partial)
        guard partialExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        return url.deletingPathExtension().lastPathComponent
    }

    /// Compares a new listing of the folder with the downloads seen so far.
    public mutating func update(listing: Set<String>) -> [Event] {
        let partial = Set(listing.filter { Self.finalName(of: $0) != nil })
        var events: [Event] = []
        for name in partial.subtracting(inProgress).sorted() {
            events.append(.started(Self.finalName(of: name)!))
        }
        for name in inProgress.subtracting(partial).sorted() {
            let final = Self.finalName(of: name)!
            events.append(listing.contains(final) ? .finished(final) : .cancelled(final))
        }
        inProgress = partial
        return events
    }
}

/// Battery levels an accessory reports, from 0 to 100, missing when unknown.
public struct AccessoryBattery: Equatable, Sendable {
    public var left: Int?
    public var right: Int?
    public var caseLevel: Int?
    public var single: Int?

    public init(left: Int? = nil, right: Int? = nil, caseLevel: Int? = nil, single: Int? = nil) {
        self.left = left
        self.right = right
        self.caseLevel = caseLevel
        self.single = single
    }

    /// Accessories report 0 for a part they cannot see; that is unknown, not empty.
    public static func level(_ raw: Int?) -> Int? {
        guard let raw, raw > 0, raw <= 100 else { return nil }
        return raw
    }

    public var isEmpty: Bool { left == nil && right == nil && caseLevel == nil && single == nil }

    /// The lowest earbud, for a single figure in the wing.
    public var summary: Int? {
        [left, right].compactMap { $0 }.min() ?? single
    }
}
