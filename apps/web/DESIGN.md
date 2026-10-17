# Design on myhutch.app

The values, color roles, type levels and rules live in the root [DESIGN.md](../../DESIGN.md); read it first. This page covers only how the website applies them. It names tokens, never values, so it can't drift.

## From DESIGN.md to CSS

`npm run tokens` turns DESIGN.md's front matter into `src/styles/tokens.css`. `site.css` and the components use only those variables:

| In DESIGN.md | In CSS |
|--------------|--------|
| `colors.ink`, `colors.ink-dark` | `--color-ink`, overridden under `prefers-color-scheme: dark` |
| `typography.headline-lg`, `headline-lg-wide` | `font: var(--type-headline-lg); letter-spacing: var(--type-headline-lg-tracking);`, with the wide size from `breakpoint-wide` up |
| the headline and body families, and their weights | `--font-display`, `--font-text`, `--font-weight-regular` … `bold` (for emphasis inside text, such as `strong`) |
| `rounded.md` | `--radius-md` |
| `spacing.6`, `spacing.page-width` | `--space-6`, `--layout-page-width` |

Always set `font` and `letter-spacing` together: `font` doesn't reset letter spacing, so a level's tracking would otherwise be inherited from the parent. Pages declare `color-scheme: light dark` and follow the system setting.

## Enforced by `npm test`

- **`npm run lint:design`** lints the root DESIGN.md: broken references, contrast for every pair under `components` (4.5:1 for text, 3:1 for `-graphic` marks), unused tokens, and a `-dark` twin for every pair whose colors change in dark mode.
- **`npm run check:css`** checks the site's CSS, `<style>` blocks, `style=""` attributes and SVG color attributes in `src/` and `og/card.html`. It fails on a raw color (hex, `rgb()`, `hsl()`, a named color; `color-mix()` only over `var(--color-*)` and `transparent`), on a `var(--…)` that `tokens.css` doesn't define, on type set without a `--type-*` level or a font family other than `--font-*`, on an external font or stylesheet, and on raw px in `margin`, `padding` or `gap` except the cases below. Each failure names the file, line, rule and the token to use instead.

## Spacing exceptions

Layout gaps and padding come from `--space-*`. These cases are local to a component and stay in px; `check:css` reads this table, so a new exception means a new row with its reason.

| File | Selector | Property | Why |
|------|----------|----------|-----|
| `src/styles/site.css` | `.pill` | `padding` | The pill's side inset is sized to its 52px height, not to the page rhythm. |
| `src/styles/site.css` | `.badge` | `padding` | Small component internals: a 13px label in a tight capsule. |
| `src/styles/site.css` | `.phone-screen` | `gap` | Device geometry: the mockup draws the iPhone screen at phone scale. |
| `src/styles/site.css` | `.phone-list` | `gap` | Device geometry: iOS list spacing at phone scale. |
| `src/styles/site.css` | `.phone-list li` | `gap` | Device geometry: iOS list-row metrics at phone scale. |
| `src/styles/site.css` | `.phone-list li` | `padding` | Device geometry: iOS list-row metrics at phone scale. |

## Fonts

Both families are self-hosted from pinned `@fontsource` packages imported in `Base.astro` and bundled into `dist/`, so no request leaves myhutch.app (D15). Never link a font CDN or a remote stylesheet. Fontsource registers the display font as "Bricolage Grotesque Variable", which is why that name leads the display family in DESIGN.md.

Each web font is followed by a "Fallback" face, declared in `site.css`: Arial (Liberation Sans on Linux) sized like the web font, so nothing moves when the web fonts arrive (#36). Its `src` is only `local()`, the one kind of `@font-face` that `check:css` allows. Changing a font means recomputing its fallback (see the comment in `site.css`).

## Sections (landing page)

| Section | Background | Notes |
|---------|-----------|-------|
| Header | `background` | The logo (mark in `sage`, wordmark in `ink`); nav links `body-sm` in `ink`, hover `sage` |
| Hero | `background` | `label-caps` eyebrow in `sage`, `headline-display` headline, `body-lg` lede in `ink-muted`, status pill, phone mockup |
| Privacy band (`#privacy`) | `deep` | `headline-lg` title in `on-deep`, `body-lg` intro in `on-deep-muted`, `deep-rule` divider, `headline-sm` numerals in `accent`, `title-md` point titles |
| Where we’re heading | `background` | Launch card: `surface`, solid, `border` shadow. Planned cards: no fill, dashed `border-dashed`. `headline-md` titles, `body-md` text |
| Closing card | `surface-sunken`, `radius-lg` | `headline-lg` headline + status pill |
| Footer | `background`, `border` top rule | The wordmark in `headline-sm`, `body-sm` text in `ink-subtle`, `ink` links |

Text pages (privacy, support, 404) use the same header and footer, a `layout-prose-width` column, `headline-lg` and `headline-md` headings, and `body-md` text in `ink-muted` with `ink` for bold.

## Components

| Component | What it is |
|-----------|-----------|
| `AppStoreLink.astro` | The status pill (`ink` fill, `background` text, `label-lg`, `marker` dot). Becomes the App Store link once Hutch is listed. |
| `PhoneMockup.astro` | The inventory screen illustration. The frame and its shadow are `device` (dark in both modes). The screen is `surface`, the search field `background`, and item swatches cycle through `surface-sunken`, `sage-tint`, `border` and `background`. |
| `StageIcon.astro` | 22px line icon beside each roadmap badge: `private` (house), `lend` (two people), `sell` (tag), matching the SF Symbols the app will use. `ink-muted` on the launch card, `ink-subtle` on planned cards. Draws in `currentColor`. |
| `Logo.astro` | The logo as inline SVG, traced from `design/light/logo.svg`: house-with-keyhole mark in `sage`, "hutch" in `ink`, so it follows light and dark mode. |

## Link preview

When someone shares a myhutch.app link, apps show `public/og.png` (1200×630), set through the Open Graph tags in `Base.astro`. The card is a real page, [`og/card.html`](og/card.html), using the same tokens and self-hosted fonts as the site, so it can't drift from the brand (D16).

- **Forest** (`deep`) background; the logo with its mark in `sage-on-deep` and wordmark in `on-deep`; headline (`preview-headline`) in `on-deep`, the line below (`preview-lede`) in `on-deep-muted`.
- **The light:** a narrow `accent` gap of even width, running from the top edge to the floor (a door seen up close, cropped by the frame), with a soft glow and a wedge of light on the floor that leaves the gap at its full width and widens toward the viewer. (A sliver tapering to a hairline at the floor was tried first: the floor light fanned out of a single point and read as a spotlight or a blade, not a door.) Light through a door left ajar, shown as light rather than drawn as a door: home, private, and warm inside. Its geometry is fixed pixels on a fixed-size image.
- `npm run og` re-renders the PNG in headless Chromium. `npm test` fails if the card, the tokens or the fonts changed since the last render (`og/card.sha256`), so a token change can't leave a stale image. Comments in `tokens.css` don't count.

## Favicon

`public/favicon.svg` is the house-and-keyhole mark from [`design/light/icon.svg`](../../design/light/icon.svg), without its background square, in `sage` (the dark `sage` in dark mode). `npm run tokens` generates it with the CSS variables, and `npm test` fails if it is stale.
