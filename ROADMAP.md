---
# Hutch's plan, phase by phase. The prose below holds each phase's goal, success test and milestones.
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

The plan for Hutch: three phases, each a goal, a success test and the milestones that get there.

**How to read it.**

- **Milestones** are in build order: each builds on those above it. Each has a goal, why we need it, and its **Definition of Done**: the boxes that must all be ticked. **Requires** appears only when something outside the list must come first: a decision, an account, a test passed.
- A **phase** is done when all its milestones are done and its success test passed. Its status (`done`, `in-progress`, `planned`) is in the front matter above.
- A milestone's **status** is written only when it's news: `in progress` or `done`, with the PR, or `blocked`, with why. None means not started. What's next is the first milestone not done.
- The rules every milestone follows (the non-negotiables, tests, design) are in [AGENTS.md](AGENTS.md), not repeated here. Open questions are in [DECISIONS.md](DECISIONS.md).

Each PR ticks the boxes it proves, here, in the same diff as the code.

## Phase 1 — My private inventory

**Goal:** I keep a list of my things on my iPhone, and all of it is encrypted, so only I can read it.

**Success test:** 50 real items cataloged within two weeks of fast capture shipping, without forcing it. If not, improve capture before anything else. Don't start Phase 2 until this passes.

#### M0 — Monorepo scaffold on the Mac
A clean, repeatable foundation every later session builds on.

**Why:** every later session builds, tests and runs on it; without it, no session can prove its work.

**Requires:** Xcode and XcodeGen on the Mac.

