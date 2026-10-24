# Learned

What already happened.

- **Evidence:** what I observed, dated.
- **Verdicts:** how each finished bet (H) or experiment (X) ended.
- [ROADMAP.md](ROADMAP.md) only looks forward. When a bet or experiment ends, its verdict moves here.
- What I chose because of a verdict goes in [DECISIONS.md](DECISIONS.md).

Newest first in each section.

## Evidence

What happened, not what I hope.

Hutch collects nothing ([non-negotiable 5](AGENTS.md#non-negotiables)), so evidence comes from:
- my notes
- counts on my phone that only I see
- what neighbors tell me
- public research

#### <a id="e4"></a>E4 — A catalog of names, matched by image embeddings: the right kind for 4 of 4

- **Date:** 2026-10-24
- **Bears on:** [X5](ROADMAP.md#x5), [D26](DECISIONS.md#d26--identifying-a-product-online-by-choice)
- **Effect:** supports
- **Source:** `tools/catalog-index/score.py` on the Mac, SigLIP 2 base, a hand-made catalog of 382 names
- Two public photos of a MacBook Air, one on a wooden desk: "Apple MacBook Air" first both times.
- My beer glass: the right kind, all 5 beer or pint glasses. The brewery's logo wasn't known: with decoy breweries added, another one ranked first and Bissell Brothers second.
- A wooden frame on a busy shop wall:
  - The whole photo: third, behind "screen print poster" and "framed art print".
  - Cropped to the frame: first.
- A hose spray nozzle: "Gardena hose spray nozzle" first. Grey and orange are Gardena's colors.
- Before the catalog covered a kind, the answers were confident nonsense: "blender" for the glass, "desk" for the frame.
- **What it says:**
  - Kinds work.
  - Famous brands work; small ones don't.
  - Coverage of the catalog matters most, and cropping helps in busy scenes.
  - About 15–45 ms per photo on the Mac.
- Too few photos for a verdict: X5's gate asks for 20+.

#### <a id="e3"></a>E3 — My MacBook Air came out as just "Computer"

- **Date:** 2026-10-24
- **Bears on:** [X4](ROADMAP.md#x4), [D26](DECISIONS.md#d26--identifying-a-product-online-by-choice)
- **Effect:** weakens on-device naming
- **Source:** my notes, on my iPhone 17, after the screen-text fix
- A MacBook Air has no brand text the camera can read, only a logo, and Vision's most specific label is "computer".
- What I want instead: broad but not too broad from the photo ("Apple MacBook Air", "Wooden chair"), then help narrowing to what the photo can't show (chip and year, memory, storage), and for things like chairs, a way to find the exact product.
- **What changed because of it:**
  - The model is asked for brand plus product line, and never a bare class like "computer".
  - It also lists the item's aspects (Brand: Apple, Color: Silver, Memory: 16 GB). Those the photo shows come filled in; the rest have a few choices to pick in one tap. They're saved with the item.
  - Identifying online is written up as D26, open, for later.

#### E2 — With Apple Intelligence on: a charger right, a laptop wrong

- **Date:** 2026-10-24
- **Bears on:** [X4](ROADMAP.md#x4)
- **Effect:** mixed
- **Source:** my notes, on my iPhone 17, after the brand change
- A RAVPower charger was named right.
- My open laptop, on a wooden table, was named "Wooden Box".
- Likely causes: the screen's text was passed to the model as if printed on the object, and scene labels ("wood", "table") were passed as if they named it. Not yet known whether the model saw the photo or only Vision's labels: the note under the name says which.
- **What changed because of it:** only short printed lines count as text on the object, and scene and material labels are passed to the model marked "not the object".

#### E1 — First 3 photos: no suggestion was right

- **Date:** 2026-10-24
- **Bears on:** [X4](ROADMAP.md#x4)
- **Effect:** weakens, though the cause isn't known yet
- **Source:** my notes, on my iPhone 17, first build of [H1](ROADMAP.md#h1)
- A glasses box was named "Bookshelf".
- A charger was named "Computer".
- A laptop got "Unknown".
- 0 of 3 kept as is, against X4's bar of 7 in 10.
- The first two are raw Vision labels, so Apple Intelligence probably never ran: off, still downloading, or failing silently. Vision also labeled the whole scene, not the object.
- **What changed because of it:**
  - The confirm screen now says which path named the item, and why Apple Intelligence wasn't used.
  - Vision crops to the main object first.
  - "Unknown" counts as no suggestion.
  - The next photos tell whether the model is the problem or just wasn't running.

<!-- Template:

#### E1 — What happened, in one line

- **Date:** YYYY-MM-DD
- **Bears on:** H1
- **Effect:** supports or weakens
- **Source:** my notes
- The numbers or the quote.

-->

## Verdicts

#### <a id="x2"></a>X2 — DESIGN.md: kept

- **Learning goal:** Google's alpha DESIGN.md format, enforced on both apps.
- **Need:** one design source that agents and I both read ([D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides)).
- **Verdict:** the tokens and their reasons live in one file, linted on every PR.
- **If it stalls:** the exit plan is in D18.

#### <a id="x1"></a>X1 — performance.md: kept

- **Learning goal:** a spec format and CLI for web performance, built from scratch.
- **Need:** nothing checked the website's speed ([D19](DECISIONS.md#d19--website-performance-one-file-budgets-at-the-deploy-gate-lighthouse-on-pull-requests)).
- **What happened:**
  - Pages went from 156 KB to 46 KB.
  - Lighthouse scores 99.
  - Text never moves once drawn.
  - performance.md became a project of its own, which Hutch's CI runs.
- **What it taught about the plan:** it moved no outcome and filled the time the Mac was off, so the old roadmap stopped describing the work. The work was what I wanted; the roadmap was what was missing. That led to [D22](DECISIONS.md#d22--an-outcome-roadmap-bets-and-experiments).

## Before D22

Until Oct 2026 the roadmap was phases of milestones. Older docs and PRs still name these ids.

Website milestones, all done and part of [X1](#x1):
- **W1:** website v1, [#21](https://github.com/chtitoon/hutch/pull/21).
- **W2:** performance budgets, [#35](https://github.com/chtitoon/hutch/pull/35).
- **W3:** no layout shift from fonts, [#35](https://github.com/chtitoon/hutch/pull/35).
- **W4:** fonts never swap in, [#44](https://github.com/chtitoon/hutch/pull/44).
- **W5:** Page Speed check in about a minute, [#48](https://github.com/chtitoon/hutch/pull/48).

The rest:
- **B1:** the house-and-keyhole logo was chosen ([D17](DECISIONS.md#d17--the-house-and-keyhole-logo-and-dark-mode-on-the-website)). The rest of it is under Later.
- **M0–M4** (scaffold, encryption at rest, item store, capture, sync and recovery) became [H1](ROADMAP.md#h1) and [H3](ROADMAP.md#h3).
- **M5–M12, T1, A1** are under Later, or part of H1.

Their old checklists are in git history, before D22.
