---
version: alpha
name: Hutch
description: >-
  Forest, warm grey and brass. One design system for the iPhone app and myhutch.app.
  Tokens here are the single source of truth; a color name ending in -dark is that
  role's dark-mode value, and a type level ending in -wide is its size on wide screens.

colors:
  # Primary text, the wordmark, dark pills.
  ink: "#1B2420"
  ink-dark: "#EEEDE8"
  # Body copy and secondary text on light surfaces.
  ink-muted: "#4A554F"
  ink-muted-dark: "#BAC4BD"
  # Captions, metadata, footer text, quiet line drawings.
  ink-subtle: "#55605A"
  ink-subtle-dark: "#98A39C"
  # Page and app background: warm off-white; night forest in dark mode, from the dark logo.
  background: "#F3F1EC"
  background-dark: "#152319"
  # Raised cards and screens on the background.
  surface: "#FFFFFF"
  surface-dark: "#1D2E24"
  # Recessed panels, neutral badges, the closing card.
  surface-sunken: "#E8E5DD"
  surface-sunken-dark: "#0F1A13"
  # Hairlines, dividers, card edges.
  border: "#DEDAD0"
  border-dark: "#2B3D32"
  # Dashed outlines for things that are planned but not built.
  border-dashed: "#C9C5BA"
  border-dashed-dark: "#3C5144"
  # Forest. Dark bands such as the privacy section. Same in both modes.
  deep: "#1F3A31"
  # Headings and primary text on deep.
  on-deep: "#E9EEE9"
  # Body text on deep.
  on-deep-muted: "#B4C3BA"
  # The logo's mark on deep (the link-preview card).
  sage-on-deep: "#6AAA86"
  # Dividers on deep.
  deep-rule: "#3A5A4E"
  # Brass. Fills and markers only (dots, numerals on deep); never text on a light surface.
  accent: "#D4A24C"
  # Small labels and eyebrows, link hover, the focus ring. Lighter in dark mode to keep contrast.
  sage: "#3D7961"
  sage-dark: "#6AAA86"
  # Background of positive badges.
  sage-tint: "#E2EDE7"
  sage-tint-dark: "#24402F"
  # Text on sage-tint.
  on-sage-tint: "#2C5A48"
  on-sage-tint-dark: "#B5DCC6"
  # The brass dot on the status pill. Deeper in dark mode, where the pill turns light.
  marker: "#D4A24C"
  marker-dark: "#A87A2C"
  # Hardware drawn on the page (the phone frame) and its shadow. Dark in both modes.
  device: "#1B2420"
  device-dark: "#0A120D"
  # The spec asks for a primary color: ours is ink.
  primary: "{colors.ink}"

typography:
  # Display family: Bricolage Grotesque, weights 500 and 700, optical sizing on. The web
  # self-hosts the variable font under its own name, listed first; other platforms skip it.
  # Each "Fallback" is a web-only face, Arial sized like the font, so the swap doesn't shift text.
  # Text family: Instrument Sans, weights 400, 500 and 600.
  headline-display:
    fontFamily: &display Bricolage Grotesque Variable, Bricolage Grotesque Fallback, Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif
    fontSize: 48px
    fontWeight: 700
    lineHeight: 0.96
    letterSpacing: -0.035em
  headline-display-wide:
    fontFamily: *display
    fontSize: 96px
    fontWeight: 700
    lineHeight: 0.96
    letterSpacing: -0.035em
  headline-lg:
    fontFamily: *display
    fontSize: 36px
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: -0.03em
  headline-lg-wide:
    fontFamily: *display
    fontSize: 60px
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: -0.03em
  headline-md:
    fontFamily: *display
    fontSize: 26px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: *display
    fontSize: 18px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.02em
  title-md:
    fontFamily: &text Instrument Sans, Instrument Sans Fallback, ui-sans-serif, system-ui, -apple-system, sans-serif
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.3
  body-lg:
    fontFamily: *text
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.55
  body-lg-wide:
    fontFamily: *text
    fontSize: 20px
    fontWeight: 400
    lineHeight: 1.55
  body-md:
    fontFamily: *text
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  body-sm:
    fontFamily: *text
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: *text
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.4
  label-lg:
    fontFamily: *text
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.5
  label-md:
    fontFamily: *text
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.4
  label-sm:
    fontFamily: *text
    fontSize: 13px
    fontWeight: 600
    lineHeight: 1.4
  label-caps:
    fontFamily: *text
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0.08em
  # The link-preview card is a 1200×630 image shown small, so its type is larger than the site's.
  preview-headline:
    fontFamily: *display
    fontSize: 92px
    fontWeight: 700
    lineHeight: 0.96
    letterSpacing: -0.035em
  preview-lede:
    fontFamily: *text
    fontSize: 27px
    fontWeight: 500
    lineHeight: 1.35
  preview-label:
    fontFamily: *text
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.2

