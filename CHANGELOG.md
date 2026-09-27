# Changelog

Each release's section is what Islet's update window and the GitHub release show. Dates are in ISO format.

## Unreleased

- **Liquid Glass**: on macOS 26, the open island stays black where it meets the notch and melts into glass toward its
  lower edge, so it sits on your desktop instead of covering it. Choose it in Settings, Island, Liquid Glass, as macOS
  lets you choose for its own glass: Transparent (the desktop seen through, lightly blurred and dimmed; the default),
  Tinted (Apple's frosted Liquid Glass) or Black. It stays black when Reduce transparency is on.

## 1.0.0 (2026-09-27)

The first release of Islet: a Dynamic Island for the MacBook notch, free and open source under the MIT License.

- **Now playing**: artwork, scrubber, controls and output picker in the island; the track peeks in the wings when it
  changes, and a swipe on the closed island skips it.
- **AI agents**: Claude Code, Codex, Gemini CLI and Cursor sessions show in the notch while they work; Claude Code's
  and Codex's permission requests get Allow and Deny buttons. No account, no login: connect each agent in one click
  from Settings. Any other agent or script reports with `islet agent`.
- **Programmable**: an `islet` command, a local API, an `islet://` URL scheme and Shortcuts actions push your own live
  activities; extensions add more.
- **Privacy**: a green or orange light when the camera or the microphone is in use, and which app is using it.
- **Every Mac**: on displays without a notch, Islet floats under the menu bar. It never covers a menu or a menu bar
  icon: when an app's menus reach the notch, the activity keeps a single wing on the free side.
- **AirPods, by model**: AirPods, AirPods Pro, AirPods Max and Beats recognised from the model they report, each
  with its own card and battery.
- **The rest of the island**: headphone battery, volume and brightness, charging, a shelf for files,
  clipboard history with pins, agenda and reminders, timers, a mirror, a color picker, system stats, keep awake,
  downloads.
- **Settings and onboarding**: turn each module on or off, reorder the pages, choose the size and the motion, and meet
  Islet in a short guided tour that asks only for the permissions your modules need.
- **Updates**: Islet checks for updates with Sparkle; every update is EdDSA-signed and notarized by Apple.
