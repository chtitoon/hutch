---
# Hutch's plan, phase by phase. The prose below holds each phase's goal, what makes it done, and its milestones.
# Only each phase's `public` block is ever shown on the website (the "Where we're heading"
# cards on myhutch.app). Nothing else in this file is: ids, titles, statuses and the prose stay internal.
#
# status: done | in-progress | planned
# public.icon: private | lend | sell (the StageIcon.astro icons)
phases:
  - id: phase-1
    title: My private inventory
    status: in-progress
    public:
      name: Behind closed doors
      icon: private
      badge: At launch
      description: "Snap it, name it, say where it lives. Everything you add is private by default."
  - id: phase-2
    title: Lend to a trusted circle
    status: planned
    public:
      name: A few things on the shelf
      icon: lend
      badge: Planned
      description: "Choose what to lend to people you trust: the ladder, the tent, the pasta maker…"
  - id: phase-3
    title: Sell
    status: planned
    public:
      name: Out the door
      icon: sell
      badge: Planned
      description: "When it’s time, sell what you no longer need straight from your inventory."
---

# Roadmap

The plan for Hutch: three phases, each with its goal, what makes it done, and the milestones that get it there.

**How to read it.**

- **Milestones** are the road, in build order: each one builds on those above it. Each has a goal and why we need it, and **Requires** only when something outside the list must happen first (a decision, an account, a test passed). Its detail (screens, tasks) is worked out when it starts, not here.
- **Done when** is the phase's definition of done: every box ticked and the success test passed. Each box ends with a link to the milestone that delivers it, and a milestone is done when all of its boxes are ticked.
- **Status** is written only when it's news: `done` or `in progress`, with the PR, or `blocked`, with why. A milestone without one hasn't started. What's next isn't marked: it's the first milestone not done. Phases are `done`, `in-progress` or `planned`, in the front matter above.
- Open questions are **Open** or **Proposed** entries in [DECISIONS.md](DECISIONS.md), linked from the milestones that require them.

Each PR ticks the boxes it meets and updates statuses here, so the plan changes in the same diff as the code (see the work loop in [AGENTS.md](AGENTS.md)).

## Phase 1 — My private inventory

**Status:** in progress.

**Goal:** I keep a list of my things on my iPhone, and all of it is encrypted, so only I can read it.

**Success test:** 50 real items cataloged within two weeks of fast capture shipping, without forcing it. If not, improve capture before anything else. Don't start Phase 2 until this passes.

### Milestones

#### M0 — Monorepo scaffold on the Mac
A clean, repeatable foundation every later session builds on.

