---
# Read by check-performance.mjs (in `npm test`, Cloudflare's deploy gate) and compare-performance.mjs
# (the Validate Page Speed check on pull requests). Change a number here and both follow.

# Per page, in KB as the browser downloads them before compression. Every page gets `default`;
# `pages` can raise a limit for one page (key: its file in dist/, e.g. index.html). Measured
# 2026-10-17, after fonts.mjs cut the fonts down: the largest page (index.html) was 11.2 KB HTML,
# 14.4 KB CSS, 49.6 KB fonts, 2.4 KB images, 0 JS, 77.6 KB total (before: 125.4 KB fonts and
# 156.0 KB total).
budgets:
  default:
    total_kb: 90
    html_kb: 13
    css_kb: 17
    fonts_kb: 56
    images_kb: 4
    js_kb: 0
  pages: {}

# Everything a page loads comes from the site itself. `others` lists any other origin allowed
# to serve a resource; empty means self only. Plain links to other sites are fine.
origins:
  site: https://myhutch.app
  others: []

images:
  require_dimensions: true     # every <img> has width and height
  formats: [svg, webp, avif]   # no PNG, JPEG or GIF on pages (og.png is for link previews, never loaded by a page)
  max_kb: 100                  # any single image

# Lighthouse, mobile preset (emulated mid-range phone, simulated slow 4G), on every page.
lighthouse:
  runs: 7                      # per side, alternating; medians compared, except score and CLS: worst run (see "How the numbers were set")
  limits:                      # a PR fails if any page's median is past these (see "Lighthouse limits")
    score: 99
    fcp_ms: 1500
    lcp_ms: 2500
    tbt_ms: 200
    cls: 0.1

# A PR fails if a metric gets worse, and earns a comment if it gets better, by more than both
# its threshold and noise_margin × main's value. Smaller changes are "on par".
compare:
  noise_margin: 0.02           # 2% of main's value
  thresholds:
    score: 1                   # points; so 2 or more counts
    fcp_ms: 50
    lcp_ms: 50
    tbt_ms: 50
    cls: 0.01
    total_bytes: 2048          # as transferred (compressed)
---

# Performance

myhutch.app should load instantly on a mid-range phone over a weak connection. Speed is a rule here, not a polish pass: the numbers above are checked on every build and every pull request, and this file is the only place they live.

## How it's enforced

| Where | What | Blocks |
|-------|------|--------|
| `npm test` → `check-performance.mjs` | Budgets, origins and image rules, read from the built files. No browser (D16 keeps the Cloudflare build browser-free). | The Cloudflare deploy |
| GitHub Actions → `run-lighthouse.mjs`, `compare-performance.mjs` | Lighthouse on main and the PR, alternating runs, then compared. Only pages whose built files differ from main are measured: identical files give identical results. | The PR's check |

The Actions check fails when any page is past a Lighthouse limit or when a metric regresses beyond the noise margin. When the PR makes the site measurably faster, it posts one comment with before and after numbers (updated on each push, removed if the gain disappears). When nothing changed beyond noise, it stays quiet and green.

## Why each rule exists

