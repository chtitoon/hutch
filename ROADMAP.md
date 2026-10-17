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

- **Done when** is the phase's definition of done: every box ticked and the success test passed. Each box names, in brackets, the milestone that delivers it.
- **Milestones** are one line each: ID, status, goal, why, and what it depends on. A milestone is done when all of its boxes are ticked. Its detail (screens, tasks) is worked out when it starts, not here.
- **Status:** milestones are `done`, `next` (ready to start), `later` or `blocked` (waiting on something outside the repo); phases are `done`, `in-progress` or `planned`, in the front matter above.
- Open questions are **Open** or **Proposed** entries in [DECISIONS.md](DECISIONS.md), linked from what depends on them.

Each PR ticks the boxes it meets and updates statuses here, so the plan changes in the same diff as the code (see the work loop in [AGENTS.md](AGENTS.md)).

## Phase 1 — My private inventory

**Status:** in progress.

**Goal:** I keep a list of my things on my iPhone, and all of it is encrypted, so only I can read it.

**Order:** scaffold, encryption at rest, local store, fast capture, encrypted sync with recovery, organize, then the website (the App Store needs its privacy policy) and a first TestFlight build; the final logo can happen alongside.

**Success test:** 50 real items cataloged within two weeks of fast capture shipping, without forcing it. If not, improve capture before anything else. Don't start Phase 2 until this passes.

### Done when

**Private by design**
- [ ] Item data and photos are encrypted on the device with CryptoKit before anything is written, with the key in the Keychain [M1]
- [ ] Tests assert that nothing the app writes to disk contains plaintext [M1, M2]
- [ ] Synced payloads are ciphertext only, and tests assert the server can't read them [M4]
- [ ] Every item is `private`; nothing in Phase 1 can make it lendable or for sale (non-negotiable 2) [M2]
- [ ] Every crypto choice is explained in the PR that makes it (non-negotiable 3) [M1, M4]
- [ ] No third-party analytics, trackers or SDKs that report anywhere, in the app or on the site (non-negotiable 5) [all]

**Never lose it**
- [ ] The sync approach is settled in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) [M4]
- [ ] A second device restores everything from a recovery key [M4]
- [ ] Recovery shipped before or with sync, never after (non-negotiable 4) [M4]

