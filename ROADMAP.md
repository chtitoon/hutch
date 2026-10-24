---
# One phase per outcome. Each `public` block mirrors a "Where we're heading" card, hard-coded today
# in apps/web/src/pages/index.astro: change both together. Everything else here stays internal.
#
# status: done | in-progress | later
# public.icon: private | lend | sell (the StageIcon.astro icons)
phases:
  - id: o1
    title: I know what I own and where it is
    status: in-progress
    public:
      name: Behind closed doors
      icon: private
      badge: At launch
      description: "Snap it, name it, say where it lives. Everything you add is private by default."
  - id: o2
    title: Neighbors lend to each other
    status: later
    public:
      name: A few things on the shelf
      icon: lend
      badge: Planned
      description: "Choose what to lend to people you trust: the ladder, the tent, the pasta maker…"
  - id: o3
    title: I let go of things I don't use
    status: later
    public:
      name: Out the door
      icon: sell
      badge: Planned
      description: "When it’s time, sell what you no longer need straight from your inventory."
---

# Roadmap

Where Hutch is going, and what's next. What already happened is in [LEARNED.md](LEARNED.md), and why the roadmap works this way is in [D22](DECISIONS.md#d22--an-outcome-roadmap-bets-and-experiments).

## Why Hutch exists

I wanted to borrow a lawn mower from a neighbor for a day, and lend my own things in return, without putting a list of everything in my home on someone else's website. One day I'd also like to sell what I no longer use, without typing it all out again.

So Hutch is first the app I wish I had. I snap a photo of something, and I know what I own, where it is and what it's worth, and nobody else can see it. It's mostly for me. If the people around me find it useful too, even better.

It's also how I learn. I'd rather try new tools on an app I actually use than on a tutorial.

## Keeping it fun

If building Hutch feels like a chore two weeks in a row, the next thing I pick is something I'm excited to try.

## Outcomes

#### <a id="o1"></a>O1 — I know what I own and where it is
- **Early signal:** 20 items in my first week; adding one takes under 20 s.
- **Proof:** 50 items, still accurate two months later, used at least 3 times to find, prove or decide something.
- **Comes first:** nothing for other people gets built until I'm using Hutch myself, past O1's early signal.

#### <a id="o2"></a>O2 — Neighbors lend to each other
- **Early signal:** when a neighbor asks for something, I answer from Hutch.
- **Proof:** 3 households lending within a month; an "anyone have a ladder?" request answered.

#### <a id="o3"></a>O3 — I let go of things I don't use
- **Proof:** 5 items sold from Hutch, each listed faster than with the eBay app.

## Now

At most two bets and one experiment.

