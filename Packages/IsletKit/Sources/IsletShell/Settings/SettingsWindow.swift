import AppKit
import ServiceManagement
import SwiftUI

/// The settings window. Islet has no Dock icon, so the window brings the app forward while it is open.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = String(localized: "Islet Settings", bundle: .module)
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Frees the view tree: settings are rarely open.
        window = nil
    }
}

struct SettingsView: View {
    @State private var opensOnHover = Preferences.opensOnHover
    @State private var replacesHUD = Preferences.replacesSystemHUD
    @State private var showsBattery = Preferences.showsBattery
    @State private var showsDevices = Preferences.showsAudioDevices
    @State private var showsPrivacy = Preferences.showsMicrophoneAndCamera
    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = MediaKeyTap.isTrusted
    @State private var cliMessage: String?
    @State private var hooksMessage: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    IsletMark().frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Islet").font(.system(size: 20, weight: .bold))
                        Text("The notch, made useful.", bundle: .module).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Toggle(isOn: $opensOnHover) { Text("Open when the pointer rests on the notch", bundle: .module) }
                    .onChange(of: opensOnHover) { Preferences.opensOnHover = opensOnHover }
                Toggle(isOn: $launchesAtLogin) { Text("Open Islet at login", bundle: .module) }
                    .onChange(of: launchesAtLogin) { setLaunchAtLogin(launchesAtLogin) }
            } header: {
                Text("General", bundle: .module)
            }

            Section {
                Toggle(isOn: $replacesHUD) { Text("Replace the volume and brightness displays", bundle: .module) }
                    .onChange(of: replacesHUD) { Preferences.replacesSystemHUD = replacesHUD }
                if replacesHUD, !trusted {
                    HStack {
                        Label { Text("Needs the Accessibility permission to take over the keys.", bundle: .module) } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                        .font(.callout)
                        Spacer()
                        Button { MediaKeyTap.requestTrust() } label: { Text("Grant…", bundle: .module) }
                    }
                }
                Toggle(isOn: $showsDevices) { Text("Show headphones and speakers as they connect", bundle: .module) }
                    .onChange(of: showsDevices) { Preferences.showsAudioDevices = showsDevices }
                Toggle(isOn: $showsBattery) { Text("Show charging and low battery", bundle: .module) }
                    .onChange(of: showsBattery) { Preferences.showsBattery = showsBattery }
                Toggle(isOn: $showsPrivacy) { Text("Show which app uses the microphone or camera", bundle: .module) }
                    .onChange(of: showsPrivacy) { Preferences.showsMicrophoneAndCamera = showsPrivacy }
            } header: {
                Text("Live activities", bundle: .module)
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Command line", bundle: .module)
                        Text(cliMessage ?? String(localized: "Installs `islet` in ~/.local/bin to push activities from any script.", bundle: .module))
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { cliMessage = CommandLineInstaller.install() } label: { Text("Install", bundle: .module) }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code", bundle: .module)
                        Text(hooksMessage ?? String(localized: "Follow your sessions in the notch and answer permission requests from it.", bundle: .module))
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { hooksMessage = CommandLineInstaller.connectClaudeCode() } label: { Text("Connect", bundle: .module) }
                }
            } header: {
                Text("Programmable notch", bundle: .module)
            }

            Section {
                Link(destination: URL(string: "https://github.com/ruben4reall/islet")!) {
                    Text("Source code on GitHub", bundle: .module)
                }
                Button(role: .destructive) { NSApp.terminate(nil) } label: { Text("Quit Islet", bundle: .module) }
            } footer: {
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"). MIT License.", bundle: .module)
                    .font(.footnote).foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 620)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            trusted = MediaKeyTap.isTrusted
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            launchesAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

/// The Islet mark: a black island resting under a luminous horizon.
struct IsletMark: View {
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.1), .black], startPoint: .top, endPoint: .bottom))
                Capsule()
                    .fill(Theme.lagoon.color)
                    .frame(width: side * 0.5, height: side * 0.07)
                    .offset(y: -side * 0.2)
                    .blur(radius: side * 0.03)
                IslandGlyph()
                    .fill(.white)
                    .frame(width: side * 0.56, height: side * 0.2)
                    .offset(y: -side * 0.08)
            }
            .frame(width: side, height: side)
        }
    }
}

/// The island silhouette of the mark: the notch shape itself.
struct IslandGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let ear = rect.height * 0.3
        let radius = rect.height * 0.55
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear, y: rect.minY + ear), control: CGPoint(x: rect.minX + ear, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear + radius, y: rect.maxY), control: CGPoint(x: rect.minX + ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear - radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - ear, y: rect.maxY - radius), control: CGPoint(x: rect.maxX - ear, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: rect.minY + ear))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.maxX - ear, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
