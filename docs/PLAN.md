# Plan

Three phases. Each has a success test; don't start the next phase until the current one passes. Milestones are sized so one Claude Code session from a phone can finish one.

## Phase 1 — My private inventory

Goal: Antoine catalogs his own things in an app that knows nothing he hasn't encrypted.

| # | Milestone | Done when |
|---|-----------|-----------|
| M0 | Confirm D3 (platform) and scaffold the project | App deploys to myhutch.app; CI runs tests on every push |
| M1 | Local item store | Add / edit / delete / search items in IndexedDB; works offline |
| M2 | Encryption at rest | Items and photos encrypted with a key derived from a passphrase; nothing readable in storage devtools |
| M3 | Fast capture | Photo-first entry, barcode scan; decide D5 (AI capture) |
| M4 | Encrypted sync + recovery | Ciphertext synced to Cloudflare; second device restores from passphrase + recovery kit; server holds no plaintext (verified by test) |
| M5 | Organize | Locations (garage, basement…), categories, value, receipts, warranty dates |

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

Payments between neighbors (Venmo/Zelle is fine), public marketplace, native apps, a dedicated "neighborhood" discovery feature.
