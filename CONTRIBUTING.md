# Contributing to Islet

Thank you for helping. A few principles keep Islet what it is.

## Principles

- **Light.** Nothing polls when nothing changes. Prefer notifications (Core Audio, IOKit, EventKit) over timers, and
  animations that run in the render server over per-frame work in the app. Measure with `scripts/bench.sh <pid>`
  before and after a change that could cost memory or processor time.
- **Native.** AppKit and Core Animation for the island, SwiftUI for its content. No web views.
- **Private.** No network calls, no analytics. Anything sensitive stays in memory.
- **Tested rules.** Behaviour that can be expressed without AppKit belongs in `IsletCore`, with tests.
- **Clean-room.** Islet is MIT licensed. Do not copy code from projects under other licences, including GPL notch apps.

## Workflow

1. `scripts/build.sh` and `swift test --package-path Packages/IsletKit` must pass without warnings.
2. User-facing strings go through the string catalogs (`Localizable.xcstrings`), in English, with a French
   translation when you can.
3. One change per pull request, with a screenshot or a short video for anything visible.

## Where things live

See the table in the [README](README.md#build-from-source).
