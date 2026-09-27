import AppKit

// A write to a helper that has just exited must not kill the app.
signal(SIGPIPE, SIG_IGN)

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
