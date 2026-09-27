# Islet brand

**Name**: Islet. A small island: the Dynamic Island, on a Mac.
**Tagline**: The notch, made useful. (FR: L'encoche, enfin utile.)

## Icon

A slab of polished black glass with a notch-shaped window at its top edge, lit in coral from within: the light rises
from the bottom of the window and spills onto the glass below it. Drawn by `scripts/glow-icon.swift` at every size of
the asset catalog (`App/Assets.xcassets/AppIcon.appiconset`), and at 1024 px in `icon-1024.png`.

```sh
swiftc -O -o /tmp/glow brand/scripts/glow-icon.swift && /tmp/glow notch brand/icon-1024.png 1024
```

## Colour

| Token | Hex | Use |
|---|---|---|
| Night | `#05080A` | The island, dark surfaces |
| Coral | `#FF7A59` | The accent: Islet's own marks in the island, links, highlights |
| Ember | `#E2472D` | Deep coral, gradients and pressed states |
| Peach | `#FFC7A8` | The brightest light in the icon and gradients |
| Ink | `#0F1B1F` | Text on light surfaces |

Semantic colours inside the island follow macOS: green `#33D666` for done and charging, orange `#FF9F0A` for waiting
and timers, red `#FF453A` for denied and low battery.

## Type

- Inside the app: the system font (SF Pro, SF Pro Rounded for the clock).
- Website: see `site/`.

## Voice

Short, concrete, calm. Say what happens. No exclamation marks, no em dashes.
