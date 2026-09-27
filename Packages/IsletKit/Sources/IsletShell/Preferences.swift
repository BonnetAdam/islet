import Foundation
import IsletCore

/// How fast the island moves.
enum MotionStyle: String, CaseIterable, Identifiable {
    case snappy, standard, relaxed
    var id: String { rawValue }
    /// Multiplies every perceptual duration.
    var factor: Double {
        switch self {
        case .snappy: 0.78
        case .standard: 1
        case .relaxed: 1.3
        }
    }
}

/// User settings, stored in the standard defaults.
enum Preferences {
    private static var defaults: UserDefaults { .standard }

    /// Posted after any setting changes.
    static let didChange = Notification.Name("IsletPreferencesDidChange")

    private static func bool(_ key: String, default fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    /// Replace the volume and brightness displays of macOS with Islet's. Needs the Accessibility permission.
    static var replacesSystemHUD: Bool {
        get { bool("replacesSystemHUD", default: true) }
        set { defaults.set(newValue, forKey: "replacesSystemHUD"); changed() }
    }

    static var showsMicrophoneAndCamera: Bool {
        get { bool("showsMicrophoneAndCamera", default: true) }
        set { defaults.set(newValue, forKey: "showsMicrophoneAndCamera"); changed() }
    }

    static var showsBattery: Bool {
        get { bool("showsBattery", default: true) }
        set { defaults.set(newValue, forKey: "showsBattery"); changed() }
    }

    static var showsAudioDevices: Bool {
        get { bool("showsAudioDevices", default: true) }
        set { defaults.set(newValue, forKey: "showsAudioDevices"); changed() }
    }

    /// Keep recent text copies, in memory only.
    static var keepsClipboardHistory: Bool {
        get { bool("keepsClipboardHistory", default: true) }
        set { defaults.set(newValue, forKey: "keepsClipboardHistory"); changed() }
    }

    /// Keep the island, and widgets under the clock, on the Lock Screen. Experimental: it relies on private APIs.
    static var showsOnLockScreen: Bool {
        get { bool("showsOnLockScreen", default: false) }
        set { defaults.set(newValue, forKey: "showsOnLockScreen"); changed() }
    }

    static var opensOnHover: Bool {
        get { bool("opensOnHover", default: true) }
        set { defaults.set(newValue, forKey: "opensOnHover"); changed() }
    }

    private static func changed() {
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    // MARK: Island

    static var islandSize: IslandSize {
        get { IslandSize(rawValue: defaults.string(forKey: "islandSize") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "islandSize"); changed() }
    }

    static var motionStyle: MotionStyle {
        get { MotionStyle(rawValue: defaults.string(forKey: "motionStyle") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "motionStyle"); changed() }
    }

    /// Seconds the pointer rests on the notch before the island opens by itself.
    static var hoverDelay: Double {
        get { defaults.object(forKey: "hoverDelay") == nil ? 0.18 : min(max(defaults.double(forKey: "hoverDelay"), 0), 1.5) }
        set { defaults.set(newValue, forKey: "hoverDelay"); changed() }
    }

    /// The optional pages shown in the island, in order. Home and Live are always there.
    static var enabledPages: [String] {
        get { defaults.stringArray(forKey: "enabledPages") ?? ["shelf", "clipboard", "tools", "system"] }
        set { defaults.set(newValue, forKey: "enabledPages"); changed() }
    }

    /// Keep the island out of screenshots and screen recordings.
    static var hiddenFromScreenCapture: Bool {
        get { bool("hiddenFromScreenCapture", default: false) }
        set { defaults.set(newValue, forKey: "hiddenFromScreenCapture"); changed() }
    }

    static var showsMediaActivity: Bool {
        get { bool("showsMediaActivity", default: true) }
        set { defaults.set(newValue, forKey: "showsMediaActivity"); changed() }
    }

    static var showsTrackChanges: Bool {
        get { bool("showsTrackChanges", default: true) }
        set { defaults.set(newValue, forKey: "showsTrackChanges"); changed() }
    }

    static var showsAgents: Bool {
        get { bool("showsAgents", default: true) }
        set { defaults.set(newValue, forKey: "showsAgents"); changed() }
    }

    /// A card with the battery when headphones connect.
    static var showsDeviceCard: Bool {
        get { bool("showsDeviceCard", default: true) }
        set { defaults.set(newValue, forKey: "showsDeviceCard"); changed() }
    }

    /// Step aside while an app is in full screen; brief displays such as the volume still show.
    static var hidesInFullScreen: Bool {
        get { bool("hidesInFullScreen", default: true) }
        set { defaults.set(newValue, forKey: "hidesInFullScreen"); changed() }
    }

    /// "notch": the screen with the notch, or the built-in one; "main": the screen with the active window.
    static var displayChoice: String {
        get { defaults.string(forKey: "displayChoice") ?? "notch" }
        set { defaults.set(newValue, forKey: "displayChoice"); changed() }
    }

    /// Follow downloads in progress. Off by default: reading Downloads asks for a permission.
    static var watchesDownloads: Bool {
        get { bool("watchesDownloads", default: false) }
        set { defaults.set(newValue, forKey: "watchesDownloads"); changed() }
    }

    /// Control, Option, Command and I open and close the island.
    static var hotKeyEnabled: Bool {
        get { bool("hotKeyEnabled", default: true) }
        set { defaults.set(newValue, forKey: "hotKeyEnabled"); changed() }
    }
}
