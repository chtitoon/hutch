# Design in the iPhone app

The values, color roles, type levels and rules live in the root [DESIGN.md](../../DESIGN.md); read it first. This page covers how the SwiftUI app applies them. It landed with [H1](../../ROADMAP.md#h1), the first bet with screens.

## Standard components first

Use SwiftUI's own controls, navigation, lists, sheets and SF Symbols before drawing anything custom: they come with Dynamic Type, dark mode, accessibility and the system's feel for free. Tokens tint and set type on standard components; they don't replace them. Primary actions (add an item, scan) sit within one-handed reach.

## Colors and dark mode

Each color role becomes a `Palette` color in the generated `Tokens.swift`, with its `-dark` token as the dark appearance (`ink` and `ink-dark` become one `Palette.ink`). A role without a `-dark` twin has one value in both appearances. Views use the roles, never a value: `Palette.ink`, not `Color(red:green:blue:)`. Dark mode follows the system; there is no in-app theme switch.

Why `Palette` and not `Color.ink`: some role names clash with SwiftUI's own (`.background`, `.primary`), so the roles live in their own namespace. Why Swift and not the asset catalog: one generated file is easier to check for staleness and to review.

## Type and Dynamic Type

Each type level becomes a `Typography` font in its brand family, at its iPhone size and weight, scaling with the Dynamic Type text style closest to that size (`relativeTo:`). For example, `headline-md` (26px) scales like `.title`, `body-md` (16px) like `.callout`, and `caption` (13px) like `.footnote`. `-wide` levels and `preview-*` levels are web-only.

- **The fonts:** Bricolage Grotesque and Instrument Sans, as Google Fonts' variable TTFs in `Hutch/Fonts/`, each with its OFL license. The web's subsetted WOFF2 files are its own.
- **Registered at launch** by `BrandFonts`, which also sets navigation titles in them (Bricolage for large titles), since SwiftUI styles those only through UIKit.
- **Body text** defaults to `body-lg` for a whole screen through `.brand()`, which also sets the sage tint.
- **Section headers** are an `Eyebrow`: `label-caps`, uppercase, tracked, in `sage`.

## Components

- **Chips** pick one option, such as a room: an `ink` pill with `background` text when picked (the `pill` pair), outlined in `border` when not.
- **The primary action** (add an item, save) is `deep` forest with `on-deep` text, the website's band colors.
- **The privacy badge** ("On this phone only") appears once, on Home, with the logo's house-and-keyhole mark, never a padlock. Repeating it on every screen is noise.

## Spacing and corners

The spacing scale and `rounded` values become constants (`Spacing.s6`, `Radius.md`) in the same generated file. Prefer the system's own spacing (stacks' default spacing, list insets) where a standard component already has one.

## Generated, never hand-edited

`make tokens` in `apps/ios` reads DESIGN.md's front matter and writes `Hutch/Generated/Tokens.swift` (`Palette`, `Typography`, `Spacing`, `Radius`), the way `npm run tokens` generates CSS for the website. It also draws the app icon from the logo's mark.

- **Not committed,** like the Xcode project: `make setup`, `test`, `run` and `snapshots` write both fresh before building.
- **Change DESIGN.md,** never the generated files. Review a design change in DESIGN.md, and in the snapshot images it moves.

## Enforcement

As on the web, `make test` fails when the app bypasses the tokens:

- **`lint.sh`** bans raw `Color(...)` and `UIColor(...)` literals and hard-coded sizes in `.font(.system(size:))`, `.padding(<number>)`, `spacing: <number>` and `cornerRadius: <number>`, outside the generated file. It's a grep, so it needs nothing installed; it becomes a SwiftLint rule if it grows.
- **Snapshot tests** in light, dark and a large Dynamic Type size (D11) catch any visual change.
