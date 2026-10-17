---
# Hutch's plan, phase by phase. The prose below holds each phase's goal and its work items.
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

The plan for Hutch: three phases, each a list of work items.

**How to read it.** Each item has an ID (M0, W1, T1…), a status, why we need it, its goal, a "Done when" checklist and what it depends on.

- **Status:** `done`, `next` (ready to start), `later` (not yet), `blocked` (waiting on something outside the repo).
- **Phases** are `done`, `in-progress` or `planned`, kept in the front matter above.
- Done items collapse to one line with a link to their PR.
- Open questions aren't items: they're **Open** or **Proposed** entries in [DECISIONS.md](DECISIONS.md), and items link the ones they depend on.

Each PR ticks its item's boxes and updates its status here, so the plan changes in the same diff as the code (see the work loop in [AGENTS.md](AGENTS.md)).

## Phase 1 — My private inventory

**Status:** in progress.

**Goal:** I keep a list of my things on my iPhone, and all of it is encrypted, so only I can read it.

**Order:** scaffold, encryption at rest, local store (encrypted from its first version), fast capture, encrypted sync with recovery, organize, then the website (the App Store needs its privacy policy) and a first TestFlight build; the final logo can happen alongside.

**Success test:** 50 real items cataloged within two weeks of fast capture shipping, without forcing it. If not, improve capture before anything else. Don't start Phase 2 until this passes.

### M0 — Monorepo scaffold on the Mac
**Status:** next

**Why:** every later session builds, tests and runs on it; without repeatable tasks, no session can prove its work.

**Goal:** a clean, repeatable foundation every later session builds on.

**Done when:**
- [ ] `apps/ios/project.yml` generates an app with bundle ID `app.myhutch.ios`, minimum iOS 26 (D7, D8)
- [ ] A local Swift package for core logic, with one passing Swift Testing test
- [ ] `apps/ios/Makefile` has `setup`, `test`, `run`, `tokens`, per AGENTS.md; all non-interactive
- [ ] Root `Makefile` delegates (`make test`, `make ios-test`, `make web-test`)
- [ ] `make test` in `apps/ios` is green on a local iPhone simulator, and prints which one
- [ ] The app launches showing an empty "Hutch" screen using colors generated from `DESIGN.md` (D18)
- [ ] `apps/web` has a placeholder page
- [ ] `.claude/settings.json` allows any new commands

**Depends on:** Xcode and XcodeGen installed on the Mac.

