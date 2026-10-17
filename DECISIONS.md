# Decisions

Each entry: what, status, and why. "Decided" means I chose it; "Proposed" means it's a recommendation awaiting my confirmation.

## D1 — Name and domain: Hutch, myhutch.app
**Status:** Decided (domain registered on Cloudflare, Oct 2026).

**Why:** Short, spelled as said, concrete image. A hutch has open shelves above and closed doors below, which maps onto private-by-default with selective display.

**Known risks:** "Hutch" is crowded — hutch.app (2018), gethutch.app (a live "AI assistants for your family" product, private/family positioning, 2026), thehutch.app (2026), plus a Sri Lankan telecom brand. Fine for a personal/neighborhood tool. **Revisit before any public launch.** Rejected alternatives: Armoire (hard to spell), Cubby (cubby.app $15k), Tallboy (US beer association), Lendery (sounds like a lender), Baoo (ambiguous pronunciation, baoo.app taken).

## D2 — Privacy model: end-to-end encrypted, zero-knowledge
**Status:** Decided (core requirement).

**Why:** I don't want a database on the web that knows what I own. The 1Password model: encrypt on device, server stores ciphertext only, sharing via per-vault keys.

**Consequences:** server can't search, match requests or send content-rich notifications; all of that runs on device. Key loss = data loss, so recovery (an emergency kit / recovery key) is a Phase 1 requirement, not an afterthought. Sharing protects against the platform, not against the circle — a neighbor who can see an item can screenshot it.

## D3 — Platform: native iPhone app + static website, in one monorepo
**Status:** Decided (Oct 2026). Replaces an earlier proposal for a web app (PWA).

**What:**
- `apps/ios` — the iPhone app (SwiftUI), distributed through the App Store.
- `apps/web` — a static site at myhutch.app: what Hutch is, an App Store download link, and the privacy policy and support pages the App Store requires.

**Why native:** better camera and barcode capture, the Keychain and Secure Enclave for keys, and a real App Store presence.

**Where it's built (decided):** on my Mac, in `~/Projects/hutch`, with Xcode. Sessions build, test and run the app in the iPhone simulator locally. This replaced an earlier plan to use a GitHub macOS runner as the only compiler, which was slow (minutes per iteration) and expensive (macOS CI minutes cost a multiple of Linux minutes on GitHub's free tier for private repos). CI stays optional.

**Supporting choices:**
1. The Xcode project is generated from a readable `project.yml` (XcodeGen), because `.xcodeproj` files are hard to edit correctly by hand.
2. Logic (models, crypto, sync) lives in a Swift package with unit tests, so most correctness is checked by tests rather than by tapping through the UI.
3. UI is checked through snapshot tests in each PR (D11), then on my phone through TestFlight.

**Costs and constraints:**
- Apple Developer Program, $99/year, needed for TestFlight and the App Store.
- Work that compiles Swift only happens when the Mac is on and linked to the session. With the Mac off, sessions are limited to docs and the website.

**Sync (proposed, confirm at M4):** CloudKit private database using encrypted fields, so Apple stores ciphertext and runs the servers. No backend to operate.

**Open risk for Phase 2:** CloudKit sharing only works between Apple users. If a neighbor is on Android, Phase 2 needs either our own small backend (storing only ciphertext) or a web view of the shared shelf. Decide at M6.

## D4 — Build order: personal first, sharing later
**Status:** Decided in principle.

**Why:** most home-inventory apps die from abandoned data entry, not missing features. Phase 2 sharing (invites, identity, key rotation on revocation) is far more complex than Phase 1, and only worth building once I've proven I keep the inventory up to date.

## D5 — Photo-based AI capture
**Status:** Open.

**Tension:** sending photos to a cloud model to auto-fill items breaks zero-knowledge. Options: manual entry + barcode only; on-device model; or explicit opt-in per photo with a clear warning. Decide during Phase 1, milestone M3.

## D6 — Personal tool vs. product
**Status:** Open — decide after Phase 1.

Drives whether to rename (see D1), invest in multi-platform polish, or pursue the eBay angle more seriously.

## D7 — Bundle ID: `app.myhutch.ios`
**Status:** Decided (Oct 2026).

**Why:** bundle IDs are reverse domain names, which keeps them globally unique. I own myhutch.app, so `app.myhutch.*` is mine. `app.hutch.*` would claim hutch.app, owned by someone else since 2018. A bundle ID can't change after App Store release.

