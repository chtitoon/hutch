# Decisions

Each entry: what, status, and why. "Decided" means Antoine chose it; "Proposed" means it's a recommendation awaiting his confirmation.

## D1 — Name and domain: Hutch, myhutch.app
**Status:** Decided (domain registered on Cloudflare, Oct 2026).

**Why:** Short, spelled as said, concrete image. A hutch has open shelves above and closed doors below, which maps onto private-by-default with selective display.

**Known risks:** "Hutch" is crowded — hutch.app (2018), gethutch.app (a live "AI assistants for your family" product, private/family positioning, 2026), thehutch.app (2026), plus a Sri Lankan telecom brand. Fine for a personal/neighborhood tool. **Revisit before any public launch.** Rejected alternatives: Armoire (hard to spell), Cubby (cubby.app $15k), Tallboy (US beer association), Lendery (sounds like a lender), Baoo (ambiguous pronunciation, baoo.app taken).

## D2 — Privacy model: end-to-end encrypted, zero-knowledge
**Status:** Decided (core requirement).

**Why:** Antoine does not want a database on the web that knows what he owns. The 1Password model: encrypt on device, server stores ciphertext only, sharing via per-vault keys.

**Consequences:** server can't search, match requests or send content-rich notifications; all of that runs on device. Key loss = data loss, so recovery (an emergency kit / recovery key) is a Phase 1 requirement, not an afterthought. Sharing protects against the platform, not against the circle — a neighbor who can see an item can screenshot it.

## D3 — Platform: installable web app (PWA) on Cloudflare
**Status:** Proposed — confirm before building.

**Why this over native iOS + CloudKit (the earlier recommendation):**
1. Development happens from a phone via Claude Code on the web, which runs on Linux. It cannot build or run an iOS app (no Xcode/macOS). A web app can be built, tested and deployed entirely from there.
2. Neighbors may be on Android. CloudKit sharing is Apple-only, which would force a rewrite at Phase 2.
3. It uses the domain directly: myhutch.app *is* the app. No App Store review.
4. `.app` requires HTTPS, which Cloudflare provides for free.

**Trade-offs accepted:** web crypto and storage are slightly less robust than native keychains; camera/barcode capture works but is less polished than native; iOS can evict PWA storage if unused for weeks, so encrypted sync/backup must ship in Phase 1.

**Proposed stack:** TypeScript, a light framework (SvelteKit or React + Vite), IndexedDB locally, WebCrypto (AES-GCM for data, PBKDF2/Argon2 for key derivation), Cloudflare Pages + Workers + D1/R2 storing only encrypted blobs.

## D4 — Build order: personal first, sharing later
**Status:** Decided in principle.

**Why:** most home-inventory apps die from abandoned data entry, not missing features. Phase 2 sharing (invites, identity, key rotation on revocation) is far more complex than Phase 1, and only worth building once Antoine has proven he keeps the inventory up to date.

## D5 — Photo-based AI capture
**Status:** Open.

**Tension:** sending photos to a cloud model to auto-fill items breaks zero-knowledge. Options: manual entry + barcode only; on-device model; or explicit opt-in per photo with a clear warning. Decide during Phase 1, milestone M3.

## D6 — Personal tool vs. product
**Status:** Open — decide after Phase 1.

Drives whether to rename (see D1), invest in multi-platform polish, or pursue the eBay angle more seriously.
