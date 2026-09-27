import AppKit
import EventKit
import ServiceManagement
import IsletCore
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
            .tint(Color(red: 0.93, green: 0.36, blue: 0.24))
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

/// The island breathing between its closed and open shapes, with the app's own outline. A Core Animation loop: the
/// render server plays it, so the window costs nothing while it waits.
private struct IslandPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let canvas = CGSize(width: 300, height: 90)
        let notch = NotchMetrics(width: 110, height: 24, centerX: 150, isHardware: true)
        let layout = IslandLayout(notch: notch)
        let path = { (state: IslandState, wings: CGFloat) -> CGPath in
            var shape = layout.shape(for: state, wings: wings)
            if state == .expanded {
                shape.width = 260
                shape.height = 84
            }
            var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: canvas.height)
            let outline = IslandPath.make(shape, centerX: canvas.width / 2)
            return outline.copy(using: &flip) ?? outline
        }
        let island = CAShapeLayer()
        island.frame = CGRect(origin: .zero, size: canvas)
        island.fillColor = NSColor.black.cgColor
        island.path = path(.collapsed, 34)
        let breathe = CAKeyframeAnimation(keyPath: "path")
        breathe.values = [path(.collapsed, 34), path(.expanded, 0), path(.expanded, 0), path(.collapsed, 34), path(.collapsed, 34)]
        breathe.keyTimes = [0, 0.3, 0.6, 0.85, 1]
        breathe.timingFunctions = [CAMediaTimingFunction(controlPoints: 0.2, 1.1, 0.4, 1), CAMediaTimingFunction(name: .linear), CAMediaTimingFunction(name: .easeInEaseOut), CAMediaTimingFunction(name: .linear)]
        breathe.duration = 4.2
        breathe.repeatCount = .infinity
        island.add(breathe, forKey: "breathe")
        let glow = CALayer()
        glow.frame = CGRect(x: canvas.width / 2 - 40, y: canvas.height - 3, width: 80, height: 3)
        glow.cornerRadius = 1.5
        glow.backgroundColor = NSColor(srgbRed: 1, green: 0.48, blue: 0.35, alpha: 0.85).cgColor
        view.layer?.addSublayer(glow)
        view.layer?.addSublayer(island)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