## D8 — Minimum iOS version: iOS 26
**Status:** Decided (Oct 2026).

**Why:** iOS 27 shipped in September 2026 and supports the same iPhones as iOS 26, so targeting 26 excludes no device that can run 27, while allowing modern SwiftUI and SwiftData APIs. Revisit each autumn.

## D9 — The Xcode project is generated, not committed
**Status:** Decided (Oct 2026).

**Why:** `project.yml` (XcodeGen) is the source of truth. Generated `.xcodeproj` files cause merge conflicts and are hard for agents to edit safely. Trade-off: after cloning, run `make setup` in `apps/ios` before opening the project in Xcode.

## D10 — Work tracked in GitHub issues and milestones
**Status:** Decided (Oct 2026).

**Why:** issues show up in the GitHub app on my phone, PRs close them automatically, and the history is kept. Milestones are the three phases; issues are the units of work, each with a "Done when." The milestone descriptions hold each phase's goal, order and success test; durable reasoning stays in these docs. There is no separate plan file, because a second copy of the plan would drift.

## D11 — UI review through snapshot tests
**Status:** Proposed (Oct 2026). The approach is decided; confirm the library with me in M1.

**What:** each screen renders to reference images (light, dark, large Dynamic Type) stored with its tests. GitHub shows changed images side by side in a PR's file changes, so I can review UI from my phone with no extra tooling, and an unintended change fails the tests.

**Why not screenshots posted to the PR** (the earlier plan, on an orphan branch): custom plumbing to build and maintain, images from a private repo may not render in the GitHub mobile app, and screenshots are thrown away after one look. Snapshot tests give the same review plus regression protection.

**Costs:** one third-party test-only library (a well-known open-source snapshot-testing package is the likely choice), and small reference images in the repo, which are real test assets.

## D12 — Agents can't merge
**Status:** Decided (Oct 2026).

**Why:** every change gets one human look before it lands. Agent settings deny merging and pushing to `main`.

## D13 — Out of scope, for now
**Status:** Decided (Oct 2026).

- **Payments between neighbors:** Venmo or Zelle is fine, and the research found neighbors prefer lending for free (CONTEXT.md).
- **A public marketplace:** the opposite of private by default.
- **An Android app:** iPhone first (D3). Android neighbors are handled in the Phase 2 sharing decision.
- **Neighborhood discovery:** trust comes from people who already know each other, not from finding strangers nearby.

## D14 — Website: Astro, static output
**Status:** Decided (Oct 2026).

**Why:** Astro builds plain HTML ahead of time and ships no JavaScript by default: fast, and fitting for a privacy-first product. Text pages (privacy policy, support) are Markdown; shared components keep the header, footer and App Store button in one place; it deploys simply to Cloudflare Pages, where the domain lives.

**Rules:** static mode only, no server rendering or Cloudflare adapter unless a real need appears. Pin the Astro version; Astro moves fast (v6 requires a recent Node and removed older APIs), so upgrades get their own PR.

**Alternative considered:** plain HTML. Simpler for three pages, but means copying shared parts into every page, and the site is likely to grow.

**Hosting (decided, Oct 2026, W1):** Cloudflare Pages project `hutch`, connected to the GitHub repo rather than uploaded by hand. Merging to `main` deploys myhutch.app, and each PR touching `apps/web/` or `design/` gets a preview URL, so the site goes live through the same review-and-merge loop as everything else (D12) and needs no deploy credentials on the Mac. Pages runs `npm test`, so a broken build or link never ships. Astro pinned at 7.3.5, the newest release at least two weeks old when chosen. Web fonts are self-hosted (amended by D15).

**Contact:** support@myhutch.app, forwarded to my Gmail by Cloudflare Email Routing, so my personal address stays off the site.

## D15 — Palette: forest, warm grey and brass; self-hosted web fonts
**Status:** Proposed (Oct 2026). Confirm before the iOS app or the app icon adopt it. The tokens now live in the root `DESIGN.md` (D18), not `design/tokens.json`.

