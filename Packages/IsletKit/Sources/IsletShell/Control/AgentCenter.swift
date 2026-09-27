import AppKit
import IsletCore
import Observation

/// Follows the coding agents that report through their hooks, and holds their permission requests until the user
/// answers from the island.
@MainActor
@Observable
final class AgentCenter {
    enum Decision: String, Sendable {
        case allow, deny, ask
    }

    struct PendingRequest: Identifiable {
        var id: String { sessionID }
        var sessionID: String
        var project: String
        var summary: String
        var detail: String?
        var received: Date
    }

    private(set) var board = AgentBoard()
    private(set) var pending: [String: PendingRequest] = [:]
    @ObservationIgnored private var responders: [String: @Sendable (Decision) -> Void] = [:]
    @ObservationIgnored private var settleTimer: Task<Void, Never>?
    @ObservationIgnored private var timeouts: [String: Task<Void, Never>] = [:]

    @ObservationIgnored var onChange: (() -> Void)?
    /// Called when a request arrives, so the island can open and show it.
    @ObservationIgnored var onRequest: (() -> Void)?

    /// How long a permission request waits for the island before falling back to the terminal.
    static let answerWindow: Duration = .seconds(90)

    var sessions: [AgentSession] { board.ordered }

    func receive(_ event: HookEvent, respond: @escaping @Sendable (Decision) -> Void) {
        let now = Date()
        board.apply(event, at: now)
        if event.event == "PermissionRequest" {
            // A newer request from the same session replaces an unanswered one.
            resolve(event.sessionID, .ask)
            pending[event.sessionID] = PendingRequest(
                sessionID: event.sessionID,
                project: event.project,
                summary: event.toolSummary ?? event.toolName ?? "",
                detail: event.toolDetail,
                received: now
            )
            responders[event.sessionID] = respond
            timeouts[event.sessionID] = Task { @MainActor [weak self] in
                try? await Task.sleep(for: Self.answerWindow)
                guard !Task.isCancelled else { return }
                self?.resolve(event.sessionID, .ask)
            }
            onRequest?()
        } else {
            respond(.ask)
            if ["PostToolUse", "PostToolUseFailure", "Stop", "SessionEnd", "UserPromptSubmit"].contains(event.event) {
                // The session moved on: a request it left behind was answered elsewhere.
                resolve(event.sessionID, .ask, updateBoard: false)
            }
        }
        scheduleSettle()
        onChange?()
    }

    func decide(_ sessionID: String, _ decision: Decision) {
        resolve(sessionID, decision)
        onChange?()
    }

    private func resolve(_ sessionID: String, _ decision: Decision, updateBoard: Bool = true) {
        timeouts.removeValue(forKey: sessionID)?.cancel()
        guard let respond = responders.removeValue(forKey: sessionID) else { return }
        pending[sessionID] = nil
        respond(decision)
        if updateBoard, decision != .ask {
            board.apply(HookEvent(sessionID: sessionID, event: "PreToolUse"), at: Date())
        }
    }

    /// Finished sessions go quiet after a few seconds; one timer for all of them.
    private func scheduleSettle() {
        settleTimer?.cancel()
        guard board.sessions.values.contains(where: { $0.state == .done }) else { return }
        settleTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(6.2))
            guard !Task.isCancelled, let self else { return }
            self.board.settle(now: Date())
            self.onChange?()
        }
    }

    func activity(tint: RGBA) -> Activity? {
        board.activity(now: Date(), tint: tint)
    }

    /// Focuses the terminal or editor a session runs in, by its folder when possible.
    func reveal(_ session: AgentSession) {
        let candidates = ["com.anthropic.claudefordesktop", "com.mitchellh.ghostty", "com.googlecode.iterm2", "com.apple.Terminal", "com.microsoft.VSCode", "dev.warp.Warp-Stable"]
        for bundle in candidates {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first {
                app.activate()
                return
            }
        }
    }
}
