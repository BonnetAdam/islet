import AppKit
import EventKit
import ServiceManagement
import SwiftUI

/// Shown once, on first launch: what Islet is, and the few permissions it can use, each asked only if wanted.
@MainActor
final class WelcomeWindow: NSObject, NSWindowDelegate {
    static let shared = WelcomeWindow()
    private var window: NSWindow?
    private static let key = "hasWelcomed"

    func showIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.key) else { return }
        show()
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: WelcomeView { [weak self] in self?.finish() })
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: Self.key)
        window = nil
    }
}

struct WelcomeView: View {
    let done: () -> Void
    @State private var trusted = MediaKeyTap.isTrusted
    @State private var calendarAllowed = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var cliInstalled = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                IslandPreview()
                    .frame(width: 300, height: 90)
                Text("Welcome to Islet", bundle: .module)
                    .font(.system(size: 26, weight: .bold))
                Text("Rest the pointer on the notch to open the island. Swipe down with two fingers to open it, up to close it.", bundle: .module)
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(.top, 34)
            .padding(.bottom, 22)

            VStack(spacing: 0) {
                Row(symbol: "speaker.wave.2.fill", tint: .blue, title: Text("Volume and brightness keys", bundle: .module),
                    detail: Text("Show Islet’s display instead of the system’s. Needs Accessibility.", bundle: .module)) {
                    if trusted {
                        Granted()
                    } else {
                        Button { MediaKeyTap.requestTrust() } label: { Text("Allow…", bundle: .module) }
                    }
                }
                Divider().padding(.leading, 52)
                Row(symbol: "calendar", tint: .red, title: Text("Agenda", bundle: .module),
                    detail: Text("Your next events beside the clock.", bundle: .module)) {
                    if calendarAllowed {
                        Granted()
                    } else {
                        Button {
                            Task { @MainActor in
                                _ = try? await EKEventStore().requestFullAccessToEvents()
                                calendarAllowed = EKEventStore.authorizationStatus(for: .event) == .fullAccess
                            }
                        } label: { Text("Allow…", bundle: .module) }
                    }
                }
                Divider().padding(.leading, 52)
                Row(symbol: "power", tint: .green, title: Text("Open at login", bundle: .module),
                    detail: Text("Islet stays out of the Dock and the menu bar.", bundle: .module)) {
                    Toggle("", isOn: $launchesAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: launchesAtLogin) {
                            if launchesAtLogin { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                        }
                }
                Divider().padding(.leading, 52)
                Row(symbol: "terminal.fill", tint: .gray, title: Text("The islet command", bundle: .module),
                    detail: Text("Push live activities from scripts, and connect Claude Code.", bundle: .module)) {
                    if cliInstalled {
                        Granted()
                    } else {
                        Button {
                            _ = CommandLineInstaller.install()
                            cliInstalled = FileManager.default.fileExists(atPath: CommandLineInstaller.linkURL.path)
                        } label: { Text("Install", bundle: .module) }
                    }
                }
            }
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.background.secondary))
            .padding(.horizontal, 28)

            Spacer(minLength: 20)
            Button(action: done) {
                Text("Start", bundle: .module)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.05, green: 0.62, blue: 0.52))
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.horizontal, 28)
            .padding(.bottom, 26)
        }
        .frame(width: 520, height: 600)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            trusted = MediaKeyTap.isTrusted
        }
        .onAppear {
            cliInstalled = FileManager.default.fileExists(atPath: CommandLineInstaller.linkURL.path)
        }
    }
}

private struct Row<Accessory: View>: View {
    let symbol: String
    let tint: Color
    let title: Text
    let detail: Text
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint.gradient))
            VStack(alignment: .leading, spacing: 1) {
                title.font(.system(size: 13, weight: .semibold))
                detail.font(.system(size: 11.5)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct Granted: View {
    var body: some View {
        Label { Text("Done", bundle: .module) } icon: { Image(systemName: "checkmark.circle.fill") }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.green)
    }
}

/// The island breathing between its states, drawn with the app's own outline.
private struct IslandPreview: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
            let phase = (sin(context.date.timeIntervalSinceReferenceDate * 1.1) + 1) / 2
            Canvas { canvas, size in
                let width = 120 + 180 * phase, height = 30 + 52 * phase
                let rect = CGRect(x: (size.width - width) / 2, y: 4, width: width, height: height)
                canvas.fill(Path(roundedRect: rect, cornerRadius: 12 + 16 * phase, style: .continuous), with: .color(.black))
                let bar = CGRect(x: size.width / 2 - 40, y: 0, width: 80, height: 3)
                canvas.fill(Path(roundedRect: bar, cornerRadius: 1.5), with: .color(Color(red: 0.31, green: 0.89, blue: 0.76).opacity(0.8)))
            }
        }
    }
}