rounded:
  sm: 12px
  md: 24px
  lg: 32px
  pill: 999px

spacing:
  # 4px-based scale; the name is the multiple of 4px.
  "2": 8px
  "3": 12px
  "4": 16px
  "5": 20px
  "6": 24px
  "7": 28px
  "8": 32px
  "10": 40px
  "12": 48px
  "14": 56px
  "16": 64px
  "20": 80px
  "22": 88px
  "24": 96px
  "28": 112px
  "30": 120px
  # Layout: the page column, the reading column, and where -wide type levels start.
  page-width: 1200px
  prose-width: 720px
  breakpoint-wide: 1024px

# Every text-on-background pair the design uses, so the linter checks its contrast (WCAG AA, 4.5:1).
# A pair whose colors have -dark values has a -dark twin, checked the same way.
# Names ending in -graphic are marks, not text, and need 3:1 (WCAG 1.4.11).
components:
  page-text:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink}"
  page-text-dark:
    backgroundColor: "{colors.background-dark}"
    textColor: "{colors.ink-dark}"
  page-body:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink-muted}"
  page-body-dark:
    backgroundColor: "{colors.background-dark}"
    textColor: "{colors.ink-muted-dark}"
  page-caption:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink-subtle}"
  page-caption-dark:
    backgroundColor: "{colors.background-dark}"
    textColor: "{colors.ink-subtle-dark}"
  page-label:
    backgroundColor: "{colors.background}"
    textColor: "{colors.sage}"
    typography: "{typography.label-caps}"
  page-label-dark:
    backgroundColor: "{colors.background-dark}"
    textColor: "{colors.sage-dark}"
    typography: "{typography.label-caps}"
  card-text:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
  card-text-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.ink-dark}"
  card-body:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-muted}"
  card-body-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.ink-muted-dark}"
  card-caption:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-subtle}"
  card-caption-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.ink-subtle-dark}"
  card-label:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.sage}"
    typography: "{typography.label-sm}"
  card-label-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.sage-dark}"
    typography: "{typography.label-sm}"
  sunken-text:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.ink}"
  sunken-text-dark:
    backgroundColor: "{colors.surface-sunken-dark}"
    textColor: "{colors.ink-dark}"
  badge-planned:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.pill}"
  badge-planned-dark:
    backgroundColor: "{colors.surface-sunken-dark}"
    textColor: "{colors.ink-muted-dark}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.pill}"
  badge-positive:
    backgroundColor: "{colors.sage-tint}"
    textColor: "{colors.on-sage-tint}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.pill}"
  badge-positive-dark:
    backgroundColor: "{colors.sage-tint-dark}"
    textColor: "{colors.on-sage-tint-dark}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.pill}"
  pill:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.background}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.pill}"
    height: 52px
  pill-dark:
    backgroundColor: "{colors.ink-dark}"
    textColor: "{colors.background-dark}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.pill}"
    height: 52px
  pill-marker-graphic:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.marker}"
  pill-marker-graphic-dark:
    backgroundColor: "{colors.ink-dark}"
    textColor: "{colors.marker-dark}"
  band-text:
    backgroundColor: "{colors.deep}"
    textColor: "{colors.on-deep}"
  band-body:
    backgroundColor: "{colors.deep}"
    textColor: "{colors.on-deep-muted}"
  band-numeral:
    backgroundColor: "{colors.deep}"
    textColor: "{colors.accent}"
    typography: "{typography.headline-sm}"
  band-logo-graphic:
    backgroundColor: "{colors.deep}"
    textColor: "{colors.sage-on-deep}"
  band-divider:
    backgroundColor: "{colors.deep-rule}"
  # Fills with no text on them: nothing to contrast-check, listed so every color has a use.
  divider:
    backgroundColor: "{colors.border}"
  divider-dark:
    backgroundColor: "{colors.border-dark}"
  planned-outline:
    backgroundColor: "{colors.border-dashed}"
    rounded: "{rounded.md}"
  planned-outline-dark:
    backgroundColor: "{colors.border-dashed-dark}"
    rounded: "{rounded.md}"
  phone-frame:
    backgroundColor: "{colors.device}"
  phone-frame-dark:
    backgroundColor: "{colors.device-dark}"
