#!/bin/bash
# scripts/capture-site.sh: photographs the real app for the website, window by window, then lays the island on a
# real macOS desktop (ISLET_DESKTOP, a 3024 x 1964 PNG) and writes the WebP files the website uses.
# Nothing is drawn by hand: each picture is Islet itself, in English, driven by its debug switches, with a silent
# demo track playing so no sound and no personal data (calendar, clipboard) appear.
set -euo pipefail
cd "$(dirname "$0")/.."
APP=.build/xcode/Build/Products/Debug/Islet.app
OUT=.build/site-shots
TMP=$(mktemp -d)
mkdir -p "$OUT"
[ -d "$APP" ] || scripts/build.sh >/dev/null

# The window of Islet whose frame matches: "panel" (the island, hanging from the top of the screen) or "window".
window_id() {
  swift - "$1" <<'SWIFT' 2>/dev/null
import CoreGraphics
let kind = CommandLine.arguments[1]
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w["kCGWindowOwnerName"] as? String) == "Islet" {
    let bounds = w["kCGWindowBounds"] as! [String: Double]
    let isPanel = bounds["Y"]! == 0
    if (kind == "panel") == isPanel { print(w["kCGWindowNumber"]!); break }
}
SWIFT
}
shoot() { local id; id=$(window_id "$1"); [ -n "$id" ] && screencapture -x -o -l "$id" "$OUT/$2.png" && echo "  $2"; }
run() { pkill -x Islet 2>/dev/null || true; sleep 0.6; ("$APP/Contents/MacOS/Islet" -AppleLanguages '(en)' -AppleLocale en_US "$@" >/dev/null 2>&1 &) }

swift brand/scripts/demo-cover.swift "$TMP/cover.png"
ALBUM="Long Light" swift scripts/fake-player.swift "Golden Hour" "Sunset Avenue" 214 "$TMP/cover.png" >/dev/null 2>&1 &
PLAYER=$!
trap 'kill $PLAYER 2>/dev/null; pkill -x Islet 2>/dev/null; rm -rf "$TMP"' EXIT
sleep 4

echo "Island:"
run; sleep 5; shoot panel music-compact
run -IsletOpen YES; sleep 4; shoot panel music-open
run -IsletDemo headphones; sleep 7; shoot panel airpods-pro
run -IsletDemo max; sleep 7; shoot panel airpods-max
run -IsletOpen YES -IsletPage live; sleep 3
# In a background list the shell would give the hook an empty stdin: the pipe stays inside the subshell.
(echo '{"session_id":"site","hook_event_name":"PermissionRequest","cwd":"/Users/me/islet","tool_name":"Bash","tool_input":{"command":"git push origin main","description":"Push the release"}}' \
  | "$APP/Contents/Helpers/islet" hook >/dev/null 2>&1) &
sleep 3; shoot panel agent-request
pkill -f "Helpers/islet hook" 2>/dev/null || true

echo "Windows:"
front() { osascript -e 'tell application "System Events" to set frontmost of process "Islet" to true' >/dev/null 2>&1 || true; sleep 0.8; }
for pane in general island activities; do run -IsletSettings "$pane"; sleep 3; front; shoot window "settings-$pane"; done

echo "Website images:"
swift scripts/compose-site.swift "${ISLET_DESKTOP:-$HOME/islet-private/site-sources/desktop/desktop.png}" "$OUT" >/dev/null
mkdir -p site/assets/island site/assets/app site/assets/figures
for s in music-compact music-open airpods-pro airpods-max agent-request; do cwebp -quiet -q 90 -alpha_q 100 "$OUT/$s.png" -o "site/assets/island/$s.webp"; done
for s in settings-general settings-island settings-activities; do cwebp -quiet -q 88 "$OUT/$s.png" -o "site/assets/app/$s.webp"; done
for f in "$OUT"/figures/*.png; do n=$(basename "$f" .png); cwebp -quiet -q 86 "$f" -o "site/assets/figures/$n.webp"; done
echo "  site/assets/{island,app,figures}"
