# Third-party notices

The app contains no third-party code apart from [Sparkle](https://sparkle-project.org) (MIT), which installs updates.
Two techniques it uses were learned from open source projects, credited here:

- **Now playing on macOS 15.4 and later**: running a helper library inside `/usr/bin/perl`, which macOS entitles to
  read MediaRemote. Approach from [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) by Jonas van
  den Berg (BSD 3-Clause). Islet's helper (`MediaBridge/`) is its own implementation.
- **Windows above the Lock Screen**: a SkyLight space at the notification-centre-at-lock level. Approach from
  [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) by Lakr233 (MIT). Islet's `LockScreenSpace` is its own
  implementation.

## The website

`site/` ships one third-party work, unchanged: the [Inter](https://rsms.me/inter/) typeface
(`site/assets/fonts/`), by Rasmus Andersson, SIL Open Font License 1.1 (`site/assets/fonts/LICENSE-Inter.txt`),
used where SF Pro is not available. The page's stylesheet is adapted from the Pli website, by the same author.

The website's pictures of macOS (the desktop and its wallpaper, the Dock's icons, the menu bar, the arrow cursor, a
TextEdit window) are screenshots of Apple's software, shown to illustrate Islet running on it. They belong to Apple.