**Prior work:** [PR #32](https://github.com/chtitoon/hutch/pull/32), branch `1-monorepo-scaffold`: the XcodeGen project, the `HutchCore` package with one test, the iOS and root Makefiles, Swift tokens generated from `design/` (before DESIGN.md), the logo screen and the app icon. Closed, not merged.

**Definition of Done:**
- [ ] `apps/ios/project.yml` generates the app: bundle ID `app.myhutch.ios`, minimum iOS 26 ([D7](DECISIONS.md#d7--bundle-id-appmyhutchios), [D8](DECISIONS.md#d8--minimum-ios-version-ios-26))
- [ ] A local Swift package for core logic, with one passing Swift Testing test
- [ ] `setup`, `test`, `run` and `tokens` work in `apps/ios`, and the root `Makefile` delegates; `make test` prints its simulator
- [ ] The app launches to an empty "Hutch" screen in colors generated from [DESIGN.md](DESIGN.md)

#### M1 — Encryption at rest
Nothing about my items is readable on the device without my key.

**Why:** an inventory is a map of my home ([D2](DECISIONS.md#d2--privacy-model-end-to-end-encrypted-zero-knowledge)). Built before the store, so there's never an unencrypted one and nothing to migrate.

**Definition of Done:**
- [ ] Item data and photos are encrypted with CryptoKit before anything is written, with the key in the Keychain
- [ ] Tests assert that nothing written to disk contains plaintext

#### M2 — Local item store
My items on the phone, written only through M1's encryption.

**Why:** the inventory is the product; capture, sync and sharing all work on these items.

**Requires:** [PR #22](https://github.com/chtitoon/hutch/pull/22)'s decision on location as free text, decided (never merged).

**Prior work:** [PR #22](https://github.com/chtitoon/hutch/pull/22), branch `2-m1-design-spec`: a screen spec for the item store, written when it was M1 (`apps/ios/design/milestone1.md`), the design canvas export, and two proposed decisions, on location as free text and on the written spec winning over the canvas. Closed, not merged.

**Definition of Done:**
- [ ] Items have a name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and `visibility` (`private`, `lendable`, `for_sale`; only `private` works yet)
- [ ] Add, edit, delete and search items, offline
- [ ] Opening Hutch, or coming back to it, needs Face ID or the device passcode
- [ ] The snapshot-testing library is chosen with me and recorded in [D11](DECISIONS.md#d11--ui-review-through-snapshot-tests)

#### M3 — Fast capture
Adding an item is fast enough that I actually catalog my things.

**Why:** data entry is what kills home-inventory apps ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product)), and the success test is about it.

**Requires:** [D5](DECISIONS.md#d5--photo-based-ai-capture) decided (Open today).

**Definition of Done:**
- [ ] Photo-first entry with the camera
- [ ] A barcode scan fills in what it can
- [ ] Photo-based AI capture built, if D5 chooses it

#### M4 — Encrypted sync and recovery
My inventory survives a lost phone, and the server still learns nothing.

**Why:** on one phone, losing it loses everything; and losing the only key must never do that either ([non-negotiable 4](AGENTS.md#non-negotiables)).

**Requires:** the sync approach in [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo) confirmed (Proposed today).

**Definition of Done:**
- [ ] My items sync between my devices as ciphertext only
- [ ] A new iPhone signed into my Apple account gets the key through iCloud Keychain and restores everything ([D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit))
- [ ] A printable recovery kit restores everything on a new device without my Apple account

#### M5 — Organize
Find things by where they are and what they're worth.

**Why:** a list only helps if I can find the ladder by where it is; value, receipts and warranties are what I look things up for.

**Definition of Done:**
- [ ] Locations (garage, basement…), categories and estimated value to find and sort by
- [ ] Receipts and warranty dates attached to items

#### B1 — Final logo and design tokens
Final artwork and a fuller design system.

**Why:** TestFlight needs an app icon, and the logo files are AI-traced.

**Definition of Done:**
- [x] Logo chosen: house with a keyhole beside the "hutch" wordmark ([D17](DECISIONS.md#d17--the-house-and-keyhole-logo-and-dark-mode-on-the-website)); on the website
- [ ] App icon at all required sizes, from the house-and-keyhole mark
- [ ] A clean vector master of the logo
- [ ] Type scale, spacing and corner radius in DESIGN.md ([D18](DECISIONS.md#d18--designmd-is-the-design-systems-source-of-truth-enforced-on-both-sides))
- [ ] Color roles confirmed ([D15](DECISIONS.md#d15--palette-forest-warm-grey-and-brass-self-hosted-web-fonts))

#### T1 — First TestFlight build
Hutch on my own phone.

**Why:** the success test runs on my phone, with my real things.

**Requires:** Apple Developer Program membership ($99/year).

**Definition of Done:**
- [ ] A signed build on TestFlight, installed on my phone
- [ ] The App Store Connect API key is a GitHub secret, never in the repo
- [ ] The privacy policy on myhutch.app matches what the app does

#### A1 — App Store release
Hutch public on the App Store.

**Why:** "At launch" on the site means anyone can get it, not just me.

**Requires:** the success test passed.

**Definition of Done:**
- [ ] The name is revisited before going public, as [D1](DECISIONS.md#d1--name-and-domain-hutch-myhutchapp) requires
- [ ] Live on the App Store, with an App Privacy label that says no data is collected
- [ ] The site's "Coming to iPhone" pill becomes the App Store link

#### W1 — Website v1
**Status:** done, [PR #21](https://github.com/chtitoon/hutch/pull/21). **Why:** the App Store requires a privacy policy and a support page.

#### W2 — Website performance budgets
**Status:** done, [PR #35](https://github.com/chtitoon/hutch/pull/35). **Why:** speed was a value ([D14](DECISIONS.md#d14--website-astro-static-output)) but nothing checked it ([D19](DECISIONS.md#d19--website-performance-one-file-budgets-at-the-deploy-gate-lighthouse-on-pull-requests)).

#### W3 — Font swap no longer shifts the layout
**Status:** done, [PR #35](https://github.com/chtitoon/hutch/pull/35), from closed [PR #38](https://github.com/chtitoon/hutch/pull/38). **Why:** visitors saw `/support` jump when the fonts arrived.

#### W4 — Text never changes once drawn
**Status:** in progress. **Why:** W3 kept blocks of text in place, but the swap from Arial to the web fonts still showed: letters changed shape, words shifted and two headings rewrapped, so the page looked like it moved on arrival.

- [x] Fonts are preloaded and `font-display: optional`: used from the first paint when they arrive in time, never swapped in later
- [x] With fonts delayed 1.5 s, headings keep their positions after first paint (they moved on main); with fonts delayed 30 ms, the headline renders in Bricolage Grotesque

## Phase 2 — Lend to a trusted circle

**Goal:** the neighbors I trust can see and borrow the few things I put on the shelf.

**Social plan** (matters more than the code): seed with 10-15 of my own items; ask 4-6 trusted neighbors for 2-3 things they'd lend, not a full inventory; support 'anyone have a ladder?' requests ([CONTEXT.md](CONTEXT.md#the-social-plan-for-lending)).

**Success test:** at least 3 households lending to each other within a month of launch.

#### M6 — Lendable shelf
Chosen items on a shelf my circle can see.

**Why:** lending starts with choosing what to show; a separate key keeps everything else private.

**Requires:** [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)'s Phase 2 sharing platform decided.

**Definition of Done:**
- [ ] A shelf is a separate vault with its own key
- [ ] Moving an item there re-encrypts it under that key

#### M7 — Circle invites
Invite the few neighbors I trust.

**Why:** trust comes from people I already know, not strangers nearby ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product)).

**Definition of Done:**
- [ ] Invite by link; members receive the shelf key through public-key exchange
- [ ] Members can share shelves of their own

#### M8 — Loans
Lending is easy to request and hard to forget.

**Why:** if lending is a chore or things don't come back, neighbors stop lending.

**Definition of Done:**
- [ ] Request → approved → out → returned, with dates
- [ ] Condition photos at handoff, and return reminders
- [ ] "Anyone have a ladder?" requests, not just browsing

#### M9 — Revocation
Removing someone actually removes their access.

**Why:** without a new key, someone I removed could still read what I add afterward.

**Definition of Done:**
- [ ] Removing a member rotates the shelf key
- [ ] Tests show they can't read items added afterward

## Phase 3 — Sell

**Goal:** sell an item on eBay straight from my private inventory, decrypting it only on my device.

#### M10 — eBay connect
Connect my eBay account.

**Why:** listing and pricing both go through it.

**Definition of Done:**
- [ ] OAuth to eBay, with the token stored encrypted

#### M11 — Sell an item
Sell straight from my inventory.

**Why:** selling shouldn't mean retyping an item, or handing my inventory to a server.

**Definition of Done:**
- [ ] "Sell on eBay" decrypts the item on the device only
- [ ] It creates a listing through eBay's Sell Inventory API from the item's photos and description

#### M12 — What's it worth?
Know what my things would fetch.

**Why:** that's what tells me something is worth selling.

**Definition of Done:**
- [ ] Each item shows a price estimate from comparable sold listings
