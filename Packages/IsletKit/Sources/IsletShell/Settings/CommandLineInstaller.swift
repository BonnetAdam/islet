import Foundation

/// Puts the `islet` command on the user's path and connects Claude Code to Islet, both without administrator rights.
@MainActor
enum CommandLineInstaller {
    static var bundledTool: URL? {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/islet")
        return FileManager.default.isExecutableFile(atPath: url.path) ? url : nil
    }

    static var linkURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/islet")
    }

    /// Links ~/.local/bin/islet to the tool inside the app. Returns a message for the settings window.
    static func install() -> String {
        guard let tool = bundledTool else { return String(localized: "The command is missing from this build.", bundle: .module) }
        let link = linkURL
        do {
            try FileManager.default.createDirectory(at: link.deletingLastPathComponent(), withIntermediateDirectories: true)
            if (try? link.checkResourceIsReachable()) == true || (try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) != nil {
                try FileManager.default.removeItem(at: link)
            }
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: tool)
            return String(localized: "Installed in ~/.local/bin. Try `islet status`.", bundle: .module)
        } catch {
            return error.localizedDescription
        }
    }

    /// True when ~/.claude/settings.json calls `islet hook`.
    static var claudeCodeConnected: Bool {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return text.contains("islet\" hook") || text.contains("islet hook")
    }

    static func connectClaudeCode() -> String { runHooks("install") }

    static func disconnectClaudeCode() -> String { runHooks("uninstall") }

    /// Runs `islet hooks install|uninstall`, which edits ~/.claude/settings.json and keeps a backup next to it.
    private static func runHooks(_ action: String) -> String {
        guard let tool = bundledTool else { return String(localized: "The command is missing from this build.", bundle: .module) }
        let process = Process()
        process.executableURL = tool
        process.arguments = ["hooks", action]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error.localizedDescription
        }
        let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        return action == "install"
            ? String(localized: "Connected. New Claude Code sessions report to Islet.", bundle: .module)
            : String(localized: "Disconnected. Claude Code no longer calls Islet.", bundle: .module)
    }
}
