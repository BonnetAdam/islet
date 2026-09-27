# The Islet API

Islet listens on a Unix domain socket:

```
~/Library/Application Support/Islet/islet.sock
```

The socket file is readable only by your user account, so only programs running as you can reach it. Web pages
cannot: browsers do not open Unix sockets. It speaks plain HTTP/1.1 with JSON bodies.

## The `islet` command

```
islet push <id> [--title T] [--subtitle S] [--symbol SF_SYMBOL] [--tint COLOR]
                [--progress 0..1 | N%] [--text T] [--priority ambient|standard|alert] [--ttl SECONDS]
islet done <id> [--text T]
islet remove <id>
islet list
islet status
islet agent <name> <working|waiting|done|idle|end> [--message M] [--session S]
islet hook                      # for Claude Code hooks, reads the event on stdin
islet hooks install [--settings PATH]
islet hooks uninstall [--settings PATH]
```

Colours: `white`, `green`, `orange`, `red`, `blue`, `purple`, `yellow`, `pink`, `teal`, `gray`, or `#RRGGBB`.

## What an activity shows

Beside the camera, the left wing shows the symbol in the tint colour. The right wing shows a ring when there is a
progress, otherwise the text. In the open island, the Live page lists every activity with its title, subtitle and
progress bar.

When several activities want the notch, the highest priority wins, then the most recent:
`alert` > `standard` > `ambient`. Islet's own brief displays (volume, charger) come first for a second or two.

## Endpoints

| Method and path | Body | Answer |
|---|---|---|
| `GET /v1/status` | | `{"app": "Islet", "version": "0.1.0", "activities": 1, "agents": 0}` |
| `GET /v1/activities` | | `{"activities": [{"id": "build", "title": "Build", "progress": 0.4}]}` |
| `POST /v1/activities` | an activity | `{"id": "build"}` |
| `POST /v1/activities/<id>/done?text=Done` | | `{"id": "build"}` |
| `DELETE /v1/activities/<id>` | | `{"id": "build"}` |
| `POST /v1/agents/events` | a Claude Code hook event | `{"decision": "allow"}`, `"deny"` or `"ask"` |

An activity:

```json
{
  "id": "build",
  "title": "Build",
  "subtitle": "12 of 40 files",
  "symbol": "hammer.fill",
  "tint": "orange",
  "progress": 0.3,
  "text": "30%",
  "priority": "standard",
  "ttl": 60
}
```

Only `id` is required: 64 characters at most. `progress` is clamped to 0 to 1; `ttl` to one second to one day.

With curl:

```sh
curl --unix-socket "$HOME/Library/Application Support/Islet/islet.sock" \
  -X POST http://islet/v1/activities \
  -d '{"id":"deploy","title":"Deploy","progress":0.6,"tint":"teal"}'
```

## Links

```
islet://push?id=tea&title=Tea&symbol=cup.and.saucer.fill&ttl=240
islet://done?id=tea
islet://remove?id=tea
```

## Agents

`POST /v1/agents/events` takes the JSON that Claude Code writes on a hook's stdin. Islet follows each session through
`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Notification`, `Stop` and `SessionEnd`.

For `PermissionRequest`, the request waits until the user answers from the island, for up to 90 seconds. The
answer is `allow`, `deny`, or `ask`, which means "let Claude Code ask in the terminal". `islet hook` turns it into
Claude Code's hook output.

### Other agents

Agents without Claude Code's hooks report their state with `islet agent`:

```sh
islet agent Codex working --message "Refactoring the parser"
islet agent Codex waiting --message "Approve the plan"
islet agent Codex done
```

For Codex, point its `notify` setting at the command in `~/.codex/config.toml`; Codex calls it when a turn ends:

```toml
notify = ["islet", "agent", "Codex", "done"]
```

