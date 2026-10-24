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

Where Hutch is going and what's next. It only looks forward: what already happened is in [LEARNED.md](LEARNED.md). How it works is [D22](DECISIONS.md#d22--an-outcome-roadmap-bets-and-experiments).

## Why Hutch exists

1. **The product I wish I had:** I know what I own, borrow instead of buying what I'd use once, and let go of what I don't use, without exposing what's in my home. Mostly for me; if it lands with people around me, even better.
2. **The way I learn:** new tools and ways of working, tried on a real product instead of a toy.

**Guardrail:** I still want to build it. Two slogs in a row at the weekly review, and the next pick is an experiment or a fun bet.

## Outcomes

What someone does differently because of Hutch. Only [O1](#o1) is a gate: nothing for other people gets built until I use Hutch myself.

| | Outcome | Early signal | Proof |
|---|---|---|---|
| <a id="o1"></a>**O1** | I know what I own and where it is | 20 items in my first week; adding one takes under 20 s | 50 items, still accurate two months later, used at least 3 times to find, prove or decide something |
| <a id="o2"></a>**O2** | Neighbors lend to each other | Neighbors join a shared vault and add things themselves | 3 households lending within a month; an "anyone have a ladder?" request answered |
| <a id="o3"></a>**O3** | I let go of things I don't use | — | 5 items sold from Hutch, each listed faster than with the eBay app |

Signals come from my notes, what neighbors tell me and counts on my phone only I see: never telemetry ([non-negotiable 5](AGENTS.md#non-negotiables)).

## Now

At most two bets and one experiment.

#### <a id="h1"></a>H1 — I'll keep an inventory if Hutch makes it effortless
**Serves:** [O1](#o1). **Status:** ready, needs the Mac. **Appetite:** 3 weeks to build, then 1 week of use on my phone.
- **Test:** the first Hutch app. It opens on the camera; one tap, and an on-device model turns the photo into an item ([X4](#x4)); I confirm it, say where it lives (picked from places I've used) and what I'd resell it for. A list shows each item's photo, name, place and price. When time runs short, everything else is cut first.
- **Never cut:** encrypted at rest from the first write, with the key in the Keychain ([non-negotiable 1](AGENTS.md#non-negotiables), [D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)); new items private; snapshot tests for each screen. Prior work: [#32](https://github.com/chtitoon/hutch/pull/32).
- **Also learning:** SwiftUI, Swift 6 and CryptoKit, on a real app; the models are [X4](#x4).
- **Signal:** 20 items in my first week of use, each added in under 20 s (timed on the phone, never sent), with a note each time I stop and each time I look something up.
- **If yes:** keep building [O1](#o1) (barcode, search), then [H3](#h3). **If no:** my notes say whether it was speed (reshape capture) or motivation (O1 shrinks to what's worth lending, selling or insuring).
- **Open:** a looked-up resale price would tell a price service what I own, which non-negotiable 1 rules out today ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)).

#### <a id="x4"></a>X4 — Photo to item, with on-device models
**Tried on:** [H1](#h1). **Status:** starts with H1.
- **Learning:** what Apple's on-device models can do with one photo: Vision to recognize the object, the Foundation Models framework to turn that into a name and category (and maybe a resale guess), Core ML if neither is enough.
- **Question going in:** do I accept its suggestion as is for at least 7 items in 10, in under 2 seconds on my phone? Photos never leave the device ([D5](DECISIONS.md#d5--photo-based-ai-capture)).
- **Verdict decides:** D5, and whether an on-device estimate is good enough for resale prices ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)).

#### <a id="h2"></a>H2 — Neighbors will join a shared vault and add to it
**Serves:** [O2](#o2). **Status:** ready, needs only me. **Appetite:** 2 weeks.
- **Against it:** Peerby found people won't list their things but help when asked for one ([CONTEXT.md](CONTEXT.md#research-findings-that-shape-the-product)). The riskiest assumption in [O2](#o2), so it goes first.
- **Test:** a shared iCloud album, "Neighborhood shelf", seeded with 10 of my things; invite 6 neighbors to add what they'd lend. After two weeks, ask the group for one thing I need.
- **Signal:** 3 of 6 add at least 2 things each without a second nudge; the request gets an offer.
- **If yes:** [O2](#o2) is a vault members write to; maybe a lending bet before [O1](#o1)'s proof. **If they answer but don't add:** lending starts from requests. **If neither:** O2 moves to Later.

## Next

Riskiest first.

1. <a id="x3"></a>**X3 — OpenSpec.** Tried on [H1](#h1). Does a spec per change make an agent's work better than a checklist, or just add a second plan to keep in sync?
2. <a id="h3"></a>**H3 — My inventory survives a lost phone.** Serves [O1](#o1). Once I rely on it. Sync and recovery, together ([non-negotiable 4](AGENTS.md#non-negotiables), [D21](DECISIONS.md#d21--recovery-icloud-keychain-plus-a-printable-recovery-kit)). Needs [D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)'s sync approach confirmed.

## Later

No order, no detail.

- **Organize:** locations, categories, value, receipts, warranties. If [H1](#h1) shows lookups are what I use it for.
- **Lending:** shaped by [H2](#h2). A vault every member writes to means every member holds its key, removing one re-keys it for all, and CloudKit sharing only reaches Apple users ([D3](DECISIONS.md#d3--platform-native-iphone-app--static-website-in-one-monorepo)).
- **Selling:** eBay connect, listing, price estimates from sold listings ([D23](DECISIONS.md#d23--resale-prices-without-telling-anyone-what-i-own)). After [O1](#o1): an empty inventory has nothing to sell.
- **App icon and final logo:** the icon comes with [H1](#h1)'s first build on my phone.
- **App Store release:** needs [D6](DECISIONS.md#d6--personal-tool-vs-product) and the name revisited ([D1](DECISIONS.md#d1--name-and-domain-hutch-myhutchapp)).
