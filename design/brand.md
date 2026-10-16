# Brand

Status: logo chosen (D17, Oct 2026); palette proposed in D15 (Oct 2026).

## Values the brand expresses

- **Privacy by default.** Nothing is visible to anyone unless you choose.
- **Generosity by choice.** You open a small door for the people you trust.
- **Calm confidence.** Feels like home, never like a vault or a security product.
- **Modern optimism.** Fresh, bright and light; never rustic, nostalgic or heavy.

## The logo: a house with a keyhole (D17)

- **Mark:** a rounded, line-drawn house with a keyhole in the middle, in sage. Home first; the keyhole says it's yours to open.
- **Wordmark:** lowercase **hutch** in a bold, geometric, contemporary sans-serif, in ink, to the right of the mark.
- **Files:** [`light/logo.svg`](light/logo.svg) (on the warm off-white) and [`dark/logo.svg`](dark/logo.svg), [`dark/logo-transparent.svg`](dark/logo-transparent.svg) (on night forest). The website draws it inline from tokens (`apps/web/src/components/Logo.astro`): mark `color.sage`, wordmark `color.ink`, so the same shape works in both modes.
- **App icon:** the house-and-keyhole mark alone, not yet drawn.

This replaced the earlier direction, a door left ajar carved into the "h" of the wordmark (#9), which was never drawn to a finished state.

## Color (proposed, D15)

Forest, warm grey and brass. Near-black green ink on a warm off-white, a deep forest for bold bands, a muted sage for small labels, and brass as the one warm accent. Values and roles live in [tokens.json](tokens.json); how the website applies them is in [apps/web/DESIGN.md](../apps/web/DESIGN.md).

- **Brass (`color.accent`) is a marker, not a text color.** Use it for dots, numerals on forest and small fills; never as text on a light surface, where it fails contrast.
- **Sage (`color.sage`)** carries small labels, link hover and the focus ring.

This replaced the earlier fresh-green palette (D15). Alternatives considered then: saffron `#FFB627`, ultramarine `#3D3BFF`.

## What was tried and rejected, and why

1. **Furniture pictures** (a drawn hutch, wardrobe, cabinet): too literal; looked like clip art. The metaphor explains the brand; it shouldn't be drawn **as the logo**. Door drawings for the private → lend → sell stages were tried on the website and dropped (D15): with the door already in the copy and the logo, a third door read as heavy-handed. Stage icons show the action instead (house, people, tag).
2. **Earth-tone palettes** (walnut, oak, olive, brass, terracotta): read as depressing and dated. **Superseded by D15:** a restrained forest, warm-grey and brass palette, kept light and airy, replaced fresh green. What failed before was heavy, rustic wood tones, not every warm color.
3. **Colored accent pieces beside or on top of letters:** the symbol vanished in black and white, proving it was decoration, not design.
4. **Cuts in several letters:** turned into a stencil typeface rather than one hidden symbol.
5. **Uniform straight cuts:** read as seams or rendering errors; the cut needs a taper to read as a door ajar.

## Next step

Draw the app icon from the mark, then a clean vector master of the logo (the current files are AI-traced, with uneven curves).

## Reference images

In [`explorations/`](explorations/), in the order they were made:
- `round1-rejected-furniture.png` — literal furniture, earth tones.
- `round2-rejected-added-shapes.png` — colored pieces added beside letters; symbol vanishes in black and white.
- `round3-rejected-no-cut.png` — AI could not carve the cut.
- `round4-closest-recraft.png` — closest to the carved-"h" direction: right weight, color and placement, but too many cuts, uniform rather than tapered, and rough curves. That direction was dropped for the house-and-keyhole logo (D17).