**Keep an inventory**
- [ ] Items have a name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and `visibility` (`private`, `lendable`, `for_sale`; only `private` works yet) [M2]
- [ ] Add, edit, delete and search items, on the device, offline [M2]
- [ ] Photo-first entry with the camera [M3]
- [ ] A barcode scan fills in what it can [M3]
- [ ] Photo-based AI capture is decided in [D5](DECISIONS.md#d5--photo-based-ai-capture), and built if chosen [M3]
- [ ] Locations (garage, basement…), categories and estimated value to find and sort by [M5]
- [ ] Receipts and warranty dates attached to items [M5]

**Built well**
- [ ] `apps/ios/project.yml` generates the app: bundle ID `app.myhutch.ios`, minimum iOS 26 (D7, D8) [M0]
- [ ] From a clean clone, `make setup`, `make test`, `make run` and `make tokens` work in `apps/ios` and at the root, non-interactively; `make test` prints its simulator [M0]
- [ ] Logic (models, crypto, sync) lives in the Swift package and is unit-tested there [M0 on]
- [ ] Every screen has snapshot tests in light and dark mode and at a large Dynamic Type size, with the library recorded in D11 [M2 on]
- [ ] Works on every current iPhone size, in dark mode and with Dynamic Type [M2 on]
- [ ] Colors and sizes are generated from `DESIGN.md`, never hard-coded (D18) [M0 on]
- [ ] `make test` is green at the root [all]
- [x] Logo chosen: house with a keyhole beside the "hutch" wordmark (D17); on the website [B1]
- [ ] Final app icon at all required sizes, from the house-and-keyhole mark [B1]
- [ ] A clean vector master of the logo (the current files are AI-traced) [B1]
- [ ] Type scale, spacing and corner radius in `DESIGN.md` (D18) [B1]
- [ ] Color roles confirmed (proposed in D15; dark roles added in D17) [B1]

**On my phone, and in public**
- [x] myhutch.app explains Hutch, with the privacy policy and support page the App Store requires [W1]
- [ ] The privacy policy matches what the app actually does [T1]
- [ ] A signed build on TestFlight, installed on my phone [T1]
- [ ] The App Store Connect API key is a GitHub secret, never in the repo [T1]

**Proven**
- [ ] The success test passed
- [ ] Personal tool or product is decided in [D6](DECISIONS.md#d6--personal-tool-vs-product)

### Milestones

- **M0 — Monorepo scaffold on the Mac** · next. A clean, repeatable foundation: the XcodeGen project (`app.myhutch.ios`, iOS 26), a Swift package with a first test, the four `make` tasks, an empty screen in generated colors. *Why:* every later session builds, tests and runs on it; without it, no session can prove its work. *Depends on:* Xcode and XcodeGen on the Mac. *Prior work:* [PR #32](https://github.com/chtitoon/hutch/pull/32), branch `1-monorepo-scaffold`: the XcodeGen project, the `HutchCore` package with one test, the iOS and root Makefiles, Swift tokens generated from `design/` (before DESIGN.md), the logo screen and the app icon. Closed, not merged.
- **M1 — Encryption at rest** · later. Nothing about my items is readable on the device without my key. *Why:* zero-knowledge starts on the device (D2): an inventory is a map of my home. It comes before the store so there's never an unencrypted one, not even briefly, and nothing to migrate later. *Depends on:* M0.
- **M2 — Local item store** · later. Add, edit, delete and search my items on the phone, written only through M1's encryption. *Why:* the inventory is the product; capture, sync and sharing all work on these items. *Depends on:* M1; dark-mode color roles in `DESIGN.md` (D15, D17); PR #22's decision on location as free text, confirmed. *Prior work:* [PR #22](https://github.com/chtitoon/hutch/pull/22), branch `2-m1-design-spec`: a screen spec for the item store, written when it was M1 (`apps/ios/design/milestone1.md`), the design canvas export, and two proposed decisions, on location as free text and on the written spec winning over the canvas. Closed, not merged.
- **M3 — Fast capture** · later. Adding an item is fast enough that I actually catalog my things. *Why:* data entry is what kills home-inventory apps (CONTEXT.md), and the success test is about it. *Depends on:* M2; [D5](DECISIONS.md#d5--photo-based-ai-capture) (Open).
- **M4 — Encrypted sync and recovery** · later. My inventory survives a lost phone, and the server still learns nothing. *Why:* with the data on one phone, losing it loses everything, and losing the only key must never do that either (non-negotiable 4). *Depends on:* M2; the sync approach in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) (Proposed).
- **M5 — Organize** · later. Find things by where they are and what they're worth. *Why:* a list only helps if I can find the ladder by where it is, and value, receipts and warranties are what I look things up for. *Depends on:* M2.
- **T1 — First TestFlight build** · later. Hutch on my own phone. *Why:* the success test runs on my phone, with my real things. *Depends on:* Apple Developer Program membership ($99/year).
- **B1 — Final logo and design tokens** · later, alongside the rest. Final artwork and a fuller design system. *Why:* the app needs an icon before TestFlight, and the logo files are AI-traced. *Depends on:* nothing.
- **W1 — Website v1** · done. *Why:* the App Store requires a privacy policy and a support page. [PR #21](https://github.com/chtitoon/hutch/pull/21)
- **W2 — Website performance budgets** · done. *Why:* speed was a value (D14) but nothing checked it (D19). [PR #35](https://github.com/chtitoon/hutch/pull/35)
- **W3 — Font swap no longer shifts the layout** · done. *Why:* visitors saw `/support` jump when the fonts arrived. [PR #35](https://github.com/chtitoon/hutch/pull/35), from closed PR #38

## Phase 2 — Lend to a trusted circle

**Status:** planned. Starts only once Phase 1 is done.

**Goal:** the neighbors I trust can see and borrow the few things I put on the shelf.

**Order:** lendable shelf, invites, loans, revocation.

**Social plan** (matters more than the code): seed with 10-15 of my own items; ask 4-6 trusted neighbors for 2-3 things they'd lend, not a full inventory; support 'anyone have a ladder?' requests (CONTEXT.md).

**Success test:** at least 3 households lending to each other within a month of launch.

### Done when

- [ ] What neighbors who aren't on iPhone get is settled in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) (Phase 2 sharing platform) [M6]
- [ ] A shelf is a separate vault with its own key; moving an item there re-encrypts it under that key [M6]
- [ ] Nothing reaches the shelf without my explicit action (non-negotiable 2) [M6]
- [ ] I invite by link; members receive the shelf key through public-key exchange [M7]
- [ ] Members can share shelves of their own [M7]
- [ ] Request → approved → out → returned, with dates [M8]
- [ ] Condition photos at handoff, and return reminders [M8]
- [ ] "Anyone have a ladder?" requests, not just browsing [M8]
- [ ] Removing a member rotates the shelf key, and tests show they can't read items added afterward [M9]
- [ ] Tests assert everything shared reaches the server as ciphertext only [M6–M9]
- [ ] The success test passed

### Milestones

- **M6 — Lendable shelf** · later. Chosen items on a shelf my circle can see. *Why:* lending starts with choosing what to show; a separate key keeps everything else private. *Depends on:* Phase 1 done; D3's Phase 2 sharing platform.
- **M7 — Circle invites** · later. Invite the few neighbors I trust. *Why:* trust comes from people I already know, not strangers nearby (CONTEXT.md). *Depends on:* M6.
- **M8 — Loans** · later. Lending is easy to request and hard to forget. *Why:* if lending is a chore or things don't come back, neighbors stop lending. *Depends on:* M7.
- **M9 — Revocation** · later. Removing someone actually removes their access. *Why:* without a new key, someone I removed could still read what I add afterward. *Depends on:* M7.

## Phase 3 — Sell

**Status:** planned.

**Goal:** sell an item on eBay straight from my private inventory, decrypting it only on my device.

### Done when

- [ ] I connect my eBay account by OAuth, and the token is stored encrypted [M10]
- [ ] "Sell on eBay" decrypts the item on the device only [M11]
- [ ] It creates a listing through eBay's Sell Inventory API from the item's photos and description [M11]
- [ ] Each item shows a price estimate from comparable sold listings [M12]

### Milestones

- **M10 — eBay connect** · later. Connect my eBay account. *Why:* listing and pricing both go through it. *Depends on:* Phase 1 done.
- **M11 — Sell an item** · later. Sell straight from my inventory. *Why:* selling shouldn't mean retyping an item, or handing my inventory to a server. *Depends on:* M10.
- **M12 — What's it worth?** · later. Know what my things would fetch. *Why:* that's what tells me something is worth selling. *Depends on:* M10.
