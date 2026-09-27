# Third-party notices

Islet contains no third-party code. Two techniques it uses were learned from open source projects, credited here:

- **Now playing on macOS 15.4 and later**: running a helper library inside `/usr/bin/perl`, which macOS entitles to
  read MediaRemote. Approach from [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) by Jonas van
  den Berg (BSD 3-Clause). Islet's helper (`MediaBridge/`) is its own implementation.
- **Windows above the Lock Screen**: a SkyLight space at the notification-centre-at-lock level. Approach from
  [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) by Lakr233 (MIT). Islet's `LockScreenSpace` is its own
  implementation.
