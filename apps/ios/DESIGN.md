# Design in the iPhone app

The values, color roles, type levels and rules live in the root [DESIGN.md](../../DESIGN.md); read it first. This page covers how the SwiftUI app applies them. It landed with [H1](../../ROADMAP.md#h1), the first bet with screens.

## Standard components first

Use SwiftUI's own controls, navigation, lists, sheets and SF Symbols before drawing anything custom: they come with Dynamic Type, dark mode, accessibility and the system's feel for free. Tokens tint and set type on standard components; they don't replace them. Primary actions (add an item, scan) sit within one-handed reach.

## Colors and dark mode

Each color role becomes a `Palette` color in the generated `Tokens.swift`, with its `-dark` token as the dark appearance (`ink` and `ink-dark` become one `Palette.ink`). A role without a `-dark` twin has one value in both appearances. Views use the roles, never a value: `Palette.ink`, not `Color(red:green:blue:)`. Dark mode follows the system; there is no in-app theme switch.

Why `Palette` and not `Color.ink`: some role names clash with SwiftUI's own (`.background`, `.primary`), so the roles live in their own namespace. Why Swift and not the asset catalog: one generated file is easier to check for staleness and to review.

## Type and Dynamic Type

Each type level becomes a `Typography` font: the Dynamic Type text style closest to its iPhone size (the base level, not `-wide`), at its weight, so text scales with the user's setting. For example, `headline-md` (26px) becomes `.title`, `body-md` (16px) `.callout`, and `caption` (13px) `.footnote`. `-wide` levels and `preview-*` levels are web-only.

For now the app uses the system font. Bundling Bricolage Grotesque and Instrument Sans (scaled with `relativeTo:`) is a later change; the web serves them as subsetted WOFF2, which iOS can't load.

## Spacing and corners

The spacing scale and `rounded` values become constants (`Spacing.s6`, `Radius.md`) in the same generated file. Prefer the system's own spacing (stacks' default spacing, list insets) where a standard component already has one.

## Generated, never hand-edited

`make tokens` in `apps/ios` reads DESIGN.md's front matter and writes `Hutch/Generated/Tokens.swift` (`Palette`, `Typography`, `Spacing`, `Radius`), the way `npm run tokens` generates CSS for the website. The file is marked as generated; change DESIGN.md and regenerate.

## Enforcement

As on the web, `make test` fails when the app bypasses the tokens:

- **Generated files are current:** `make tokens` in check mode fails if DESIGN.md changed without regenerating.
- **`lint.sh`** bans raw `Color(...)` and `UIColor(...)` literals and hard-coded sizes in `.font(.system(size:))`, `.padding(<number>)`, `spacing: <number>` and `cornerRadius: <number>`, outside the generated file. It's a grep, so it needs nothing installed; it becomes a SwiftLint rule if it grows.
- **Snapshot tests** in light, dark and a large Dynamic Type size (D11) catch any visual change.