#### <a id="h1"></a>H1 — I'll keep an inventory if Hutch makes it effortless
**Serves:** [O1](#o1). **Status:** started 2026-10-24; building until 2026-11-14 at the latest. **Appetite:** 3 weeks to build, then 1 week of use on my phone.
- **Test:** the first Hutch app. It opens on the camera; one tap, and an on-device model turns the photo into an item ([X4](#x4)); I confirm the name and say where it lives: a room from Apple Home or one I've used, plus a spot if I like ([D25](DECISIONS.md#d25--where-it-lives-an-apple-home-room-and-an-optional-spot)). A list shows each item's photo, name and place. When time runs short, everything else is cut first.
- **Reshaped 2026-10-24, before any use:** no resale price for now, and the model's category is kept but not shown. Both slowed adding an item without serving the signal.
- **Guardrails,** which no appetite cuts:
  - Encrypted at rest from the first write, with the key in the Keychain ([non-negotiable 1](AGENTS.md#non-negotiables), [D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)).
  - New items are private.
  - Every screen has snapshot tests.
- **Learning goals:**
  - Ship a SwiftUI app to my own phone.
  - Write Swift 6 with strict concurrency, without silencing a warning.
  - Encrypt with CryptoKit, and be able to explain each choice.
  - The photo models are [X4](#x4).
- **Prior work:** [#32](https://github.com/chtitoon/hutch/pull/32).
- **Counted on the phone:** the item list's footer shows the item count, the median time from shutter to Save, how many took under 20 s, and how often I kept the suggested name ([X4](#x4)). None of it is sent anywhere.
- **Signal:** 20 items in my first week of use, each added in under 20 s (timed on the phone, never sent), with a note each time I stop and each time I look something up.
- **If yes:** keep building [O1](#o1) (barcode, search), then [H3](#h3). **If no:** my notes say whether it was speed (reshape capture) or motivation (O1 shrinks to what's worth lending, selling or insuring).

#### <a id="x4"></a>X4 — Photo to item, with on-device models
**Tried on:** [H1](#h1). **Status:** started 2026-10-24, with H1.
- **Learning goals:**
  - Know what Vision recognizes from one photo of a household thing.
  - Use the Foundation Models framework to turn that into a name and category.
  - Know when Core ML is worth it, if neither is enough.
- **Question going in:** do I accept its suggestion as is for at least 7 items in 10, in under 2 seconds on my phone? Photos never leave the device ([D5](DECISIONS.md#d5--photo-based-ai-capture)).
- **Verdict decides:** D5. Resale guesses wait for selling ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)).

#### <a id="x5"></a>X5 — Photo to product, with a catalog on the phone
**Tried on:** [H1](#h1). **Status:** started 2026-10-24. It's X4's third learning goal ("when Core ML is worth it"), split out because it's big; it shares X4's lane in Now. **Appetite:** 2 weeks, gated after phase 2.
- **Why:** Apple's on-device models named my MacBook Air "Computer" ([E3](LEARNED.md#e3)). Image embeddings matched against a catalog of names got the right kind for 4 of 4 of my photos ([E4](LEARNED.md#e4)), with nothing sent.
- **Learning goals:**
  - Build a product catalog from open data and embed it with SigLIP 2.
  - Convert an image encoder to Core ML and prove it matches PyTorch.
  - Know how far the right kind, brand and model can go without a network.
- **How it works:**
  - **On the Mac:** an index builder embeds catalog names, and later product images, with SigLIP 2.
  - **On the phone:** only the image half runs (Core ML). It looks up, strongest evidence first:
    1. barcode
    2. model number read on the item
    3. nearest catalog entries
  - **Confirmed by me:** the result is always a suggestion, gated by confidence.
- **Phases,** each ending with my review:
  1. **Plan:** sizes, layout, licenses. In [#53](https://github.com/chtitoon/hutch/pull/53).
  2. **Prototype and eval** on my own photos: category accuracy, top-5 hit rate, a threshold sweep. **Gate:** 90% right at the category level I'd accept (for example "Laptops", not leaf SKUs), on 20+ of my photos.
  3. **Core ML conversion:** cosine similarity of at least 0.99 against PyTorch; latency on my phone.
  4. **Swift pipeline** behind protocols, with a debug screen showing the evidence.
  5. **Integration** into adding an item, and `make catalog` to rebuild the index.
- **Guardrails:**
  - No network call in the lookup, with a test that fails if one is made.
  - My photos never enter the repo.
  - Nothing bundled whose license is unclear ([D27](DECISIONS.md#d27--a-product-catalog-on-the-phone-siglip-2-open-data-licenses-first)).
- **Verdict decides:** whether the catalog ships with H1's successor, and [D26](DECISIONS.md#d26--identifying-a-product-online-by-choice) (online identification), which a good result makes unnecessary.

#### <a id="h2"></a>H2 — When a neighbor asks, I answer from Hutch
**Serves:** [O2](#o2). **Status:** counting starts now; building needs [H1](#h1)'s items. **Appetite:** 1 week to build, then a month of use.
- **We believe:** neighbors ask for things more than they browse ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product): Peerby moved from listings to requests), and answering "I have one" with the item makes lending happen.
- **First, no code:** for 2 weeks, count the "anyone have a…?" requests in my neighborhood texts and chats. If there are none, there's nothing to answer: H2 waits.
- **Test:** on an item, one tap shares a card (photo, name, "happy to lend it") into the text thread through the share sheet. One item, never the inventory; nothing goes through a server, and they need no app.
- **Signal:** 3 requests answered from Hutch within a month, at least one ending in a loan.
- **If yes:** a link that opens the item for someone without Hutch, end-to-end encrypted, then loans and return reminders. **If no:** O2 moves to Later.
- **Needs:** [D24](DECISIONS.md#d24--sending-one-item-to-someone-i-choose) decided: today non-negotiable 1 says photos and names never leave the device, even when I send them.

## Next

Riskiest first.

1. <a id="x3"></a>**X3 — OpenSpec.** Tried on [H1](#h1). Does a spec per change make an agent's work better than a checklist, or just add a second plan to keep in sync?
2. <a id="h3"></a>**H3 — My inventory survives a lost phone.** Serves [O1](#o1). Once I rely on it. Sync and recovery, together ([non-negotiable 4](AGENTS.md#non-negotiables), [D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)). Needs [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)'s sync approach confirmed.

## Later

No order, no detail.

- **Organize:** locations, categories, value, receipts, warranties. If [H1](#h1) shows lookups are what I use it for.
- **Lending:** shaped by [H2](#h2): loans, return reminders, and maybe a shared vault neighbors add to (every member would hold its key, removing one re-keys it for all, and CloudKit sharing only reaches Apple users, [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)).
- **Selling:** eBay connect, listing, price estimates from sold listings ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)). After [O1](#o1): an empty inventory has nothing to sell.
- **App icon and final logo:** the icon comes with [H1](#h1)'s first build on my phone.
- **App Store release:** needs [D6](DECISIONS.md#d6--personal-tool-vs-product) and the name revisited ([D1](DECISIONS.md#d1--name-and-domain-hutch-myhutchapp)).
