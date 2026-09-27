#!/bin/bash
# scripts/capture-site.sh: photographs the real app for the website, window by window, then lays the island on a
# real macOS desktop (ISLET_DESKTOP, a 3024 x 1964 PNG) and writes the WebP files the website uses.
# Nothing is drawn by hand: each picture is Islet itself, in English, driven by its debug switches, with a silent
# demo track playing so no sound and no personal data (calendar, clipboard) appear.
set -euo pipefail
cd "$(dirname "$0")/.."
APP=.build/xcode/Build/Products/Debug/Islet.app
# The user's own Islet, relaunched at the end if it was running.
USER_ISLET=$(ps -axo command= | grep -m1 "/Islet.app/Contents/MacOS/Islet$" | sed 's|/Contents/MacOS/Islet$||' || true)
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

echo "Island:"
# At rest first, before the demo track: the island is the notch itself, its exact shape.
run; sleep 4; shoot panel rest

swift brand/scripts/demo-cover.swift "$TMP/cover.png"
# Demo files for the shelf (a brief, a photo, a note), and the pieces of macOS the website's scenes use.
swift brand/scripts/demo-files.swift "$TMP/files" "$TMP/cover.png" >/dev/null
mkdir -p "$TMP/none" "$TMP/one"
cp "$TMP/files/Brief.pdf" "$TMP/one/"
# The demo track, restarted before each capture of the player so every picture shows the same moment of the song.
PLAYER=
player() {
  [ -n "$PLAYER" ] && kill "$PLAYER" 2>/dev/null
  ALBUM="Long Light" swift scripts/fake-player.swift "Golden Hour" "Sunset Avenue" 214 "$TMP/cover.png" >/dev/null 2>&1 &
  PLAYER=$!
  sleep 3
}
player
trap 'kill $PLAYER 2>/dev/null; pkill -x Islet 2>/dev/null; rm -rf "$TMP"; [ -n "$USER_ISLET" ] && open "$USER_ISLET"' EXIT
sleep 4
player; run; sleep 4; shoot panel music-compact
player; run -IsletOpen YES; sleep 4; shoot panel music-open
run -IsletDemo headphones; sleep 7; shoot panel airpods-pro
run -IsletDemo max; sleep 7; shoot panel airpods-max
run -IsletOpen YES -IsletPage live; sleep 3
# In a background list the shell would give the hook an empty stdin: the pipe stays inside the subshell.
(echo '{"session_id":"site","hook_event_name":"PermissionRequest","cwd":"/Users/me/islet","tool_name":"Bash","tool_input":{"command":"git push origin main","description":"Push the release"}}' \
  | "$APP/Contents/Helpers/islet" hook >/dev/null 2>&1) &
sleep 3; shoot panel agent-request
pkill -f "Helpers/islet hook" 2>/dev/null || true
# The shelf: files dragged over, one dropped, then three. Demo files only: the user's shelf is never read.
run -IsletDemoShelf "$TMP/none" -IsletDemo drop -IsletOpen YES -IsletPage shelf; sleep 4; shoot panel shelf-drop
run -IsletDemoShelf "$TMP/one" -IsletOpen YES -IsletPage shelf; sleep 4; shoot panel shelf-one
run -IsletDemoShelf "$TMP/files" -IsletOpen YES -IsletPage shelf; sleep 4; shoot panel shelf-files
# The clipboard, with demo copies: the real pasteboard is never read.
run -IsletDemo clipboard -IsletDemoImage "$TMP/cover.png" -IsletOpen YES -IsletPage clipboard; sleep 4; shoot panel clipboard
# Settings made visible: every page off, then the three sizes of the open island.
player; run -IsletOpen YES -enabledPages '()'; sleep 4; shoot panel music-open-minimal
player; run -IsletOpen YES -islandSize compact; sleep 4; shoot panel music-open-compact
player; run -IsletOpen YES -islandSize large; sleep 4; shoot panel music-open-large

