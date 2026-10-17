# Design

One design system, two apps. The iPhone app and myhutch.app both draw their colors, type and spacing from the same source, so the brand never drifts between them.

| File | What it is |
|------|-----------|
| [tokens.json](tokens.json) | **Source of truth.** Colors, fonts and weights, corner radius and spacing (D15). |
| [brand.md](brand.md) | The logo: a house with a keyhole, beside the "hutch" wordmark. Values, rules, rejected directions. |
| [explorations/](explorations/) | Images from each logo round, kept so mistakes aren't repeated. |

## How the apps use it

- **iOS:** tokens become a generated Swift file (colors in the asset catalog, constants for spacing and type) in `apps/ios`.
- **Web:** tokens become CSS custom properties in `apps/web` (`npm run tokens`).
- iOS generation is added in M0. Change values here, never in an app.

## Status

Logo chosen (D17): `light/logo.svg` and `dark/logo.svg`; the app icon is `light/icon.svg`, the mark alone. Palette, type, radius and spacing are proposed in D15, taken from the landing-page design. On the web, see [apps/web/DESIGN.md](../apps/web/DESIGN.md) for how they're applied.
