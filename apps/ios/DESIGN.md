# Design in the iPhone app

The values, color roles, type levels and rules live in the root [DESIGN.md](../../DESIGN.md); read it first. This page covers how the SwiftUI app applies them. Most of it lands with [H1](../../ROADMAP.md#h1), the first bet with screens; until then it's the plan.

## Standard components first

Use SwiftUI's own controls, navigation, lists, sheets and SF Symbols before drawing anything custom: they come with Dynamic Type, dark mode, accessibility and the system's feel for free. Tokens tint and set type on standard components; they don't replace them. Primary actions (add an item, scan) sit within one-handed reach.

## Colors and dark mode

Each color role becomes a named color in the asset catalog, with its `-dark` token as the dark appearance (`ink` and `ink-dark` become one `ink` color). A role without a `-dark` twin has one value in both appearances. Views use the roles, never a value: `Color.ink`, not `Color(red:green:blue:)`. Dark mode follows the system; there is no in-app theme switch.

## Type and Dynamic Type

Each type level maps to the Dynamic Type text style closest to its iPhone size (the base level, not `-wide`), so text scales with the user's setting: `headline-display` → `.largeTitle`, `headline-md` → `.title2`, `body-md` → `.body`, `caption` → `.caption`, and so on. Custom fonts scale with `relativeTo:`. `-wide` levels and `preview-*` levels are web-only.

## Spacing and corners

The spacing scale and `rounded` values become constants (`Spacing.s6`, `Radius.md`). Prefer the system's own spacing (stacks' default spacing, list insets) where a standard component already has one.

## Generated, never hand-edited

`make tokens` in `apps/ios` will read DESIGN.md's front matter and generate the asset-catalog colors and a Swift file of type, spacing and radius constants, the way `npm run tokens` generates CSS for the website. Generated files are marked as such; change DESIGN.md and regenerate.

## Enforcement (planned for H1)

As on the web, `make test` will fail when the app bypasses the tokens:

- **Generated files are current:** `make tokens` in check mode fails if DESIGN.md changed without regenerating.
- **A SwiftLint custom rule** bans raw `Color(...)` and `UIColor(...)` literals (RGB, hex, named system colors used as brand colors) and hard-coded sizes in `.font(.system(size:))`, `.padding(<number>)`, `spacing: <number>` and `cornerRadius: <number>`, outside the generated files.
- **Snapshot tests** in light, dark and a large Dynamic Type size (D11) catch any visual change.
