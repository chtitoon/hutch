# Learned

What already happened: the evidence, and the verdict of each finished bet (H) and experiment (X). [ROADMAP.md](ROADMAP.md) only looks forward; when a bet or experiment ends, its verdict moves here. Newest first. What I chose because of a verdict goes in [DECISIONS.md](DECISIONS.md).

## Evidence

Observations, dated: what happened, not what I hope. Sources, since Hutch collects nothing ([non-negotiable 5](AGENTS.md#non-negotiables)): my notes, counts on my phone only I see, what neighbors tell me, public research.

<!-- #### E1 — <what happened, in one line>
**Date:** YYYY-MM-DD · **Bears on:** H1 · **Effect:** supports | weakens · **Source:** my notes
<the numbers or the quote, in a line or two> -->

_None yet. [H1](ROADMAP.md#h1) and [H2](ROADMAP.md#h2) write the first._

## Verdicts

#### <a id="x2"></a>X2 — DESIGN.md: kept
**Learning:** Google's alpha DESIGN.md format, enforced on both apps. **Need:** one design source agents and I both read ([D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides)). **Verdict:** tokens and their reasons in one file, linted on every PR; the exit plan is in [D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides).

#### <a id="x1"></a>X1 — performance.md: kept
**Learning:** a spec format and CLI for web performance, built from scratch. **Need:** nothing checked the website's speed ([D19](DECISIONS.md#d19--website-performance-one-file-budgets-at-the-deploy-gate-lighthouse-on-pull-requests)). **Verdict:** pages from 156 KB to 46 KB, Lighthouse 99, text that never moves, and a project of its own that Hutch's CI runs. It moved no outcome and filled the time the Mac was off, so the old roadmap stopped describing the work: the work was what I wanted, the roadmap was what was missing ([D22](DECISIONS.md#d22--an-outcome-roadmap-bets-and-experiments)).

## Before D22

The roadmap was phases of milestones until Oct 2026. Older docs and PRs still name these ids.

- **W1** Website v1, [#21](https://github.com/chtitoon/hutch/pull/21). **W2** performance budgets and **W3** no layout shift from fonts, [#35](https://github.com/chtitoon/hutch/pull/35). **W4** fonts never swap in, [#44](https://github.com/chtitoon/hutch/pull/44). **W5** Page Speed check in about a minute, [#48](https://github.com/chtitoon/hutch/pull/48). All done; part of [X1](#x1).
- **B1** final logo: the house-and-keyhole logo chosen ([D17](DECISIONS.md#d17--the-house-and-keyhole-logo-and-dark-mode-on-the-website)); the rest is under Later.
- **M0–M4** (scaffold, encryption at rest, item store, capture, sync and recovery) became [H1](ROADMAP.md#h1) and [H3](ROADMAP.md#h3); **M5–M12** and **T1**, **A1** are under Later or in H1. Their checklists are in git history, before [D22](DECISIONS.md#d22--an-outcome-roadmap-bets-and-experiments).
