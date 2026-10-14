# Design canvas: source files

The source of the [Hutch iPhone design canvas](https://claude.ai/artifact/4W3du15YUNdN3JE38wtxVH), made in Claude Design and exported here so the repo keeps a copy of every screen. Exported Oct 2026, from canvas version `1791945807-a284`.

## What's here

| File | Canvas page | Screen |
|------|-------------|--------|
| `canvas.json` | — | Index: pages, artboard positions, titles |
| `Main.dc.html` | Milestone 1 | Home |
| `Room.dc.html` | Milestone 1 | Room (a place's items) |
| `Item.dc.html` | Milestone 1 | Item detail |
| `Add.dc.html` | Milestone 1 | Add an item |
| `Lend.dc.html` | Later | Lend to a neighbor |
| `ShareConfirm.dc.html` | Later | Make borrowable: who sees it |
| `NeighborView.dc.html` | Later | What a neighbor sees |
| `Request.dc.html` | Later | Incoming borrow request |

Each `.dc.html` file is one 390×844 screen: HTML with inline styles, plus a small script block for interactive state. They render only inside Claude Design (they load its runtime through `support.js`), so open the canvas link to see them; here they're readable as markup.

## How to use them

- **The spec wins.** For M1, build from [`../milestone1.md`](../milestone1.md), not from these files (D17). These are a visual reference: layout, hierarchy, spacing rhythm and tone.
- **Known differences from the spec**, because the canvas was drawn before D15 and before M1 was trimmed:
  - Colors and fonts are not the tokens (sage-grey and lacquer green, Hanken Grotesk and Newsreader). Use `design/tokens.json`.
  - The canvas shows features from later milestones: rooms and spots, warranty, receipts, resale value (M5, Phase 3). M1 has a free-form "Where it lives" (D16) and no warranty, receipt or value UI.
  - Home has a tab bar and "On this phone only"; M1 has neither (see the spec's Navigation and "What M1 must not claim").
  - Add is camera-first, which is M3. M1's Add is the form in the spec.
- **The Later page** holds the Phase 2 lending flows. They're parked, not approved designs; revisit them when Phase 2 starts.

## Keeping this in sync

The canvas is the editable original; this folder is a snapshot. When the canvas changes in a way that matters, re-export it here in its own PR, and update the version above. Never edit these files by hand to change the design; change the canvas, then re-export, so the two don't diverge.
