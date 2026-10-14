# Plan

## Now

**M0 — Monorepo scaffold on the Mac.** Blocked until Xcode and XcodeGen are installed (see "Before M0" at the bottom).

*Agents: update this section in every PR that finishes a milestone. Completed milestones are marked ✅ in the tables.*

---

Three phases. Each has a success test; don't start the next phase until the current one passes. Milestones are sized so one agent session can finish one.

## Phase 1 — My private inventory

Goal: Antoine catalogs his own things in an app that knows nothing he hasn't encrypted.

| # | Milestone | Done when |
|---|-----------|-----------|
| M0 | Monorepo scaffold on the Mac | `apps/ios` generates from `project.yml`, builds and passes tests on a local iPhone simulator, and launches showing an empty "Hutch" screen; `apps/web` has a placeholder page |
| W1 | Website v1 | Landing page, privacy policy and support page live at myhutch.app (the App Store requires the last two) |
| M1 | Local item store | Add / edit / delete / search items on device (SwiftData); works offline; model logic unit-tested |
| M2 | Encryption at rest | Item data and photos encrypted with a key held in the Keychain; tests assert stored bytes are unreadable |
| M3 | Fast capture | Photo-first entry and barcode scan with the camera; decide D5 (AI capture) |
| M4 | Encrypted sync + recovery | Confirm the sync choice in D3; second device restores from a recovery key; tests assert synced payloads hold no plaintext |
| M5 | Organize | Locations (garage, basement…), categories, value, receipts, warranty dates |
| T1 | First TestFlight build | Antoine installs Hutch on his phone from TestFlight (needs the Apple Developer Program) |

**Item model (starting point):** name, photos, category, location, condition, estimated value, purchase date, receipt, notes, and a `visibility` field: `private` (default) / `lendable` / `for_sale`. The field exists from day one even though only `private` works in Phase 1.

**Success test:** 50 real items cataloged within two weeks of M3, without forcing it. If not, improve capture before anything else.

## Phase 2 — Lend to a trusted circle

| # | Milestone | Done when |
|---|-----------|-----------|
| M6 | Lendable shelf | A separate vault with its own key; moving an item there re-encrypts it under that key |
| M7 | Circle invites | Invite by link; members get the shelf key via public-key exchange; members can list their own shelves |
| M8 | Loans | Request → approved → out → returned, with dates, condition photos at handoff, reminders |
| M9 | Revocation | Removing a member rotates the shelf key; they can't read items added afterward |

**Social plan (matters more than the code):** seed with 10–15 of Antoine's own items; ask 4–6 trusted neighbors for "2–3 things you'd lend," not a full inventory; support "anyone have a ladder?" requests, not just listings.

**Success test:** at least 3 households lending to each other within a month of launch.

## Phase 3 — Sell

| # | Milestone | Done when |
|---|-----------|-----------|
| M10 | eBay connect | OAuth to eBay; token stored encrypted |
| M11 | Sell an item | "Sell on eBay" decrypts the item on device and creates a listing through the Sell Inventory API from its photos and description |
| M12 | What's it worth? | Price estimate from comparable sold listings, shown per item |

## Not doing (for now)

Payments between neighbors (Venmo/Zelle is fine), public marketplace, an Android app, a dedicated "neighborhood" discovery feature.

## Before M0 (Antoine)

- Clone the repo on the Mac: `git clone https://github.com/chtitoon/hutch ~/Projects/hutch`, and run the coding agent from that folder.
- Confirm Xcode is installed (and Homebrew, for `brew install xcodegen`).
- Create the empty private repo `chtitoon/hutch` for backup and history.
- Join the Apple Developer Program ($99/year) before T1; App Store Connect API keys go into GitHub secrets for TestFlight uploads.
- Point myhutch.app at Cloudflare Pages when W1 is ready.