---

# Hutch design system

## Overview

One design system, two apps. The iPhone app and myhutch.app draw their colors, type, corners and spacing from the tokens at the top of this file, so the brand never drifts between them. Change a value here, never in an app. Each platform has its own guide for applying it: [apps/ios/DESIGN.md](apps/ios/DESIGN.md) and [apps/web/DESIGN.md](apps/web/DESIGN.md).

Hutch is a private home inventory that opens, by choice, to people you trust. The brand says:

- **Privacy by default.** Nothing is visible to anyone unless you choose.
- **Generosity by choice.** You open a small door for the people you trust.
- **Calm confidence.** Feels like home, never like a vault or a security product.
- **Modern optimism.** Fresh, bright and light; never rustic, nostalgic or heavy.

### The logo: a house with a keyhole (D17)

- **Mark:** a rounded, line-drawn house with a keyhole in the middle, in `sage`. Home first; the keyhole says it's yours to open.
- **Wordmark:** lowercase **hutch** in a bold, geometric, contemporary sans-serif, in `ink`, to the right of the mark.
- **Files:** [`design/light/logo.svg`](design/light/logo.svg) (on the warm off-white), [`design/dark/logo.svg`](design/dark/logo.svg) and [`design/dark/logo-transparent.svg`](design/dark/logo-transparent.svg) (on night forest), and the mark alone in [`design/light/icon.svg`](design/light/icon.svg). The website draws the logo inline from tokens (mark `sage`, wordmark `ink`), so one shape serves both modes. On forest, the mark is `sage-on-deep` and the wordmark `on-deep`.
- **App icon:** the house-and-keyhole mark alone, not yet drawn. Next: draw it, then a clean vector master of the logo (the current files are AI-traced, with uneven curves).