**What:**
- `design/tokens.json` now comes from the landing-page design: near-black green ink on warm off-white, a deep forest band color, sage for small labels and focus, and brass as the single warm accent. The token file also gains roles (muted and subtle ink, surfaces, borders, on-deep colors), two fonts (Bricolage Grotesque for display, Instrument Sans for text), weights, radii and a 4px spacing scale.
- **Supersedes** the fresh-green palette and brand.md's blanket rejection of earth tones: what failed before was heavy, rustic wood tones, not a light palette with one brass accent.
- **Amends D14:** the website now uses web fonts, self-hosted through pinned `@fontsource` packages and bundled into the build, so no request leaves myhutch.app and "no trackers" stays true.
- On the website, small icons beside each roadmap badge mark the private → lend → sell stages: house, two people, tag (SF Symbols `house`, `person.2`, `tag` in the app). Not doors: the headings ("Behind closed doors", "Out the door") and the logo already carry the door, and a third one made the metaphor heavy-handed. No lock for private: Hutch should feel like home, not a vault. A house glyph stands in for the logo until #9.

**Why:** the design reads calmer and more "home" than the bright green, which fits the "feels like home, never like a vault" value better.

**Consequences:** the iOS app (generated colors in M0) and the app icon inherit these tokens. The icon description in brand.md is updated to forest but not yet redrawn. Brass fails contrast as text on light surfaces; it's limited to fills and markers. There are no dark-mode tokens yet, so the website renders light only (`color-scheme: light`) rather than inventing colors; the iOS app needs dark roles before M1.

## D16 — Link preview: the door's light, rendered from the site's own tokens
**Status:** Proposed (Oct 2026).

