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
3. UI is checked with simulator screenshots, then on my phone through TestFlight.

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

**Why:** `project.yml` (XcodeGen) is the source of truth. Generated `.xcodeproj` files cause merge conflicts and are hard for agents to edit safely. Trade-off: after cloning, run `apps/ios/scripts/setup` before opening the project in Xcode.

## D10 — Work tracked in GitHub issues and milestones
**Status:** Decided (Oct 2026).

**Why:** issues show up in the GitHub app on my phone, PRs close them automatically, and the history is kept. Milestones are the three phases; issues are the units of work, each with a "Done when." The milestone descriptions hold each phase's goal, order and success test; durable reasoning stays in these docs. There is no separate plan file, because a second copy of the plan would drift.

## D11 — Screenshots live on an orphan branch, shown in PR comments
**Status:** Decided (Oct 2026).

**Why:** I review UI changes from my phone, so they belong in the PR. Committing images to `main` would bloat the repo forever; an orphan `screenshots` branch keeps them out of the code history while still displaying in PR comments.

## D12 — Agents can't merge
**Status:** Decided (Oct 2026).

**Why:** every change gets one human look before it lands. Agent settings deny merging and pushing to `main`.

## D13 — Out of scope, for now
**Status:** Decided (Oct 2026).

- **Payments between neighbors:** Venmo or Zelle is fine, and the research found neighbors prefer lending for free (docs/context.md).
- **A public marketplace:** the opposite of private by default.
- **An Android app:** iPhone first (D3). Android neighbors are handled in the Phase 2 sharing decision.
- **Neighborhood discovery:** trust comes from people who already know each other, not from finding strangers nearby.