- **Total per page (90 KB).** Bytes are the cost most visitors feel: on a slow 4G link, every 100 KB adds roughly half a second. The landing page is the first impression of a privacy app; it should feel as light as the promise.
- **HTML and CSS.** Both block the first paint, so their size sets the floor of First Contentful Paint. The stylesheet is inlined into each page (`inlineStylesheets: 'always'` in `astro.config.mjs`): as a separate file it cost a full round trip before anything appeared, and inlining took mobile FCP from 1.80 s to 1.65 s, back under the limit. The check counts inline CSS against the CSS budget, so the cost is the same either way; if the CSS grows much past ~20 KB, a cached file may win again.
- **Fonts (56 KB).** Fonts are still the heaviest thing the site loads. The two families are self-hosted (D15), and `fonts.mjs` (`npm run fonts`) cuts them down to what the site uses: about 100 characters (ASCII and common punctuation), Bricolage Grotesque only at its one weight, 700 (its optical-size axis stays), and Instrument Sans at 400 and 600. That took them from 125 KB to 50 KB, and mobile FCP from 1.50 s to 1.20 s. A character outside that set would show in the fallback font, so `npm test` fails on it: add it to `CHARACTERS` in `fonts.mjs` and run `npm run fonts`. A third family or another weight has to fit here, or replace something.
- **JavaScript (0 KB).** Astro ships none by default (D14), and the site has never needed it. Script is the main cause of Total Blocking Time and of most tracking; zero keeps both at zero. A page that truly needs a script raises its own limit under `pages`, with the reason in the PR.
- **Images.** Width and height let the browser reserve space, so nothing jumps as images arrive (Cumulative Layout Shift). SVG, WebP and AVIF are several times smaller than PNG or JPEG for the same quality. A per-image cap catches an unexported camera photo. The 4 KB page budget leaves room for icons only: the first real photo means raising it deliberately.
- **Self only.** Every request to another origin costs a DNS lookup, a connection and a TLS handshake, and tells a third party someone visited. "No trackers" (AGENTS.md) is only true if nothing loads from anywhere else: no font CDNs, no embeds, no analytics.
- **Lighthouse limits.** LCP, TBT and CLS use PageSpeed Insights' "good" thresholds for the lab metrics. Score and FCP are stricter, set from what the site measures (100 and 1.20 s on every page after the fonts were cut down) so a regression fails before it's merely "good": score 99 (the worst run must still be near perfect) and FCP 1.5 s (PageSpeed's "good" is 1.8 s). The metrics: First Contentful Paint (when something first appears), Largest Contentful Paint (when the main content appears), Total Blocking Time (how long the page is too busy to respond) and Cumulative Layout Shift (how much things jump). Budgets keep bytes down; these catch the rest, such as a render-blocking resource or a layout that shifts as fonts load.
- **Comparison against main.** Limits catch a bad page; comparison catches a slow drift, such as ten small PRs that each add 50 ms. Thresholds stop a single noisy run from failing a PR or earning a comment.

## How the numbers were set

Budgets sit 10 to 25% above what the site measured when they were introduced (see the comment in the front matter), so today's site passes and any meaningful growth needs a deliberate change here. To see current sizes, build and run `node check-performance.mjs --report`.

The comparison settings come from 60 Lighthouse runs of the unchanged site (3 batches × 5 runs × 4 pages, mobile preset, 2026-10-17):

- **Medians barely move.** Across batches, each page's median FCP and LCP varied by under 1 ms (0.05%); score, TBT and page weight didn't change at all. Single runs strayed by up to 6 ms (0.3%), and an earlier trial run reported `/404` painting 580 ms early: single runs can mislead, so only medians are compared.
- **CLS flips, so it counts its worst run.** `/support` shifts by 0.071 when the web font arrives after first paint and not at all when it arrives before. That happened in 13 of 15 runs with the stylesheet as a file, and in about half once it was inlined. A median of a coin flip is noise, so CLS, and the score that moves with it, take the worst run: a shift that happens on some loads still happens to real visitors. With a 50% shift, **7 runs** miss it less than 1% of the time (5 runs: 3%). The shift itself was fixed at the source with fallback fonts sized like the web fonts (#36); the worst-run rule stays so a new one is caught.
- **Noise margin 2%** is about 6× the worst single-run timing spread. Lighthouse simulates the phone and network, so most machine speed cancels out, but the GitHub runner isn't the Mac these were measured on and the margin leaves room for that. A PR that changes no page is itself a main-versus-main test: if its check shows changes, the margin is too tight.
- **Thresholds** are the smallest change worth reporting even when noise is lower: 1 score point (single runs moved by exactly 1), 50 ms of paint or blocking time, 0.01 of layout shift, 2 KB of transferred weight. Content growth is fine; the page budgets cap the total.

## Before adding a page or feature

1. **Static by default.** A text page is a Markdown file in `src/pages/` on the shared layout (copy `support.md`'s front matter): no script and nothing new to load.
2. **Self-hosted assets only.** Fonts, images and icons go in the repo and ship from myhutch.app. No CDN links, embeds, widgets or third-party scripts, ever.
3. **Sized, modern images.** SVG for drawings and icons; WebP or AVIF for photos, exported at the size they're shown; `width` and `height` on every `<img>`.
4. **No JavaScript without a stated need.** If a page needs a script, say why in the PR and raise that page's `js_kb` under `pages`, nowhere else.
5. **Check it.** `npm test` fails with the page, the rule and the overage. If a budget must grow, change it here in the same PR and say why.
