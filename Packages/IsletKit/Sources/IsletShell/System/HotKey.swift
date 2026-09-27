import Carbon.HIToolbox
import Foundation

/// A system-wide keyboard shortcut, through the Carbon hot key API: it needs no permission and never sees other
/// keystrokes.
@MainActor
final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    /// Control, Option and Command with I: free in macOS and in common apps.
    static let defaultShortcut = (key: UInt32(kVK_ANSI_I), modifiers: UInt32(controlKey | optionKey | cmdKey))

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func register() {
        guard reference == nil else { return }
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &type, context, &handler)
        let id = EventHotKeyID(signature: OSType(0x49534C54), id: 1) // "ISLT"
        RegisterEventHotKey(Self.defaultShortcut.key, Self.defaultShortcut.modifiers, id, GetApplicationEventTarget(), 0, &reference)
    }

    func unregister() {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
        reference = nil
        handler = nil
    }
}
