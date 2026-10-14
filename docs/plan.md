# Plan

The roadmap and the reasoning behind it. **Status lives in GitHub:** each phase is a [milestone](https://github.com/chtitoon/hutch/milestones), each unit of work an issue with its own "Done when." This file changes only when the plan itself changes.

Three phases, each with a success test. I don't start the next phase until the current one passes.

## Phase 1 — My private inventory

**Goal:** I catalog my own things in an app that knows nothing I haven't encrypted. → [Phase 1 issues](https://github.com/chtitoon/hutch/milestone/1)

The order: scaffold, a local item store, encryption at rest, fast capture, encrypted sync with recovery, organizing, then the website (the App Store requires its privacy policy) and a first TestFlight build. The final logo and design tokens can happen alongside.

**Item model (starting point):** name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and a `visibility` field: `private` (default) / `lendable` / `for_sale`. The field exists from day one even though only `private` works in Phase 1.

**Success test:** 50 real items cataloged within two weeks of fast capture shipping, without forcing it. If not, improve capture before anything else. Most home-inventory apps die from abandoned data entry, not missing features.

## Phase 2 — Lend to a trusted circle

**Goal:** the neighbors I trust can see and borrow the few things I put on the shelf. → [Phase 2 issues](https://github.com/chtitoon/hutch/milestone/2)

The order: a lendable shelf with its own key, invites, loans, then revocation.

**Social plan (matters more than the code):** seed with 10–15 of my own items; ask 4–6 trusted neighbors for "2–3 things you'd lend," not a full inventory; support "anyone have a ladder?" requests, not just listings. The reasons are in [context.md](context.md).

**Success test:** at least 3 households lending to each other within a month of launch.

## Phase 3 — Sell

**Goal:** sell an item on eBay straight from my private inventory, decrypting it only on my device. → [Phase 3 issues](https://github.com/chtitoon/hutch/milestone/3)

## Not doing (for now)

Payments between neighbors (Venmo/Zelle is fine), a public marketplace, an Android app, a "neighborhood" discovery feature.

## My to-dos outside the repo

- Before M0: clone to `~/Projects/hutch`, and install Xcode and XcodeGen (`brew install xcodegen`).
- Before the TestFlight build: join the Apple Developer Program ($99/year).
- Before the website: point myhutch.app at Cloudflare Pages, and pick the contact email for the support page.
