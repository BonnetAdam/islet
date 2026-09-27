// islet: pushes live activities to Islet, and connects coding agents to it.
//
// Talks HTTP over Islet's Unix socket, so it only reaches the Islet of the user running it.

import Foundation

let usage = """
usage: islet <command> [options]

  push <id> [--title T] [--subtitle S] [--symbol SF_SYMBOL] [--tint COLOR]
            [--progress 0..1 | N%] [--text T] [--priority ambient|standard|alert] [--ttl SECONDS]
                        show or update a live activity in the notch
  done <id> [--text T]  mark an activity done: a check mark, then it leaves
  remove <id>           take an activity away
  list                  list the activities pushed by programs
  status                check that Islet is running

  agent <name> <working|waiting|done|idle|end> [--message M] [--session S]
                        report any coding agent (Codex, Cursor, Aider...) to the notch
  hook                  Claude Code hook: reads the event on stdin (see `islet hooks install`)
  hooks install [--settings PATH]
                        add Islet's hooks to Claude Code (~/.claude/settings.json)
  hooks uninstall [--settings PATH]

Colours: white, green, orange, red, blue, purple, yellow, pink, teal, gray, or #RRGGBB.
Example: islet push build --title Build --symbol hammer.fill --tint orange --progress 40%
"""

// MARK: Socket

func socketPath() -> String {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Islet/islet.sock").path
}

enum ClientError: Error {
    case notRunning
    case failed(String)
}

/// Sends one HTTP request over the socket and returns the status and body.
func request(_ method: String, _ path: String, body: Data? = nil, timeout: Int = 5) throws -> (Int, Data) {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { throw ClientError.notRunning }
    defer { close(fd) }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let bytes = Array(socketPath().utf8CString)
    guard bytes.count <= MemoryLayout.size(ofValue: address.sun_path) else { throw ClientError.notRunning }
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in bytes.withUnsafeBytes { buffer.copyMemory(from: $0) } }
    let connected = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    guard connected == 0 else { throw ClientError.notRunning }
    var wait = timeval(tv_sec: timeout, tv_usec: 0)
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &wait, socklen_t(MemoryLayout<timeval>.size))
    var noSigPipe: Int32 = 1
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

    let payload = body ?? Data()
    var message = Data("\(method) \(path) HTTP/1.1\r\nHost: islet\r\nContent-Type: application/json\r\nContent-Length: \(payload.count)\r\nConnection: close\r\n\r\n".utf8)
    message.append(payload)
    let sent = message.withUnsafeBytes { send(fd, $0.baseAddress, $0.count, 0) }
    guard sent == message.count else { throw ClientError.notRunning }

    var response = Data()
    var chunk = [UInt8](repeating: 0, count: 16_384)
    while true {
        let count = recv(fd, &chunk, chunk.count, 0)
        if count <= 0 { break }
        response.append(chunk, count: count)
    }
    guard let split = response.range(of: Data("\r\n\r\n".utf8)),
          let head = String(data: response[..<split.lowerBound], encoding: .utf8),
          let status = head.split(separator: " ").dropFirst().first.flatMap({ Int($0) })
    else { throw ClientError.failed("no answer from Islet") }
    return (status, Data(response[split.upperBound...]))
}

func json(_ object: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("islet: \(message)\n".utf8))
    exit(1)
}

func run(_ method: String, _ path: String, body: Data? = nil) -> Data {
    do {
        let (status, data) = try request(method, path, body: body)
        guard status == 200 else {
            let reason = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            fail(reason ?? "Islet answered \(status)")
        }
        return data
    } catch ClientError.notRunning {
        fail("Islet is not running")
    } catch {
        fail("\(error)")
    }
}

// MARK: Options

func options(_ arguments: ArraySlice<String>) -> [String: String] {
    var result: [String: String] = [:]
    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        guard argument.hasPrefix("--") else { fail("unexpected argument \(argument)") }
        guard let value = iterator.next() else { fail("\(argument) needs a value") }
        result[String(argument.dropFirst(2))] = value
    }
    return result
}

func percentOrFraction(_ value: String) -> Double? {
    if value.hasSuffix("%") { return Double(value.dropLast()).map { $0 / 100 } }
    guard let number = Double(value) else { return nil }
    return number > 1 ? number / 100 : number
}

// MARK: Hooks

/// Forwards a Claude Code hook event. Never gets in Claude's way: when Islet is not running, or anything goes
/// wrong, it prints nothing and exits 0, which leaves Claude Code's own behaviour unchanged.
func hook() -> Never {
    let input = FileHandle.standardInput.readDataToEndOfFile()
    guard let event = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else { exit(0) }
    let name = event["hook_event_name"] as? String ?? ""
    let waits = name == "PermissionRequest"
    guard let (status, data) = try? request("POST", "/v1/agents/events", body: input, timeout: waits ? 110 : 3),
          status == 200, waits,
          let answer = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let decision = answer["decision"] as? String, decision == "allow" || decision == "deny"
    else { exit(0) }
    var verdict: [String: Any] = ["behavior": decision]
    if decision == "deny" { verdict["message"] = "Denied from Islet." }
    let output = ["hookSpecificOutput": ["hookEventName": "PermissionRequest", "decision": verdict]]
    FileHandle.standardOutput.write(json(output))
    exit(0)
}

let hookEvents: [(name: String, matcher: Bool, timeout: Int)] = [
    ("SessionStart", false, 5),
    ("UserPromptSubmit", false, 5),
    ("PreToolUse", true, 5),
    ("PostToolUse", true, 5),
    ("PermissionRequest", true, 120),
    ("Notification", false, 5),
    ("Stop", false, 5),
    ("SessionEnd", false, 2),
]