This replaced an earlier direction, a door left ajar carved into the "h" of the wordmark (#9), which was never drawn to a finished state.

### What was tried and rejected, and why

Images from each round are in [`design/explorations/`](design/explorations/), kept so nobody re-proposes them.

1. **Furniture pictures** (a drawn hutch, wardrobe, cabinet): too literal; looked like clip art (`round1-rejected-furniture.png`). The metaphor explains the brand; it shouldn't be drawn as the logo. Door drawings for the private → lend → sell stages were tried on the website and dropped (D15): with the door already in the copy and the logo, a third door read as heavy-handed. Stage icons show the action instead (house, people, tag).
2. **Earth-tone palettes** (walnut, oak, olive, terracotta): read as depressing and dated. What failed was heavy, rustic wood tones, not every warm color; the forest, warm-grey and brass palette (D15) stays light and airy.
3. **Colored accent pieces beside or on top of letters:** the symbol vanished in black and white, proving it was decoration, not design (`round2-rejected-added-shapes.png`).
4. **Cuts in several letters:** turned into a stencil typeface rather than one hidden symbol.
5. **Uniform straight cuts:** read as seams or rendering errors; a cut needs a taper to read as a door ajar. `round3-rejected-no-cut.png` (AI could not carve the cut) and `round4-closest-recraft.png` (closest to the carved "h": right weight, color and placement, but too many cuts, untapered, rough curves) end that direction.

## Colors

Forest, warm grey and brass (D15). Near-black green ink on a warm off-white, a deep forest for bold bands, a muted sage for small labels, and brass as the one warm accent. It replaced an earlier fresh-green palette; saffron `#FFB627` and ultramarine `#3D3BFF` were considered then.

Each token is a role, not a swatch. Use the role that describes the job (`ink-muted` for body copy, `surface` for a card), and if a design needs a color no role covers, add the role here first, or map it to the nearest one.

- **Text:** `ink` for headings and primary text, `ink-muted` for body copy, `ink-subtle` for captions, metadata and the footer.
- **Surfaces:** `background` for the page, `surface` for raised cards and screens, `surface-sunken` for recessed panels; `border` and `border-dashed` (planned, not built) for edges.
- **Forest:** `deep` for bold bands, with `on-deep` and `on-deep-muted` text, `deep-rule` dividers and `sage-on-deep` for the logo mark.
- **Brass (`accent`) is a marker, not a text color.** Dots, numerals on forest and small fills; never text on a light surface, where it fails contrast.
- **Sage (`sage`)** carries small labels and eyebrows, link hover and the focus ring; `sage-tint` with `on-sage-tint` makes positive badges.
- **`marker`** is the brass dot on the status pill. It's brass on the dark pill, and a deeper brass in dark mode, where the pill turns light and plain brass would fade (D18).
- **`device`** is hardware drawn on the page (the phone frame and its shadow); it stays dark in both modes.

### Light and dark follow the system

A color name ending in `-dark` is that role's value when the system is in dark mode: `ink-dark` replaces `ink`. A role without a `-dark` twin (`deep`, `on-deep`, `on-deep-muted`, `sage-on-deep`, `deep-rule`, `accent`) already sits on forest and keeps one value in both modes. The spec has no modes, so this suffix is Hutch's convention (D18); the generators turn it into each platform's dark appearance. To change a dark color, edit its token. Never invert colors ad hoc or add per-component dark rules.

### Contrast

Every text-on-background pair the design uses is listed under `components` in the tokens, light and dark, and `npm test` fails if one drops below WCAG AA (4.5:1 for text, 3:1 for `-graphic` marks). Add a pair there when a design puts a new color on a new background.

## Typography

Two families (D15): **Bricolage Grotesque** for headlines, the wordmark and numerals, and **Instrument Sans** for everything else. Bricolage is bold and a little quirky at large sizes, which keeps the page warm; Instrument Sans is quiet and readable.

- **Headlines** (`headline-*`) are Bricolage Bold with tight letter spacing that loosens as the size drops.
- **Titles and labels** (`title-md`, `label-*`) are Instrument Sans Semibold. `label-caps` is the eyebrow: uppercase, tracked out, in `sage`.
- **Body** (`body-*`, `caption`) is Instrument Sans Regular with generous line height.
- **`preview-*`** levels are for the link-preview image only.

Sizes are fixed per level, not fluid. A level ending in `-wide` is the same style at its size on wide screens (from 1024px); iPhone sizes are the base. On iPhone, levels map to Dynamic Type text styles so they scale with the user's setting.

## Layout

A 4px spacing scale; a token's name is its multiple of 4px (`6` is 24px). Layout gaps and padding come from the scale. Generous vertical space between sections; related things sit in cards with roomy padding (`8`, 32px).

Design for iPhone first. The website is a centered column (`page-width`, 1200px) with a 24px gutter (`6`) that splits into two columns where there's room; text pages use a narrower reading column (`prose-width`, 720px). `breakpoint-wide` (1024px) is where type switches to its `-wide` sizes.

## Elevation & Depth

Depth comes from tone, not shadow: `surface` cards on the `background`, `surface-sunken` panels recessed below it, and the forest band for the boldest break. The launch card gets a one-pixel `border` shadow at its foot. The only real shadow is the drawn phone's, in `device` at 18%, because it is an object on the page.

## Shapes

Soft, rounded and friendly, like the logo's house. `sm` (12px) for inputs and thumbnails, `md` (24px) for cards, `lg` (32px) for large panels, `pill` for pills and badges. Drawings of real hardware (the phone frame) keep their own geometry.

## Components

The component entries in the tokens are the color pairs the linter checks, not a component library. Each platform builds its components from the standard ones first (SwiftUI on iPhone, plain HTML on the web) and documents them in its own guide.

- **Status pill** (`pill`): an `ink` capsule with `background` text and a `marker` dot, 52px tall. Later the App Store link.
- **Badges** (`badge-positive`, `badge-planned`): `label-sm` in a pill; sage-tint for what ships at launch, sunken for what's planned.
- **Cards:** `surface` and solid for what exists, no fill and a dashed `border-dashed` outline for what's planned.
- **Focus ring:** 2px `sage` on light surfaces, `accent` inside the forest band.

## Do's and Don'ts

- Do use tokens for every color, font, corner and space; if one is missing, add it here first.
- Do keep brass for dots, numerals and fills; don't set it as text on a light surface.
- Do give every new text color on a new background a pair under `components`, with its `-dark` twin.
- Do follow the system's light or dark setting; don't add a manual theme switch or invert colors.
- Don't draw doors, locks or vaults: Hutch feels like home, not a security product.
- Don't hand-edit generated files (`tokens.css`, the favicon, Swift colors); run the platform's `tokens` task.
