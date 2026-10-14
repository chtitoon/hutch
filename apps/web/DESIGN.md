# How myhutch.app uses the design tokens

Values live in [`design/tokens.json`](../../design/tokens.json) and nowhere else. `npm run tokens` turns them into `src/styles/tokens.css` (`--color-ink`, `--space-6`, …); `site.css` and the components use only those variables. This page names tokens, never values, so it can't drift.

## Rules

- **No hard-coded colors.** Every color is a `--color-*` variable. A shadow uses `color-mix()` on a token (the phone's shadow is ink at 18%). If a design needs a color that isn't a token, add the token to `tokens.json` first (and to D15's list), or map it to the nearest existing role.
- **Spacing from the scale.** Layout gaps and padding use `--space-*` (the name is the multiple of 4px). Small component internals (badge padding, list-row padding) and device geometry (the phone's corner radii) are local to the component.
- **Corners:** `radius-sm` for inputs and thumbnails, `radius-md` for cards, `radius-lg` for large panels, `radius-pill` for pills and badges.
- **Fonts:** `font-display` for headings, the wordmark and numerals (weights `bold`, `medium`); `font-text` for everything else (`regular`, `medium`, `semibold`). Both are self-hosted from `@fontsource` packages imported in `Base.astro`. Never link a font CDN.
- **Light only, for now.** There are no dark-mode tokens, so pages declare `color-scheme: light` and render the same in dark mode. Add dark roles to `tokens.json` before styling dark mode; don't invert colors ad hoc.

## Contrast

| Text | On | Use |
|------|----|-----|
| `ink` | `background`, `surface`, `surface-sunken` | Headings, primary text |
| `ink-muted` | `background`, `surface`, `surface-sunken` | Body copy, card text, planned badges |
| `ink-subtle` | `background`, `surface` | Captions, metadata, footer |
| `sage` | `background`, `surface` | Eyebrows and small labels only (semibold) |
| `on-sage-tint` | `sage-tint` | Positive badges ("At launch") |
| `background` | `ink` | The status pill |
| `on-deep`, `on-deep-muted` | `deep` | The privacy band |

- **`accent` (brass) is never text on a light surface.** It's for the pill's dot, numerals on `deep` and small fills.
- Focus ring: `sage` on light surfaces, `accent` inside the `deep` band.

## Sections (landing page)

| Section | Background | Notes |
|---------|-----------|-------|
| Header | `background` | House glyph (interim mark, #9) + wordmark; nav links in `ink`, hover `sage` |
| Hero | `background` | `sage` eyebrow, display headline, `ink-muted` lede, status pill, phone mockup |
| Privacy band (`#privacy`) | `deep` | Title `on-deep`, body `on-deep-muted`, `deep-rule` divider, `accent` numerals |
| How it grows | `background` | Launch card: `surface`, solid, `border` shadow. Planned cards: no fill, dashed `border-dashed` |
| Closing card | `surface-sunken`, `radius-lg` | Headline + status pill |
| Footer | `background`, `border` top rule | `ink-subtle` text, `ink` links |

Text pages (privacy, support, 404) use the same header and footer, a narrow column, display-font headings and `ink-muted` body text with `ink` for bold.

## Components

| Component | What it is |
|-----------|-----------|
| `AppStoreLink.astro` | The status pill (`ink` fill, `background` text, `accent` dot). Becomes the App Store link once Hutch is listed. |
| `PhoneMockup.astro` | The inventory screen illustration. The screen is `surface`, the search field `background`, and item swatches cycle through `surface-sunken`, `sage-tint`, `border` and `background`. |
| `Door.astro` | Line-drawn door: `closed` (in `ink`), `ajar` and `out` (in `ink-subtle` on planned cards). Draws in `currentColor`. |
| `HouseGlyph.astro` | Interim mark beside the wordmark, in `currentColor`. Replaced by the final logo (#9). |