**Prior work:** [PR #32](https://github.com/chtitoon/hutch/pull/32), branch `1-monorepo-scaffold`: the XcodeGen project, the `HutchCore` package with one test, the iOS and root Makefiles, Swift tokens generated from `design/` (before DESIGN.md), the logo screen and the app icon. Closed, not merged.

### M2 — Encryption at rest
**Status:** later

**Why:** zero-knowledge starts on the device (non-negotiable 1, D2): an inventory is a map of my home, and it shouldn't be readable without my key. It comes before the item store so that there is never an unencrypted store, not even briefly, and nothing to migrate later.

**Goal:** nothing about my items is readable on the device without my key.

Built ahead of the store, so this item delivers the encryption layer the store writes through, tested on sample item data and photos.

**Done when:**
- [ ] Item data and photos encrypted with CryptoKit, key held in the Keychain
- [ ] Tests assert stored bytes are unreadable
- [ ] The PR explains the crypto choices (AGENTS.md non-negotiable 3)

**Depends on:** M0

### M1 — Local item store
**Status:** later

**Why:** the inventory is the product; encryption, capture, sync and sharing all work on these items.

**Goal:** add, edit, delete and search my items on the phone.

**Done when:**
- [ ] Item model: name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and `visibility` (`private` by default, `lendable`, `for_sale`). The field exists from day one even though only `private` works in Phase 1.
- [ ] Add / edit / delete / search, stored on device with SwiftData; works offline
- [ ] Item data and photos are written only through M2's encryption; tests assert nothing reaches disk in plaintext
- [ ] Screens, states, navigation and copy match `apps/ios/design/milestone1.md` (PR #22's decision on the written spec)
- [ ] Model logic unit-tested in the Swift package
- [ ] Snapshot-testing library chosen with me and recorded in D11
- [ ] Snapshot tests for the list and edit screens: light, dark and large Dynamic Type; the reference images appear in the PR

**Depends on:** M2; dark-mode color roles in `DESIGN.md` (D15; added in D17); PR #22's decision on location as free text, confirmed. Spec: `apps/ios/design/milestone1.md` (PR #22).

**Prior work:** [PR #22](https://github.com/chtitoon/hutch/pull/22), branch `2-m1-design-spec`: the M1 screen spec (`apps/ios/design/milestone1.md`), the design canvas export (`apps/ios/design/canvas/`), and two proposed decisions, on location as free text and on the written spec winning over the canvas. Closed, not merged, so the spec this item points to isn't on `main`.

### M3 — Fast capture
**Status:** later

**Why:** data entry is what kills home-inventory apps (CONTEXT.md), and the Phase 1 success test is about it.

**Goal:** adding an item is fast enough that I actually catalog my things. Most inventory apps die here.

**Done when:**
- [ ] Photo-first entry with the camera
- [ ] Barcode scan fills in what it can
- [ ] AI-capture decision settled ([D5](DECISIONS.md#d5--photo-based-ai-capture))

**Depends on:** M1; [D5](DECISIONS.md#d5--photo-based-ai-capture), photo-based AI capture (Open)

### M4 — Encrypted sync and recovery
**Status:** later

**Why:** with the data on one phone only, losing the phone loses the inventory; and losing the only key must never lose it either (non-negotiable 4).

**Goal:** my inventory survives a lost phone, and the server still learns nothing.

**Done when:**
- [ ] Sync approach settled ([D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo), sync)
- [ ] A second device restores everything from a recovery key
- [ ] Tests assert synced payloads contain no plaintext
- [ ] Recovery ships before or with sync, never after (non-negotiable 4)

**Depends on:** M2; the sync approach in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) (Proposed)

### M5 — Organize
**Status:** later

**Why:** a list only helps if I can find the ladder by where it is, and value, receipts and warranty dates are what I look things up for.

**Goal:** find things by where they are and what they're worth.

**Done when:**
- [ ] Locations (garage, basement…), categories, estimated value
- [ ] Receipts and warranty dates attached to items

**Depends on:** M1

### W1 — Website v1 · done
Why: the App Store requires a privacy policy and a support page, and myhutch.app says what Hutch is. [PR #21](https://github.com/chtitoon/hutch/pull/21)

### W2 — Website performance budgets · done
Why: speed was a value (D14) but nothing checked it; now `npm test` and Lighthouse do (D19). [PR #35](https://github.com/chtitoon/hutch/pull/35)

### W3 — Font swap no longer shifts the layout · done
Why: real visitors saw `/support` jump when the web fonts arrived, the site's only layout shift. Fixed by sized fallback fonts, from closed PR #38, landed in [PR #35](https://github.com/chtitoon/hutch/pull/35)

### T1 — First TestFlight build
**Status:** later

**Why:** the Phase 1 success test runs on my own phone, with my real things.

**Goal:** Hutch on my own phone, so I can start the Phase 1 success test.

**Done when:**
- [ ] Signed build uploaded to TestFlight
- [ ] I install it on my phone
- [ ] App Store Connect API key stored as a GitHub secret, never in the repo

**Depends on:** Apple Developer Program membership ($99/year).

### B1 — Final logo and design tokens
**Status:** later (alongside the rest of Phase 1)

**Why:** the app needs an icon before TestFlight, and the current logo files are AI-traced, not clean artwork.

**Goal:** turn the chosen logo into final artwork and a fuller design system.

**Done when:**
- [x] Logo chosen: house with a keyhole beside the "hutch" wordmark (D17, replaces the carved-"h" direction); on the website
- [ ] App icon at all required sizes, from the house-and-keyhole mark
- [ ] Clean vector master of the logo (current files are AI-traced)
- [ ] Type scale, spacing and corner radius in the root `DESIGN.md`, now the source of truth (D18)
- [ ] Color roles confirmed (currently proposed; dark roles added in D17)

**Depends on:** nothing.

## Phase 2 — Lend to a trusted circle

**Status:** planned. Starts only once Phase 1's success test passes.

**Goal:** the neighbors I trust can see and borrow the few things I put on the shelf.

**Order:** lendable shelf, invites, loans, revocation.

**Social plan** (matters more than the code): seed with 10-15 of my own items; ask 4-6 trusted neighbors for 2-3 things they'd lend, not a full inventory; support 'anyone have a ladder?' requests (CONTEXT.md).

**Success test:** at least 3 households lending to each other within a month of launch.

Items stay one line each until the phase starts; then each expands to the full form, with a checklist.

**Open decision:** what neighbors who aren't on iPhone get ([D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo), Phase 2 sharing platform). Settle before M6.

- **M6 — Lendable shelf** · later. *Why:* lending starts with choosing what to show; a separate key keeps everything else private. Done when: a separate vault with its own key; moving an item there re-encrypts it under that key; platform for sharing settled (D3). Depends on: Phase 1 success test passed; D3's Phase 2 sharing platform.
- **M7 — Circle invites** · later. *Why:* trust comes from people I already know, not from strangers nearby (CONTEXT.md). Done when: invite by link; members receive the shelf key through public-key exchange; members can share shelves of their own. Depends on: M6.
- **M8 — Loans** · later. *Why:* lending is easy to request and hard to forget, or neighbors stop lending. Done when: request → approved → out → returned, with dates; condition photos at handoff; return reminders; "Anyone have a ladder?" requests, not just browsing (CONTEXT.md). Depends on: M7.
- **M9 — Revocation** · later. *Why:* without a new key, someone removed from my circle could still read what I add afterward. Done when: removing a member rotates the shelf key; tests show they can't read items added afterward. Depends on: M7.

## Phase 3 — Sell

**Status:** planned.

**Goal:** sell an item on eBay straight from my private inventory, decrypting it only on my device.

Items stay one line each until the phase starts.

- **M10 — eBay connect** · later. *Why:* listing and pricing both go through my eBay account. Done when: OAuth to eBay; token stored encrypted. Depends on: nothing.
- **M11 — Sell an item** · later. *Why:* selling what I no longer need shouldn't mean retyping it, or handing my inventory to a server. Done when: "Sell on eBay" decrypts the item on device only; creates a listing through eBay's Sell Inventory API from its photos and description. Depends on: M10.
- **M12 — What's it worth?** · later. *Why:* knowing what something would fetch is what tells me it's worth selling. Done when: price estimate from comparable sold listings, shown per item. Depends on: M10.
