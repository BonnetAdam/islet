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

`site/` ships two third-party works, unchanged:

- [three.js](https://threejs.org) r160 (`site/js/vendor/three.min.js`), by the three.js authors, MIT License. It
  draws the AirPods in the demo.
- [Geist and Geist Mono](https://vercel.com/font) (`site/assets/fonts/`), by Vercel, SIL Open Font License 1.1.
