# Context

Why Hutch exists and what the research found. Read this before proposing product changes; it explains choices that might otherwise look like gaps.

## Origin

Antoine wanted to borrow things from neighbors for a day (a lawn mower, an extra table) and to lend his own, without putting his household inventory on a public website. He also wanted to sell items on eBay when the time came.

## What already exists (Oct 2026) and why it doesn't fit

- **Public rental marketplaces** (Yoodlize, Leechy, RENTiGO): anyone nearby can see your listings. They depend on local density, which is thin in a small town, and have no private circles.
- **Friend-lending apps** (Mooch, Stuffly, ToolMate): private circles, return tracking, mostly free. Closest in spirit, but inventory sits on the developer's server in readable form, and they're tiny indie apps that may disappear.
- **Invitation-only rental** (Rentodo): adds payments, still a hosted database.
- **Self-hosted inventory** (Homebox): private, but not built for lending, and neighbors can't log into a home server.
- **Notion or a shared spreadsheet:** workable for a handful of households, but cloud-hosted and readable, and every contributor needs an account.

**The gap:** none combines a private, end-to-end encrypted inventory with selective sharing and an optional path to selling.

## Research findings that shape the product

- **Neighbors don't want to catalog their stuff.** The designers of Peerby, an early neighborhood-borrowing service, found people were unwilling to list their inventory and didn't want to charge neighbors, but readily helped when asked for a specific item. Peerby moved from listings to requests. Implications for Hutch:
  - Ask neighbors for "2–3 things you'd lend," never a full inventory.
  - Support requests ("anyone have a ladder?"), not only browsing.
  - Lending is free between neighbors; Hutch doesn't handle payments.
- **Trust comes from existing relationships,** not ratings. Start with 4–6 households who already know each other.
- **Data entry is what kills home-inventory apps.** Capture speed (photo-first, barcode) matters more than features.

## The privacy model, in one line

The 1Password approach: encrypt on device, the server holds only ciphertext, and sharing means giving a small circle the key to one shelf. It protects against the platform, not against the circle — a neighbor who can see an item can screenshot it.

## The selling angle

"A private inventory with a toggle to sell" is a natural bridge to a marketplace like eBay, and an end-to-end encrypted version of it doesn't appear to exist. Hutch is a personal project; whether it ever becomes more is decision D6.

## Hutch vs. a hutch

A hutch has open display shelves above and closed cupboard doors below. In the app: everything starts behind the doors (private); you put chosen items on the shelves (lendable); you take something out for good (sell). Use this metaphor consistently in UI copy.
