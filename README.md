# Islet

An open source Dynamic Island for the Mac notch. Native Swift and SwiftUI, light on memory, MIT licensed.

## Status

Early work. The island opens and closes in the notch: rest the pointer on it, click it, or swipe down with two
fingers; move away or swipe up to close. Right-click it to quit.

## Build

Requirements: macOS 14 or later, Xcode 26, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
scripts/build.sh            # Debug build, prints the path of Islet.app
scripts/build.sh Release
swift test --package-path Packages/IsletKit
```

## Layout

- `App/`: the application entry point.
- `Packages/IsletKit/Sources/IsletCore`: notch geometry, the island's outline and the rules that open and close it.
  No AppKit, fully tested.
- `Packages/IsletKit/Sources/IsletShell`: the panel, the Core Animation drawing and the SwiftUI content.

## License

MIT. Islet is not affiliated with Apple.
