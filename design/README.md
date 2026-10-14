# Design

One design system, two apps. The iPhone app and myhutch.app both draw their colors, type and spacing from the same source, so the brand never drifts between them.

| File | What it is |
|------|-----------|
| [tokens.json](tokens.json) | **Source of truth.** Colors today; type, spacing and corner radius to come. |
| [brand.md](brand.md) | The logo: a door left ajar, carved into the "h." Values, rules, rejected directions. |
| [explorations/](explorations/) | Images from each logo round, kept so mistakes aren't repeated. |

## How the apps use it

- **iOS:** tokens become a generated Swift file (colors in the asset catalog, constants for spacing and type) in `apps/ios`.
- **Web:** tokens become CSS custom properties in `apps/web`.
- Generation is added when the first app needs it (M0 for iOS, W1 for web). Until then, change values here, never in an app.

## Status

Direction chosen; final wordmark not yet drawn. Next: draw it by hand, then extend `tokens.json` with type, spacing and radius derived from it.