func linkPath() -> String { NSHomeDirectory() + "/.local/bin/islet" }
let hookCommand = "\"$HOME/.local/bin/islet\" hook"

func isIsletHook(_ entry: Any) -> Bool {
    guard let group = entry as? [String: Any], let hooks = group["hooks"] as? [[String: Any]] else { return false }
    return hooks.contains { ($0["command"] as? String)?.contains("islet\" hook") == true || ($0["command"] as? String)?.hasSuffix("islet hook") == true }
}

func editSettings(_ path: String, install: Bool) -> Never {
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    var settings: [String: Any] = [:]
    if let data = try? Data(contentsOf: url) {
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            fail("\(url.path) is not valid JSON; left untouched")
        }
        settings = parsed
        try? data.write(to: url.appendingPathExtension("islet-backup"))
    }
    var hooks = settings["hooks"] as? [String: Any] ?? [:]
    for event in hookEvents {
        var groups = (hooks[event.name] as? [Any] ?? []).filter { !isIsletHook($0) }
        if install {
            var group: [String: Any] = ["hooks": [["type": "command", "command": hookCommand, "timeout": event.timeout]]]
            if event.matcher { group["matcher"] = "*" }
            groups.append(group)
        }
        hooks[event.name] = groups.isEmpty ? nil : groups
    }
    settings["hooks"] = hooks.isEmpty ? nil : hooks

    if install {
        // The hooks call the command through ~/.local/bin, so moving the app never breaks them.
        let tool = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let link = linkPath()
        if (try? FileManager.default.destinationOfSymbolicLink(atPath: link)) == nil, !FileManager.default.fileExists(atPath: link) {
            try? FileManager.default.createDirectory(atPath: (link as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try? FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: tool.path)
        }
    }
    do {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: url, options: .atomic)
    } catch {
        fail("could not write \(url.path): \(error.localizedDescription)")
    }
    print(install ? "Islet hooks installed in \(url.path). New sessions report to Islet." : "Islet hooks removed from \(url.path).")
    exit(0)
}

// MARK: Commands

let arguments = CommandLine.arguments.dropFirst()
guard let command = arguments.first else {
    print(usage)
    exit(0)
}

switch command {
case "push":
    guard let id = arguments.dropFirst().first, !id.hasPrefix("--") else { fail("push needs an id") }
    let values = options(arguments.dropFirst(2))
    var body: [String: Any] = ["id": id]
    for key in ["title", "subtitle", "symbol", "tint", "text", "priority"] { body[key] = values[key] }
    if let progress = values["progress"] {
        guard let fraction = percentOrFraction(progress) else { fail("--progress takes 0 to 1, or a percentage") }
        body["progress"] = fraction
    }
    if let ttl = values["ttl"] {
        guard let seconds = Double(ttl) else { fail("--ttl takes seconds") }
        body["ttl"] = seconds
    }
    _ = run("POST", "/v1/activities", body: json(body))

case "done":
    guard let id = arguments.dropFirst().first else { fail("done needs an id") }
    let text = options(arguments.dropFirst(2))["text"]
    let query = text.flatMap { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }.map { "?text=\($0)" } ?? ""
    _ = run("POST", "/v1/activities/\(id)/done\(query)")

case "remove":
    guard let id = arguments.dropFirst().first else { fail("remove needs an id") }
    _ = run("DELETE", "/v1/activities/\(id)")

case "list":
    let data = run("GET", "/v1/activities")
    let list = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["activities"] as? [[String: Any]] ?? []
    if list.isEmpty { print("No activities.") }
    for item in list {
        let id = item["id"] as? String ?? ""
        let title = item["title"] as? String ?? ""
        let detail = (item["progress"] as? Double).map { "\(Int($0 * 100))%" } ?? (item["text"] as? String ?? "")
        print([id, title, detail].filter { !$0.isEmpty }.joined(separator: "  "))
    }

case "status":
    let data = run("GET", "/v1/status")
    let info = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    print("Islet \(info["version"] ?? "") is running: \(info["activities"] ?? 0) activities, \(info["agents"] ?? 0) agent sessions.")

case "agent":
    let rest = Array(arguments.dropFirst())
    guard rest.count >= 2 else { fail("agent needs a name and a state") }
    let states = ["working": "Working", "waiting": "Waiting", "done": "Done", "idle": "Idle", "end": "End"]
    guard let state = states[rest[1].lowercased()] else { fail("state is working, waiting, done, idle or end") }
    // Anything after the options (Codex passes its event as a last argument) is ignored.
    var values: [String: String] = [:]
    var index = 2
    while index + 1 < rest.count, rest[index].hasPrefix("--") {
        values[String(rest[index].dropFirst(2))] = rest[index + 1]
        index += 2
    }
    var event: [String: Any] = ["hook_event_name": state, "agent_name": rest[0], "session_id": values["session"] ?? rest[0].lowercased()]
    if let message = values["message"] { event["message"] = message }
    // Agents call this from their own hooks: never fail loudly when Islet is closed.
    _ = try? request("POST", "/v1/agents/events", body: json(event), timeout: 3)

case "hook":
    hook()

case "hooks":
    let action = arguments.dropFirst().first ?? ""
    let path = options(arguments.dropFirst(2))["settings"] ?? "~/.claude/settings.json"
    switch action {
    case "install": editSettings(path, install: true)
    case "uninstall": editSettings(path, install: false)
    default: fail("hooks takes install or uninstall")
    }

case "help", "--help", "-h":
    print(usage)

default:
    fail("unknown command \(command). Run `islet help`.")
}
