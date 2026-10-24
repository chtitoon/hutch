# Design on myhutch.app

The values, color roles, type levels and rules live in the root [DESIGN.md](../../DESIGN.md); read it first. This page covers only how the website applies them. It names tokens, never values, so it can't drift.

## From DESIGN.md to CSS

`npm run tokens` turns DESIGN.md's front matter into `src/styles/tokens.css`. `site.css` and the components use only those variables. Examples:

- **Colors:** `colors.ink` and `colors.ink-dark` become `--color-ink`, overridden under `prefers-color-scheme: dark`.
- **Type levels:** `typography.headline-lg` becomes `font: var(--type-headline-lg); letter-spacing: var(--type-headline-lg-tracking);`.
- **Wide type:** from `breakpoint-wide` up, the same variables take `headline-lg-wide`'s values.
- **Families:** the headline and body families become `--font-display` and `--font-text`.
- **Weights:** `--font-weight-regular` … `bold` (bold for emphasis inside text, such as `strong`).
- **Radius:** `rounded.md` becomes `--radius-md`.
- **Spacing:** `spacing.6` and `spacing.page-width` become `--space-6` and `--layout-page-width`.

Always set `font` and `letter-spacing` together: `font` doesn't reset letter spacing, so a level's tracking would otherwise be inherited from the parent. Pages declare `color-scheme: light dark` and follow the system setting.

## Enforced by `npm test`

- **`npm run design:lint:md`** lints the root DESIGN.md: broken references, contrast for every pair under `components` (4.5:1 for text, 3:1 for `-graphic` marks), unused tokens, and a `-dark` twin for every pair whose colors change in dark mode.
- **`npm run design:lint:css`** checks the site's CSS, `<style>` blocks, `style=""` attributes and SVG color attributes in `src/` and `og/card.html`. It fails on a raw color (hex, `rgb()`, `hsl()`, a named color; `color-mix()` only over `var(--color-*)` and `transparent`), on a `var(--…)` that `tokens.css` doesn't define, on type set without a `--type-*` level or a font family other than `--font-*`, on an external font or stylesheet, and on raw px in `margin`, `padding` or `gap` except the cases below. Each failure names the file, line, rule and the token to use instead.

## Spacing exceptions

Layout gaps and padding come from `--space-*`. These cases are local to a component and stay in px.

`design:lint:css` reads this list. A new exception is a new bullet, in the form ``- `selector` `property`: why``, under a ``### `file` `` heading.

### `src/styles/site.css`

- `.pill` `padding`: the pill's side inset is sized to its 52px height, not to the page rhythm.
- `.badge` `padding`: small component internals, a 13px label in a tight capsule.
- `.phone-screen` `gap`: device geometry; the mockup draws the iPhone screen at phone scale.
- `.phone-list` `gap`: device geometry; iOS list spacing at phone scale.
- `.phone-list li` `gap`: device geometry; iOS list-row metrics at phone scale.
- `.phone-list li` `padding`: device geometry; iOS list-row metrics at phone scale.

## Fonts

Both families are self-hosted from pinned `@fontsource` packages and bundled into `dist/`, so no request leaves myhutch.app (D15). Never link a font CDN or a remote stylesheet. `src/styles/fonts.css` declares one `@font-face` per weight, pointing at the package files, and `Base.astro` preloads the same files. After `astro build`, `fonts.mjs` cuts each one down to the characters it draws on the built pages (see "Fonts" in `PERFORMANCE.md`). Setting either family at another weight means adding its `@font-face` and preload. The display font keeps Fontsource's name, "Bricolage Grotesque Variable", which is why that name leads the display family in DESIGN.md. The link-preview card still uses the full packages.

