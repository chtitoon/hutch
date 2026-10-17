# How myhutch.app uses the design tokens

Values live in [`design/tokens.json`](../../design/tokens.json) and nowhere else. `npm run tokens` turns them into `src/styles/tokens.css` (`--color-ink`, `--space-6`, …); `site.css` and the components use only those variables. This page names tokens, never values, so it can't drift.

## Rules

- **No hard-coded colors.** Every color is a `--color-*` variable. A shadow uses `color-mix()` on a token (the phone's shadow is ink at 18%). If a design needs a color that isn't a token, add the token to `tokens.json` first (and to D15's list), or map it to the nearest existing role.
- **Spacing from the scale.** Layout gaps and padding use `--space-*` (the name is the multiple of 4px). Small component internals (badge padding, list-row padding) and device geometry (the phone's corner radii) are local to the component.
- **Corners:** `radius-sm` for inputs and thumbnails, `radius-md` for cards, `radius-lg` for large panels, `radius-pill` for pills and badges.
- **Fonts:** `font-display` for headings, the wordmark and numerals (weights `bold`, `medium`); `font-text` for everything else (`regular`, `medium`, `semibold`). Both are self-hosted from `@fontsource` packages imported in `Base.astro`. Never link a font CDN.
- **Light and dark follow the system.** The `color-dark` group in `tokens.json` gives dark values for the color roles; `npm run tokens` emits them under `prefers-color-scheme: dark`, and pages declare `color-scheme: light dark`. Roles it leaves out (`deep`, `on-deep*`, `deep-rule`, `accent`) are the same in both modes. To change a dark color, edit its token; never invert colors ad hoc or add per-component dark rules.

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
| Header | `background` | The logo (mark in `sage`, wordmark in `ink`); nav links in `ink`, hover `sage` |
| Hero | `background` | `sage` eyebrow, display headline, `ink-muted` lede, status pill, phone mockup |
| Privacy band (`#privacy`) | `deep` | Title `on-deep`, body `on-deep-muted`, `deep-rule` divider, `accent` numerals |
| Where we’re heading | `background` | Launch card: `surface`, solid, `border` shadow. Planned cards: no fill, dashed `border-dashed` |
| Closing card | `surface-sunken`, `radius-lg` | Headline + status pill |
| Footer | `background`, `border` top rule | `ink-subtle` text, `ink` links |

Text pages (privacy, support, 404) use the same header and footer, a narrow column, display-font headings and `ink-muted` body text with `ink` for bold.

## Components

| Component | What it is |
|-----------|-----------|
| `AppStoreLink.astro` | The status pill (`ink` fill, `background` text, `accent` dot). Becomes the App Store link once Hutch is listed. |
| `PhoneMockup.astro` | The inventory screen illustration. The frame and its shadow are `device` (dark in both modes). The screen is `surface`, the search field `background`, and item swatches cycle through `surface-sunken`, `sage-tint`, `border` and `background`. |
| `StageIcon.astro` | 22px line icon beside each roadmap badge: `private` (house), `lend` (two people), `sell` (tag), matching the SF Symbols the app will use. `ink-muted` on the launch card, `ink-subtle` on planned cards. Draws in `currentColor`. |
| `Logo.astro` | The logo as inline SVG, traced from `design/light/logo.svg`: house-with-keyhole mark in `sage`, "hutch" in `ink`, so it follows light and dark mode. |

## Link preview

When someone shares a myhutch.app link, apps show `public/og.png` (1200×630), set through the Open Graph tags in `Base.astro`. The card is a real page, [`og/card.html`](og/card.html), using the same tokens and self-hosted fonts as the site, so it can't drift from the brand.

- **Forest** (`deep`) background; the logo with its mark in `sage-on-deep` and wordmark in `on-deep`; headline in `on-deep`, the line below in `on-deep-muted`.
- **The light:** a tall `accent` sliver, hairline at the floor and wider at the top, with a soft glow and a spill of light across the floor. Light through a door left ajar, shown as light rather than drawn as a door: home, private, and warm inside.
- `npm run og` re-renders the PNG in headless Chromium. `npm test` fails if the card, the tokens or the fonts changed since the last render (`og/card.sha256`), so a token change can't leave a stale image.

## Favicon

`public/favicon.svg` is the house-and-keyhole mark from [`design/light/icon.svg`](../../design/light/icon.svg), without its background square, in `sage` (the dark `sage` in dark mode). `npm run tokens` generates it with the CSS variables, and `npm test` fails if it is stale.