**What:** sharing myhutch.app shows a 1200×630 card (`apps/web/public/og.png`): forest background, "Your things, privately kept.", and a tall brass sliver of light (the logo's tapered cut, hairline at the floor) spilling onto the floor. The card is an HTML page (`apps/web/og/card.html`) on the site's tokens and fonts, rendered by `npm run og` in headless Chromium via a pinned `playwright-core` dev dependency. The PNG is committed; `npm test` fails if the card, tokens or fonts changed since it was rendered.

**Why:** the site had no Open Graph tags, so shared links showed a bare URL. Light through a door ajar carries the brand's feeling (home, private, open when you choose) without drawing a door, which D15 found heavy-handed. Rendering in a real browser keeps the variable display font exactly as on the site; the usual Node image generators can't read its woff2 files. Rendering only on demand keeps the Cloudflare build browser-free.

**Consequences:** changing a token or the card means running `npm run og` once, on a machine with a Playwright browser (`npx playwright-core install chromium`). When the final logo lands (#9), the card's interim house glyph is swapped for it.

## D17 — The house-and-keyhole logo, and dark mode on the website
**Status:** Decided (Oct 2026). The `color-dark` group became `-dark` colors in the root `DESIGN.md` (D18).

**What:**
- The website header uses the new logo (`design/light/logo.svg`, `design/dark/logo.svg`): a rounded line-drawn house with a keyhole, beside a bold "hutch" wordmark. It is inlined as `Logo.astro`, traced from the light file, with the mark in `sage` and the wordmark in `ink` so one shape serves both modes. It replaces the interim house glyph.
- `tokens.json` gains a `color-dark` group: dark values for the light-surface roles, starting from the dark logo's night-forest background. The forest band, brass and on-deep roles keep one value. A new `device` role keeps the phone frame dark in both modes. The site follows the system setting (`color-scheme: light dark`).

**Why:** a real logo instead of a placeholder, in colors that come from the tokens. Dark mode follows the system, as the iPhone app will.

**Consequences:** this is the brand's logo. It replaces the "door carved into the h" direction (#9), which was never finished, and the app icon is drawn from the house mark. The link-preview card (D16) shows the logo too, with the mark in a new `sage-on-deep` role. Supersedes D15's "light only" note for the website. The iOS app can generate its dark colors from the same `color-dark` group.

## D18 — DESIGN.md is the design system's source of truth, enforced on both sides
**Status:** Proposed (Oct 2026).

**What:**
- One `DESIGN.md` at the repo root, in Google's [DESIGN.md format](https://github.com/google-labs-code/design.md) (alpha, linter pinned at 0.4.0): the tokens in its YAML front matter, the brand, rules and reasoning in its prose. It **supersedes `design/tokens.json`** (D15, D17) along with `design/README.md` and `design/brand.md`, which it absorbs. `design/` keeps only asset files: `light/`, `dark/` and `explorations/`. Each app has a short platform guide: `apps/web/DESIGN.md`, `apps/ios/DESIGN.md`.
- **Dark mode as a `-dark` suffix** in the one colors map (`ink`, `ink-dark`). The spec has no modes; unknown color names are valid, so the file stays spec-conformant, the linter checks every value, and each generator maps the suffix to its platform (a `prefers-color-scheme` block on the web, an asset-catalog appearance on iOS). The same pattern, `-wide`, gives a type level its size on wide screens: sizes are fixed, never fluid, because the spec has no `clamp()`.
- **A full type scale** (sixteen levels plus three for the link preview) replaces two families and four weights. Merging the site's ad hoc sizes into it changed some sizes on purpose (section titles share one size, prose is 16px).
- **Contrast is declared, then checked.** Every text-on-background pair is a `components` entry, with a `-dark` twin when its colors change in dark mode. Pairs ending in `-graphic` are marks and need 3:1.
- **Enforced on both sides, in `npm test`, which both GitHub (two workflows on every PR, each a required check on `main`: **Design Lint** and **Web Build**) and Cloudflare's build run, so a break can't be merged or deployed:** `design:lint:md` runs the linter and fails on any warning (the CLI only warns on low contrast), plus the `-dark` twin and `-graphic` rules; `design:lint:css` fails on raw colors, undefined variables, type outside the scale, external fonts and off-scale spacing in the website's code, with a reasoned allowlist in `apps/web/DESIGN.md`. iOS gets the equivalent in M0: Swift generated from DESIGN.md and a SwiftLint rule banning raw colors and sizes.
- Fixing what the linter found: `sage` darkened from `#3E7A62` to `#3D7961` (4.47:1 → 4.53:1 on the background), and a new `marker` role for the status pill's dot, deeper brass in dark mode (1.97:1 → 3.27:1).

**Why:** one file that agents and people both read, values next to the reasons, in a format the tools around agents are starting to understand. A token file alone said what but not why; the reasoning lived in two other files that could drift from it.

**Risks and exit plan:** the format is alpha and Google's. If it changes or stalls, `npx @google/design.md export --format dtcg DESIGN.md` writes a W3C design tokens file, the format `tokens.json` used, and the generators move to it. The -dark and -wide suffixes export as ordinary tokens, so nothing is lost. Until then, never keep a second token file by hand; generate one if a tool needs it.

## D19 — Website performance: one file, budgets at the deploy gate, Lighthouse on pull requests
**Status:** Proposed (Oct 2026).

**What:**
- `apps/web/PERFORMANCE.md` is the single source of the site's performance rules. Its YAML front matter holds the numbers: per-page byte budgets (total, HTML, CSS, fonts, images, JavaScript), allowed origins (self only), image rules (width and height, SVG/WebP/AVIF, a size cap), Lighthouse limits and the PR comparison thresholds. The prose below says why each rule exists and gives a checklist for new pages.
- `npm test` runs `check-performance.mjs`, which adds up what each built page makes the browser download and fails on any broken rule. Cloudflare Pages runs `npm test` before deploying, so a page over budget never ships.
- A GitHub Actions workflow (`.github/workflows/validate-performance.yml`, Linux, pull requests touching `apps/web/**`, `DESIGN.md` or `design/**`) builds main and the PR, runs Lighthouse (mobile preset) on each page that differs from main, alternating sides, and compares medians (score and CLS: worst run, since a font racing first paint makes CLS flip). It fails if a page is past PageSpeed's "good" limits (FCP 1.8 s, LCP 2.5 s, TBT 200 ms, CLS 0.1, score 90) or regresses beyond the noise margin; it comments only when the PR is faster.
- The site's stylesheet is now inlined in each page. As a separate file it blocked the first paint: mobile FCP measured 1.80 s, at the limit; inlined, 1.65 s.

**Why:** speed was a value (D14: static, no JavaScript) but nothing checked it, and a single photo or third-party embed could quietly undo it. One file keeps the rule and its reason together, so agents and I read the same thing and change numbers in one place. Byte budgets need no browser, so they fit the deploy gate without breaking D16's browser-free Cloudflare build. Timing metrics need a browser and are noisy, so they run in Actions, where comparing against main on the same machine cancels most of the noise; Linux minutes are cheap, unlike the macOS minutes D3 avoids.

**Consequences:** growing a budget is a visible one-line change to `PERFORMANCE.md` in the PR. The first real photo will need the images budget raised. Lighthouse is installed in the workflow only (pinned), so it adds nothing to the Cloudflare build. It runs through its Node API with one Chrome (`run-lighthouse.mjs`) rather than `lhci collect`, which launched Chrome and a server for every run: same results, about half the time, and unchanged pages aren't measured at all. The Actions check isn't required for merging unless set in branch protection.