Each web font is followed by a "Fallback" face, declared in `site.css`: Arial (Liberation Sans on Linux) sized like the web font, so a page that misses the web fonts keeps the same layout (#36). The web fonts are `font-display: optional` and preloaded: used if they arrive within about 100 ms, never swapped in after text is drawn (W4). Its `src` is only `local()`, the one kind of `@font-face` that `design:lint:css` allows. Changing a font means recomputing its fallback (see the comment in `site.css`).

## Sections (landing page)

### Header

- Background: `background`.
- Logo: mark in `sage`, wordmark in `ink`.
- Nav links: `body-sm` in `ink`, hover `sage`.

### Hero

- Background: `background`.
- Eyebrow: `label-caps` in `sage`.
- Headline: `headline-display`.
- Lede: `body-lg` in `ink-muted`.
- Then the status pill and the phone mockup.

### Privacy band (`#privacy`)

- Background: `deep`.
- Title: `headline-lg` in `on-deep`.
- Intro: `body-lg` in `on-deep-muted`.
- Divider: `deep-rule`.
- Numerals: `headline-sm` in `accent`.
- Point titles: `title-md`.

### Where we’re heading

- Background: `background`.
- Launch card: `surface`, solid, `border` shadow.
- Planned cards: no fill, dashed `border-dashed`.
- Titles: `headline-md`.
- Text: `body-md`.

### Closing card

- Background: `surface-sunken`, corners `radius-lg`.
- Content: `headline-lg` headline and the status pill.

### Footer

- Background: `background`, with a `border` top rule.
- Wordmark: `headline-sm`.
- Text: `body-sm` in `ink-subtle`.
- Links: `ink`.

### Space between sections

Space between sections scales with the screen width (`clamp()` over `vw`): `spacing.16` on an iPhone, up to `spacing.28` (`spacing.30` around the roadmap and closing card) on a wide screen. Fixed desktop spacing left a phone scrolling through empty bands. The roadmap cards and the closing card belong together, so the gap between them is smaller, at most `spacing.16`.

## Text pages

Text pages (privacy, support, 404) use the same header and footer, a `layout-prose-width` column, `headline-lg` and `headline-md` headings, and `body-md` text in `ink-muted` with `ink` for bold.

## Components

### `AppStoreLink.astro`

- The status pill: `ink` fill, `background` text, `label-lg`, `marker` dot.
- Becomes the App Store link once Hutch is listed.

### `PhoneMockup.astro`

- The inventory screen illustration.
- Frame and its shadow: `device` (dark in both modes).
- Screen: `surface`.
- Search field: `background`.
- Item swatches cycle through `surface-sunken`, `sage-tint`, `border` and `background`.

### `StageIcon.astro`

- A 22px line icon beside each roadmap badge, drawn in `currentColor`.
- Icons: `private` (house), `lend` (two people), `sell` (tag), matching the SF Symbols the app will use.
- Color: `ink-muted` on the launch card, `ink-subtle` on planned cards.

### `Logo.astro`

- The logo as inline SVG, traced from `design/light/logo.svg`.
- House-with-keyhole mark in `sage`, "hutch" in `ink`, so it follows light and dark mode.

## Link preview

When someone shares a myhutch.app link, apps show `public/og.png` (1200×630), set through the Open Graph tags in `Base.astro`. The card is a real page, [`og/card.html`](og/card.html), using the same tokens and self-hosted fonts as the site, so it can't drift from the brand (D16).

- **Forest** (`deep`) background; the logo with its mark in `sage-on-deep` and wordmark in `on-deep`; headline (`preview-headline`) in `on-deep`, the line below (`preview-lede`) in `on-deep-muted`.
- **The light:** a narrow `accent` gap of even width, running from the top edge to the floor (a door seen up close, cropped by the frame), with a soft glow and a wedge of light on the floor that leaves the gap at its full width and widens toward the viewer. (A sliver tapering to a hairline at the floor was tried first: the floor light fanned out of a single point and read as a spotlight or a blade, not a door.) Light through a door left ajar, shown as light rather than drawn as a door: home, private, and warm inside. Its geometry is fixed pixels on a fixed-size image.
- `npm run og` re-renders the PNG in headless Chromium. `npm test` fails if the card, the tokens or the fonts changed since the last render (`og/card.sha256`), so a token change can't leave a stale image. Comments in `tokens.css` don't count.

## Favicon

`public/favicon.svg` is the house-and-keyhole mark from [`design/light/icon.svg`](../../design/light/icon.svg), without its background square, in `sage` (the dark `sage` in dark mode). `npm run tokens` generates it with the CSS variables, and `npm test` fails if it is stale.
