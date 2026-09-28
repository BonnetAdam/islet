import Foundation

/// The coding agents Islet connects to through their own hooks. Each writes its events in its own shape; they all
/// become the same `HookEvent` here, so the board and the island never need to know which agent sent one.
public enum CodingAgent: String, CaseIterable, Sendable, Codable {
    case claude, codex, gemini, cursor, copilot

    public var name: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .gemini: "Gemini CLI"
        case .cursor: "Cursor"
        case .copilot: "GitHub Copilot (VS Code)"
        }
    }

    public static func symbol(for name: String?) -> String {
        switch name {
        case CodingAgent.claude.name: "sun.max.fill"
        case CodingAgent.codex.name: "curlybraces.square"
        case CodingAgent.gemini.name: "sparkles"
        case CodingAgent.cursor.name: "cursorarrow"
        case CodingAgent.copilot.name: "chevron.left.forwardslash.chevron.right"
        default: "sparkle"
        }
    }

    /// Agents whose hooks can wait for an answer: their permission requests get Allow and Deny in the island. The
    /// others say they need the user, who answers in the agent itself.
    public var answersPermissions: Bool { self == .claude || self == .codex }

    /// Turns one hook payload, as this agent wrote it, into an event. Nil for events Islet does not follow.
    public func event(from raw: [String: JSONValue]) -> HookEvent? {
        func string(_ key: String) -> String? { raw[key]?.string }
        switch self {
        case .claude, .codex:
            guard let session = string("session_id"), let name = string("hook_event_name") else { return nil }
            return HookEvent(
                sessionID: session, event: name, cwd: string("cwd"), toolName: string("tool_name"),
                toolInput: raw["tool_input"]?.object, notificationType: string("notification_type"),
                message: string("message"), agentName: string("agent_name"),
                agent: string("agent_name") == nil ? self : nil
            )
        case .gemini:
            let events = [
                "SessionStart": "SessionStart", "SessionEnd": "SessionEnd", "BeforeAgent": "UserPromptSubmit",
                "BeforeTool": "PreToolUse", "AfterTool": "PostToolUse", "AfterAgent": "Stop", "Notification": "Notification",
            ]
            guard let session = string("session_id"), let name = string("hook_event_name").flatMap({ events[$0] }) else { return nil }
            // Gemini asks for a tool's confirmation in the terminal and tells its hooks with a ToolPermission notice.
            let notice = string("notification_type") == "ToolPermission" ? "permission_prompt" : string("notification_type")
            return HookEvent(
                sessionID: session, event: name, cwd: string("cwd"), toolName: string("tool_name"),
                toolInput: raw["tool_input"]?.object, notificationType: notice, message: string("message"), agent: self
            )
        case .cursor:
            guard let session = string("conversation_id"), let name = string("hook_event_name") else { return nil }
            let cwd = raw["workspace_roots"]?.array?.first?.string ?? string("cwd")
            var event = HookEvent(sessionID: session, event: "", cwd: cwd, agent: self)
            switch name {
            case "sessionStart": event.event = "SessionStart"
            case "sessionEnd": event.event = "SessionEnd"
            case "beforeSubmitPrompt": event.event = "UserPromptSubmit"
            case "stop": event.event = "Stop"
            case "postToolUse":
                event.event = "PostToolUse"
                event.toolName = string("tool_name")
                event.toolInput = raw["tool_input"]?.object
            case "afterShellExecution":
                event.event = "PostToolUse"
                event.toolName = "Shell"
                event.toolInput = string("command").map { ["command": .string($0)] }
            case "afterFileEdit":
                event.event = "PostToolUse"
                event.toolName = "Edit"
                event.toolInput = string("file_path").map { ["file_path": .string($0)] }
            default:
                return nil
            }
            return event
        case .copilot:
            guard let name = string("hook_event_name") else { return nil }
            let session = string("session_id") ?? string("transcript_path") ?? string("cwd") ?? "vscode-copilot"
            let event = switch name {
            case "PreToolUse": "PreToolUse"
            case "Stop": "SessionEnd"
            default: name
            }
            return HookEvent(
                sessionID: session, event: event,
                cwd: string("cwd"), toolName: string("tool_name"),
                toolInput: raw["tool_input"]?.object, message: string("prompt") ?? string("message"), agent: self
            )
        }
    }
}
