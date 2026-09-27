import Foundation

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
}
