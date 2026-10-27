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
- **Test:** the first Hutch app. It opens on Home: rooms, search and what I added lately. A + opens the camera; I take a photo, name it, and say where it lives: a room from Apple Home or one I've used, or one I type when there's none ([D25](DECISIONS.md#d25--where-it-lives-a-room)). Later, an on-device model suggests the name ([X4](#x4)). When time runs short, everything else is cut first.
- **Milestones,** one PR each, each usable on my phone:
  1. **An inventory by hand:** an item is a name and a room, with its photo, encrypted. Home, room and item screens in the brand, and the app icon.
  2. **Named on the phone** ([X4](#x4)): Vision and Apple Intelligence suggest the name while a scanner sweeps the photo.
     - First, the photo is cleaned up: Vision cuts the item out, with an Undo ([D26](DECISIONS.md#d26--photos-are-cut-out-on-the-phone-and-stored-as-heic)), so naming starts from the item alone.
  3. **A product catalog** (X5, its own experiment, coming with that PR): matched on the phone for specific names.
  4. **A widget** that opens straight on the camera, to add in one go.
- **Reshaped 2026-10-24, after my first tries:**
  - No resale price, category or item aspects: they slowed adding an item without serving the signal.
  - Opening on the camera was annoying, so Hutch opens on Home and adding is one tap away, later one tap from the widget.
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
- **Signal:** 20 items in my first week of use, each added in under 20 s, with a note each time I stop and each time I look something up. Milestone 1 doesn't time adding an item; I time a few by hand.
- **If yes:** keep building [O1](#o1) (barcode, search), then [H3](#h3). **If no:** my notes say whether it was speed (reshape capture) or motivation (O1 shrinks to what's worth lending, selling or insuring).

#### <a id="x4"></a>X4 — Photo to item, with on-device models
**Tried on:** [H1](#h1). **Status:** starts with H1.
- **Learning goals:**
  - Know what Vision recognizes from one photo of a household thing.
  - Use the Foundation Models framework to turn that into a name and category, and maybe a resale guess.
  - Know when Core ML is worth it, if neither is enough.
- **Question going in:** do I accept its suggestion as is for at least 7 items in 10, in under 2 seconds on my phone? Photos never leave the device ([D5](DECISIONS.md#d5--photo-based-ai-capture)).
- **Also counted:** how often I undo the cutout, and why (wrong object, edges cut).
- **Verdict decides:** D5, and whether an on-device estimate is good enough for resale prices ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)).

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
- **Final logo:** a clean vector master of the mark. The app icon and favicon are drawn from it.
- **App Store release:** needs [D6](DECISIONS.md#d6--personal-tool-vs-product) and the name revisited ([D1](DECISIONS.md#d1--name-and-domain-hutch-myhutchapp)).
