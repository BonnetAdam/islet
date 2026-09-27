import Foundation
import Testing
@testable import IsletCore

@Suite struct CodingAgentTests {
    func raw(_ json: String) throws -> [String: JSONValue] {
        try JSONDecoder().decode([String: JSONValue].self, from: Data(json.utf8))
    }

    @Test func codexSpeaksLikeClaudeCode() throws {
        let event = try #require(CodingAgent.codex.event(from: raw("""
        {"session_id":"c1","hook_event_name":"PermissionRequest","cwd":"/Users/me/islet","model":"gpt-5",
         "tool_name":"Bash","tool_input":{"command":"rm -rf build"}}
        """)))
        #expect(event.event == "PermissionRequest")
        #expect(event.agent == .codex)
        #expect(event.project == "islet")
        #expect(event.toolSummary == "Bash · rm -rf build")
        #expect(CodingAgent.codex.answersPermissions)
    }

    @Test func geminiEventsBecomeTheSameStates() throws {
        let tool = try #require(CodingAgent.gemini.event(from: raw("""
        {"session_id":"g1","hook_event_name":"BeforeTool","cwd":"/tmp/site","timestamp":"2026-09-27T12:00:00Z",
         "tool_name":"run_shell_command","tool_input":{"command":"npm test\\nnpm run build"}}
        """)))
        #expect(tool.event == "PreToolUse")
        #expect(tool.toolSummary == "Shell · npm test")
        let ask = try #require(CodingAgent.gemini.event(from: raw("""
        {"session_id":"g1","hook_event_name":"Notification","notification_type":"ToolPermission","message":"Allow write_file?"}
        """)))
        #expect(ask.notificationType == "permission_prompt")
        let done = try #require(CodingAgent.gemini.event(from: raw(#"{"session_id":"g1","hook_event_name":"AfterAgent"}"#)))
        #expect(done.event == "Stop")
        #expect(CodingAgent.gemini.event(from: try raw(#"{"session_id":"g1","hook_event_name":"BeforeModel"}"#)) == nil)
        #expect(!CodingAgent.gemini.answersPermissions)

        var board = AgentBoard()
        board.apply(tool, at: Date())
        board.apply(ask, at: Date())
        #expect(board.ordered.first?.state == .waiting("Allow write_file?"))
        #expect(board.ordered.first?.agent == "Gemini CLI")
    }

    @Test func cursorConversationsBecomeSessions() throws {
        let edit = try #require(CodingAgent.cursor.event(from: raw("""
        {"conversation_id":"k1","generation_id":"x","hook_event_name":"afterFileEdit","workspace_roots":["/Users/me/shop"],
         "file_path":"/Users/me/shop/src/cart.ts","edits":[]}
        """)))
        #expect(edit.sessionID == "k1")
        #expect(edit.event == "PostToolUse")
        #expect(edit.project == "shop")
        #expect(edit.toolSummary == "Edit · cart.ts")
        let shell = try #require(CodingAgent.cursor.event(from: raw("""
        {"conversation_id":"k1","hook_event_name":"afterShellExecution","command":"pnpm lint","output":"ok"}
        """)))
        #expect(shell.toolSummary == "Shell · pnpm lint")
        #expect(try CodingAgent.cursor.event(from: raw(#"{"conversation_id":"k1","hook_event_name":"stop","status":"completed"}"#))?.event == "Stop")
        #expect(CodingAgent.cursor.event(from: try raw(#"{"conversation_id":"k1","hook_event_name":"beforeReadFile"}"#)) == nil)
    }

    @Test func scriptsReportedWithIsletAgentKeepTheirName() throws {
        let event = try #require(CodingAgent.claude.event(from: raw("""
        {"session_id":"aider","hook_event_name":"Working","agent_name":"Aider"}
        """)))
        #expect(event.agent == nil)
        #expect(event.project == "Aider")
    }
}