echo "Windows:"
# Where a copy comes from, for the clipboard scene: a real TextEdit window with its text selected. Only when TextEdit
# is not already open, so the user's documents are never touched.
if ! pgrep -x TextEdit >/dev/null; then
  printf '{\\rtf1\\ansi{\\fonttbl\\f0\\fnil .AppleSystemUIFont;}\\f0\\fs44 The notch, made useful.}' > "$TMP/Copy.rtf"
  open -a TextEdit "$TMP/Copy.rtf" --args -AppleLanguages '(en)' -AppleLocale en_US; sleep 2.5
  osascript -e 'tell application "System Events" to tell process "TextEdit"' \
    -e 'set frontmost to true' -e 'set position of front window to {160, 300}' -e 'set size of front window to {520, 170}' \
    -e 'end tell' -e 'delay 0.6' -e 'tell application "System Events" to keystroke "a" using command down' >/dev/null 2>&1
  sleep 1
  TEXTEDIT=$(swift - <<'SWIFT' 2>/dev/null
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w["kCGWindowOwnerName"] as? String) == "TextEdit" && (w["kCGWindowLayer"] as? Int) == 0 { print(w["kCGWindowNumber"]!); break }
SWIFT
)
  [ -n "$TEXTEDIT" ] && screencapture -x -o -l "$TEXTEDIT" "$OUT/textedit-copy.png" && echo "  textedit-copy"
  osascript -e 'tell application "System Events" to tell process "TextEdit" to set frontmost to true' -e 'tell application "System Events" to keystroke "q" using command down' >/dev/null 2>&1
fi
front() { osascript -e 'tell application "System Events" to set frontmost of process "Islet" to true' >/dev/null 2>&1 || true; sleep 0.8; }
for pane in general island activities; do run -IsletSettings "$pane"; sleep 3; front; shoot window "settings-$pane"; done
# The Pages section, with System on, then off.
run -IsletSettings island -IsletSettingsHeight 900; sleep 3; front; shoot window settings-pages-on
run -IsletSettings island -IsletSettingsHeight 900 -enabledPages '()'; sleep 3; front; shoot window settings-pages-off

echo "Website and README images:"
DESKTOP="${ISLET_DESKTOP:?set ISLET_DESKTOP to a 3024 x 1964 PNG of a macOS desktop}"
mkdir -p site/assets/island site/assets/app docs/images
for s in rest music-compact music-open airpods-pro airpods-max agent-request shelf-drop shelf-one shelf-files clipboard \
  music-open-minimal music-open-compact music-open-large; do cwebp -quiet -q 90 -alpha_q 100 "$OUT/$s.png" -o "site/assets/island/$s.webp"; done
for s in settings-general settings-island settings-activities settings-pages-on settings-pages-off; do cwebp -quiet -q 88 "$OUT/$s.png" -o "site/assets/app/$s.webp"; done
# The pieces of macOS the scenes move around: the arrow cursor and the brief as it sits on a desktop.
mkdir -p site/assets/macos
cp "$TMP/cursor-arrow.png" site/assets/macos/cursor-arrow.png
cp "$TMP/brief-icon.png" site/assets/macos/brief-icon.png
[ -f "$OUT/textedit-copy.png" ] && cwebp -quiet -q 92 "$OUT/textedit-copy.png" -o site/assets/macos/textedit-copy.webp
# The desktop: whole for the MacBook, and its top 600 points at 2x for the close-ups and the scenes.
cwebp -quiet -q 84 -resize 1920 0 "$DESKTOP" -o site/assets/desktop.webp
cwebp -quiet -q 86 -crop 0 0 3024 1200 "$DESKTOP" -o site/assets/desktop-top.webp
# The README cannot lay captures on the desktop with CSS: it gets them composed.
swift scripts/compose-site.swift "$DESKTOP" "$OUT" >/dev/null
for f in "$OUT"/figures/*.png; do cwebp -quiet -q 88 "$f" -o "docs/images/$(basename "$f" .png).webp"; done
echo "  site/assets/{island,app}, site/assets/desktop*.webp, docs/images"
