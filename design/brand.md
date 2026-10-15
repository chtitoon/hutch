# Brand

Status: logo direction chosen, final logo not yet drawn; palette proposed in D15 (Oct 2026).

## Values the brand expresses

- **Privacy by default.** Nothing is visible to anyone unless you choose.
- **Generosity by choice.** You open a small door for the people you trust.
- **Calm confidence.** Feels like home, never like a vault or a security product.
- **Modern optimism.** Fresh, bright and light; never rustic, nostalgic or heavy.

## The logo: a door left slightly ajar, carved into the "h"

- Lowercase wordmark **hutch** in a bold, geometric, contemporary sans-serif.
- **One** hidden detail in the whole word: in the first "h," a thin wedge-shaped cut separates the stem from the arch, hairline at the baseline and slightly wider at the top, so the arch and right leg read as a door swinging open from its frame.
- **Carved, never added.** The symbol is negative space only. No extra shapes, overlays or second color. Test: it must be visible in plain black on white.
- The letter must still read as an ordinary "h"; the door is a discovery, not a decoration.
- **App icon:** the carved "h" alone, light on forest (`color.deep`), with a wider cut than the wordmark so it survives at home-screen size. (Was white on fresh green before D15; not yet redrawn.)
- **Interim mark:** until the final logo exists (#9), the website uses a simple line-drawn house glyph beside the wordmark. It is a placeholder, not the logo.

## Color (proposed, D15)

Forest, warm grey and brass. Near-black green ink on a warm off-white, a deep forest for bold bands, a muted sage for small labels, and brass as the one warm accent. Values and roles live in [tokens.json](tokens.json); how the website applies them is in [apps/web/DESIGN.md](../apps/web/DESIGN.md).

- **Brass (`color.accent`) is a marker, not a text color.** Use it for dots, numerals on forest and small fills; never as text on a light surface, where it fails contrast.
- **Sage (`color.sage`)** carries small labels, link hover and the focus ring.

This replaced the earlier fresh-green palette (D15). Alternatives considered then: saffron `#FFB627`, ultramarine `#3D3BFF`.

## What was tried and rejected, and why

1. **Furniture pictures** (a drawn hutch, wardrobe, cabinet): too literal; looked like clip art. The metaphor explains the brand; it shouldn't be drawn **as the logo**. Small line-drawn door icons (closed, ajar, out) are allowed on the website to mark the private → lend → sell stages (D15); kept icon-sized, since full-size drawings read as heavy-handed.
2. **Earth-tone palettes** (walnut, oak, olive, brass, terracotta): read as depressing and dated. **Superseded by D15:** a restrained forest, warm-grey and brass palette, kept light and airy, replaced fresh green. What failed before was heavy, rustic wood tones, not every warm color.
3. **Colored accent pieces beside or on top of letters:** the symbol vanished in black and white, proving it was decoration, not design.
4. **Cuts in several letters:** turned into a stencil typeface rather than one hidden symbol.
5. **Uniform straight cuts:** read as seams or rendering errors; the cut needs a taper to read as a door ajar.

## Next step

Draw the final wordmark by hand in Figma on a real geometric typeface, with the single wedge cut; AI tools got the idea but not the precision. Then derive the design system (type scale, spacing, corner radius, color roles) from it.

## Reference images

In [`explorations/`](explorations/), in the order they were made:
- `round1-rejected-furniture.png` — literal furniture, earth tones.
- `round2-rejected-added-shapes.png` — colored pieces added beside letters; symbol vanishes in black and white.
- `round3-rejected-no-cut.png` — AI could not carve the cut.
- `round4-closest-recraft.png` — **closest so far.** Right weight, color and placement (stem separated from the arch of the "h"), but too many cuts (u, t, second h), cuts are uniform rather than tapered, and curves are rough. Use as the starting point for the hand-drawn version.