- **Why:** every later session builds, tests and runs on it; without it, no session can prove its work.
- **Requires:** Xcode and XcodeGen on the Mac.
- **Prior work:** [PR #32](https://github.com/chtitoon/hutch/pull/32), branch `1-monorepo-scaffold`: the XcodeGen project, the `HutchCore` package with one test, the iOS and root Makefiles, Swift tokens generated from `design/` (before [DESIGN.md](DESIGN.md)), the logo screen and the app icon. Closed, not merged.

#### M1 — Encryption at rest
Nothing about my items is readable on the device without my key.

- **Why:** an inventory is a map of my home ([D2](DECISIONS.md#d2--privacy-model-end-to-end-encrypted-zero-knowledge)). Built before the store, so there's never an unencrypted one and nothing to migrate.

#### M2 — Local item store
Add, edit, delete and search my items on the phone, behind Face ID.

- **Why:** the inventory is the product; capture, sync and sharing all work on these items.
- **Requires:** [PR #22](https://github.com/chtitoon/hutch/pull/22)'s decision on location as free text, decided (never merged).
- **Prior work:** [PR #22](https://github.com/chtitoon/hutch/pull/22), branch `2-m1-design-spec`: a screen spec for the item store, written when it was M1 (`apps/ios/design/milestone1.md`), the design canvas export, and two proposed decisions, on location as free text and on the written spec winning over the canvas. Closed, not merged.

#### M3 — Fast capture
Adding an item is fast enough that I actually catalog my things.

- **Why:** data entry is what kills home-inventory apps ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product)), and the success test is about it.
- **Requires:** [D5](DECISIONS.md#d5--photo-based-ai-capture) decided (Open today).

#### M4 — Encrypted sync and recovery
My inventory survives a lost phone, and the server still learns nothing.

- **Why:** on one phone, losing it loses everything; and losing the only key must never do that either ([non-negotiable 4](AGENTS.md#non-negotiables)).
- **Requires:** the sync approach in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) confirmed (Proposed today).

#### M5 — Organize
Find things by where they are and what they're worth.

- **Why:** a list only helps if I can find the ladder by where it is; value, receipts and warranties are what I look things up for.

#### B1 — Final logo and design tokens
Final artwork and a fuller design system, alongside the rest.

- **Why:** the app needs an icon before TestFlight, and the logo files are AI-traced.

#### T1 — First TestFlight build
Hutch on my own phone.

- **Why:** the success test runs on my phone, with my real things.
- **Requires:** Apple Developer Program membership ($99/year).

#### A1 — App Store release
Hutch public on the App Store.

- **Why:** "At launch" on the site means anyone can get it, not just me.
- **Requires:** the success test passed.

#### W1 — Website v1
- **Status:** done, [PR #21](https://github.com/chtitoon/hutch/pull/21)
- **Why:** the App Store requires a privacy policy and a support page.

#### W2 — Website performance budgets
- **Status:** done, [PR #35](https://github.com/chtitoon/hutch/pull/35)
- **Why:** speed was a value ([D14](DECISIONS.md#d14--website-astro-static-output)) but nothing checked it ([D19](DECISIONS.md#d19--website-performance-one-file-budgets-at-the-deploy-gate-lighthouse-on-pull-requests)).

#### W3 — Font swap no longer shifts the layout
- **Status:** done, [PR #35](https://github.com/chtitoon/hutch/pull/35) (from closed [PR #38](https://github.com/chtitoon/hutch/pull/38))
- **Why:** visitors saw `/support` jump when the fonts arrived.

### Done when

**Private by design**
- [ ] Item data and photos are encrypted on the device with CryptoKit before anything is written, with the key in the Keychain · [M1](#m1--encryption-at-rest)
- [ ] Tests assert that nothing the app writes to disk contains plaintext · [M1](#m1--encryption-at-rest), [M2](#m2--local-item-store)
- [ ] Synced payloads are ciphertext only, and tests assert the server can't read them · [M4](#m4--encrypted-sync-and-recovery)
- [ ] Every item is `private`; nothing in Phase 1 can make it lendable or for sale ([non-negotiable 2](AGENTS.md#non-negotiables)) · [M2](#m2--local-item-store)
- [ ] Opening Hutch, or coming back to it, needs Face ID or the device passcode · [M2](#m2--local-item-store)
- [ ] Every crypto choice is explained in the PR that makes it ([non-negotiable 3](AGENTS.md#non-negotiables)) · [M1](#m1--encryption-at-rest), [M4](#m4--encrypted-sync-and-recovery)
- [ ] No third-party analytics, trackers or SDKs that report anywhere, in the app or on the site ([non-negotiable 5](AGENTS.md#non-negotiables)) · every milestone

**Never lose it**
- [ ] The sync approach is settled in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) · [M4](#m4--encrypted-sync-and-recovery)
- [ ] A new iPhone signed into my Apple account gets the key through iCloud Keychain and restores everything ([D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)) · [M4](#m4--encrypted-sync-and-recovery)
- [ ] A printable recovery kit restores everything on a new device without my Apple account ([D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)) · [M4](#m4--encrypted-sync-and-recovery)
- [ ] Recovery shipped before or with sync, never after ([non-negotiable 4](AGENTS.md#non-negotiables)) · [M4](#m4--encrypted-sync-and-recovery)

**Keep an inventory**
- [ ] Items have a name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and `visibility` (`private`, `lendable`, `for_sale`; only `private` works yet) · [M2](#m2--local-item-store)
- [ ] Add, edit, delete and search items, on the device, offline · [M2](#m2--local-item-store)
- [ ] Photo-first entry with the camera · [M3](#m3--fast-capture)
- [ ] A barcode scan fills in what it can · [M3](#m3--fast-capture)
- [ ] Photo-based AI capture is decided in [D5](DECISIONS.md#d5--photo-based-ai-capture), and built if chosen · [M3](#m3--fast-capture)
- [ ] Locations (garage, basement…), categories and estimated value to find and sort by · [M5](#m5--organize)
- [ ] Receipts and warranty dates attached to items · [M5](#m5--organize)

**Built well**
- [ ] `apps/ios/project.yml` generates the app: bundle ID `app.myhutch.ios`, minimum iOS 26 ([D7](DECISIONS.md#d7--bundle-id-appmyhutchios), [D8](DECISIONS.md#d8--minimum-ios-version-ios-26)) · [M0](#m0--monorepo-scaffold-on-the-mac)
- [ ] From a clean clone, `make setup`, `make test`, `make run` and `make tokens` work in `apps/ios` and at the root, non-interactively; `make test` prints its simulator · [M0](#m0--monorepo-scaffold-on-the-mac)
- [ ] Logic (models, crypto, sync) lives in the Swift package and is unit-tested there · [M0](#m0--monorepo-scaffold-on-the-mac) on
- [ ] Every screen has snapshot tests in light and dark mode and at a large Dynamic Type size, with the library recorded in [D11](DECISIONS.md#d11--ui-review-through-snapshot-tests) · [M2](#m2--local-item-store) on
- [ ] Works on every current iPhone size, in dark mode and with Dynamic Type · [M2](#m2--local-item-store) on
- [ ] Colors and sizes are generated from [`DESIGN.md`](DESIGN.md), never hard-coded ([D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides)) · [M0](#m0--monorepo-scaffold-on-the-mac) on
- [ ] `make test` is green at the root · every milestone
- [x] Logo chosen: house with a keyhole beside the "hutch" wordmark ([D17](DECISIONS.md#d17--the-house-and-keyhole-logo-and-dark-mode-on-the-website)); on the website · [B1](#b1--final-logo-and-design-tokens)
- [ ] Final app icon at all required sizes, from the house-and-keyhole mark · [B1](#b1--final-logo-and-design-tokens)
- [ ] A clean vector master of the logo (the current files are AI-traced) · [B1](#b1--final-logo-and-design-tokens)
- [ ] Type scale, spacing and corner radius in [`DESIGN.md`](DESIGN.md) ([D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides)) · [B1](#b1--final-logo-and-design-tokens)
- [ ] Color roles confirmed (proposed in [D15](DECISIONS.md#d15--palette-forest-warm-grey-and-brass-self-hosted-web-fonts); dark roles added in [D17](DECISIONS.md#d17--the-house-and-keyhole-logo-and-dark-mode-on-the-website)) · [B1](#b1--final-logo-and-design-tokens)

**On my phone, and in public**
- [x] myhutch.app explains Hutch, with the privacy policy and support page the App Store requires · [W1](#w1--website-v1)
- [ ] The privacy policy matches what the app actually does · [T1](#t1--first-testflight-build)
- [ ] A signed build on TestFlight, installed on my phone · [T1](#t1--first-testflight-build)
- [ ] The App Store Connect API key is a GitHub secret, never in the repo · [T1](#t1--first-testflight-build)
- [ ] The name is revisited before going public, as [D1](DECISIONS.md#d1--name-and-domain-hutch-myhutchapp) requires · [A1](#a1--app-store-release)
- [ ] Hutch is live on the App Store; its App Privacy label says no data is collected · [A1](#a1--app-store-release)
- [ ] The site's "Coming to iPhone" pill becomes the App Store link · [A1](#a1--app-store-release)

**Proven**
- [ ] The success test passed
- [ ] Personal tool or product is decided in [D6](DECISIONS.md#d6--personal-tool-vs-product)

## Phase 2 — Lend to a trusted circle

**Status:** planned. Starts only once Phase 1 is done.

**Goal:** the neighbors I trust can see and borrow the few things I put on the shelf.

**Social plan** (matters more than the code): seed with 10-15 of my own items; ask 4-6 trusted neighbors for 2-3 things they'd lend, not a full inventory; support 'anyone have a ladder?' requests ([CONTEXT.md](CONTEXT.md#the-social-plan-for-lending)).

**Success test:** at least 3 households lending to each other within a month of launch.

### Milestones

#### M6 — Lendable shelf
Chosen items on a shelf my circle can see.

- **Why:** lending starts with choosing what to show; a separate key keeps everything else private.
- **Requires:** [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)'s Phase 2 sharing platform decided.

#### M7 — Circle invites
Invite the few neighbors I trust.

- **Why:** trust comes from people I already know, not strangers nearby ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product)).

#### M8 — Loans
Lending is easy to request and hard to forget.

- **Why:** if lending is a chore or things don't come back, neighbors stop lending.

#### M9 — Revocation
Removing someone actually removes their access.

- **Why:** without a new key, someone I removed could still read what I add afterward.

### Done when

- [ ] What neighbors who aren't on iPhone get is settled in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) (Phase 2 sharing platform) · [M6](#m6--lendable-shelf)
- [ ] A shelf is a separate vault with its own key; moving an item there re-encrypts it under that key · [M6](#m6--lendable-shelf)
- [ ] Nothing reaches the shelf without my explicit action ([non-negotiable 2](AGENTS.md#non-negotiables)) · [M6](#m6--lendable-shelf)
- [ ] I invite by link; members receive the shelf key through public-key exchange · [M7](#m7--circle-invites)
- [ ] Members can share shelves of their own · [M7](#m7--circle-invites)
- [ ] Request → approved → out → returned, with dates · [M8](#m8--loans)
- [ ] Condition photos at handoff, and return reminders · [M8](#m8--loans)
- [ ] "Anyone have a ladder?" requests, not just browsing · [M8](#m8--loans)
- [ ] Removing a member rotates the shelf key, and tests show they can't read items added afterward · [M9](#m9--revocation)
- [ ] Tests assert everything shared reaches the server as ciphertext only · [M6](#m6--lendable-shelf)–[M9](#m9--revocation)
- [ ] The success test passed

## Phase 3 — Sell

**Status:** planned.

**Goal:** sell an item on eBay straight from my private inventory, decrypting it only on my device.

### Milestones

#### M10 — eBay connect
Connect my eBay account.

- **Why:** listing and pricing both go through it.

#### M11 — Sell an item
Sell straight from my inventory.

- **Why:** selling shouldn't mean retyping an item, or handing my inventory to a server.

#### M12 — What's it worth?
Know what my things would fetch.

- **Why:** that's what tells me something is worth selling.

### Done when

- [ ] I connect my eBay account by OAuth, and the token is stored encrypted · [M10](#m10--ebay-connect)
- [ ] "Sell on eBay" decrypts the item on the device only · [M11](#m11--sell-an-item)
- [ ] It creates a listing through eBay's Sell Inventory API from the item's photos and description · [M11](#m11--sell-an-item)
- [ ] Each item shows a price estimate from comparable sold listings · [M12](#m12--whats-it-worth)

