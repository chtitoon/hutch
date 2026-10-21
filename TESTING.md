---
# How Hutch is tested. Proposed (D22). From M0, `make test` in apps/ios reads these numbers:
# change one here and the check follows. Budgets are targets until M0 measures the real suites;
# then they're set 10 to 25% above what was measured, as PERFORMANCE.md does.
version: 1
ios:
  simulator:                     # every simulator test and every reference image runs on this one
    device: TBD in M0            # a current 6.1" iPhone that the installed runtime supports
    runtime: TBD in M0           # an exact iOS version (e.g. 27.0); upgrading it is its own PR
    locale: en_US
    time_zone: UTC
  retries: 0                     # no test is ever re-run to get a pass
  repeat:                        # on a branch, extra runs of the suites in test files changed from main
    core: 100                    # milliseconds a run: 100 runs of a suite cost under a second
    device: 1                    # device and snapshot suites: one extra run, about 2 s per changed screen
    journeys: 0                  # seconds a run; kept deterministic by their rules instead
  budgets:                       # a PR is ready to merge within a minute of the last change
    make_test: 60 s              # `make test` end to end: incremental build, simulator already booted
    build: 20 s                  # incremental build of the app and its test targets
    core_suite: 5 s              # every Core test, `swift test` on the Mac
    core_test: 50 ms             # any one Core test
    device_suite: 20 s           # device and snapshot tests on the simulator
    journeys: 15 s               # every UI test (XCUITest) together; this, not a count, caps them
  snapshots:
    variants: [light, dark, accessibility-xl, smallest-width]   # per screen state; see "Snapshot tests"
    perceptual_precision: 0.98   # absorbs anti-aliasing only; any real change is far beyond it
---

# Testing

Hutch is built test-first, mostly by agents, and reviewed from a phone. Tests are how a change proves itself: if they pass, the change works and nothing else broke; if they fail, something real is wrong. That only holds if tests never lie, so this file is about two things: catching regressions in behavior and UI, and keeping every test fast and deterministic enough to trust on the first run.

**A flaky test is a bug, not a property of a test.** A test is flaky if its result can change while the code and its inputs don't. Every flake has a cause: a clock, a random number, a race, shared state, the network, an animation, the environment, the renderer. The rules below take each cause out of the tests by construction, and `make test` enforces what it can. "Test X is flaky" is never an answer; it's a bug report with a known list of suspects.

## The layers

Most tests sit at the bottom, where they're fastest and can't flake. Each layer up costs more time and has more ways to go wrong, so it only tests what the layer below can't.

| Layer | What it proves | Where it runs | Speed | Share |
|-------|----------------|---------------|-------|-------|
| **Core** | Models, encryption, the store's logic, sync logic, view models: everything that decides what the app does | `HutchCore`, a Swift package, with `swift test` on the Mac (no simulator) | milliseconds each | most tests |
| **Device** | What only real iOS does: Keychain, file protection, the on-disk store, Vision barcode reading | The same package's tests on the pinned simulator, plus a few in the app's test target | tens of ms each | a few per boundary |
| **Snapshot** | How each screen looks, in every state that matters | In-process on the pinned simulator: views rendered to images, no app launch | ~100 ms per image | every screen state |
| **Journey** | That screens connect: launch, unlock, add an item, find it again | XCUITest, the full app on the simulator | seconds each | what fits in 15 s, about 3 |
| **On device** | Face ID, the camera, iCloud Keychain restore, CloudKit sync between real devices | My iPhone, through TestFlight, from a checklist in the milestone's PR | minutes | what can't be automated deterministically |

**Why Core runs on the Mac.** `swift test` on the host skips building the app, installing it and booting a simulator, so a test cycle takes a couple of seconds instead of tens. That's what makes test-first practical for an agent, which runs dozens of cycles a session. `make test` runs Core on the simulator too, so nothing passes on macOS alone. The price is a split:

- **`HutchCore`** imports Foundation and CryptoKit only (plus SwiftData, which runs on macOS too): items, encryption, the store, search, sync logic, and the view models (`@Observable` classes holding each screen's state and actions). Photos are `Data` or `CGImage`, never `UIImage`; colors and fonts aren't its business.
- **The app** (or a `HutchUI` package) holds the SwiftUI views, which only render a view model's state and call its actions, and the real Keychain, camera, Face ID and CloudKit behind Core's protocols.

So nearly every behavior, including what a screen does when you tap, is a Core test; a view is tested by its snapshots. Logic that slips into a view can only be tested slowly, which is the pressure that keeps it out.

**Why journeys are capped by time.** UI tests drive the app the way a person would, across processes, through animations and the accessibility tree. That's where most iOS flakiness lives, and each one costs several seconds of launch alone. Their share of the minute is 15 s, about three journeys: unlock and see my items; add an item and find it by search; edit and delete one. Each is a path whose breakage makes the app useless, and that no lower layer sees whole. Everything else is proved lower down. A new journey has to fit the 15 s, or replace one.

**Why some things stay manual.** Face ID, the camera and real iCloud depend on hardware and Apple's servers, which no test controls. The app reaches each through a protocol (`Authenticator`, `Camera`, `SyncService`…) so everything above it is tested with a fake, and the real thing is checked once per milestone on my phone. A test that depends on Apple's servers would be flaky by design.

## Where flakiness comes from, and the rule that removes it

| Source | Rule | Enforced by |
|--------|------|-------------|
| **Time** (`Date()`, timers, `Task.sleep`, timeouts) | Code takes a clock (Swift's `Clock`) and a `now`; tests pass a manual clock and advance it. No test waits for real time. | SwiftLint bans `Date()`, `Task.sleep` and `Thread.sleep` outside the providers and in all tests |
| **Randomness** (`UUID()`, random numbers, CryptoKit's nonces) | IDs and random values come from injected generators; tests seed them. Encryption stays truly random, and its tests assert properties (round trip, tamper fails, ciphertext differs each time) rather than exact bytes. | SwiftLint bans `UUID()` and `.random` outside the providers |
| **Concurrency** (races, order of async work) | Swift 6 strict concurrency. Tests `await` the work they start, never poll or sleep for it. Swift Testing runs tests in parallel, so a test that depends on another one's timing fails early, not someday. | The compiler; parallel runs; `repeat` |
| **Shared state** (UserDefaults, files, Keychain, singletons) | Each test builds its own world: a fresh temporary directory, an in-memory Keychain, its own `UserDefaults` suite. No singletons in Core. Device tests that touch the real Keychain use a service name unique to the test and remove it after. | Parallel runs and `repeat` expose leaks |
| **Network** | No test touches the network. Core and device tests install a URL protocol that fails any request. | That trap fails the test |
| **Animations and async UI** | Snapshots render a view in a fixed state, with animations off. Journeys launch with `-UITests`, which turns animations off and injects fakes; they wait only on accessibility identifiers appearing, with `waitForExistence`, never on time. | SwiftLint bans `sleep` in UI tests |
| **Environment** (locale, time zone, calendar, Dynamic Type, device) | Pinned in the front matter and set explicitly on every snapshot and journey. A test never reads the Mac's settings. | `make test` creates the simulator from the front matter |
| **Rendering** (iOS version, GPU, fonts) | One pinned device and runtime records and checks every reference image, on the Mac. Upgrading the runtime is its own PR that re-records every image, like Lighthouse in PERFORMANCE.md. | `make setup` checks the runtime is installed; `make test` refuses any other |
| **Test order** | No test depends on another having run. | Parallel runs; `repeat` |

**No retries, no skips.** `make test` never passes `-retry-tests-on-failure`, and SwiftLint fails on `.disabled` and `XCTSkip`. A test that only runs sometimes, or only passes the second time, hides exactly the bugs this file is about. Platform differences are handled at compile time (`#if os(iOS)`), not by skipping.

**Repeat before merge.** On a branch, `make test` finds the test files changed from `main` and runs those suites again, in parallel: `repeat` in the front matter says how many extra runs per layer. This is why each test file holds one suite, named after the file. Repeats are a safety net for what slips past the rules above, not the defense, and they're sized by what a run costs, inside the minute: typically under 3 s, and nothing when no test file changed.

What a number of runs catches, for a test that fails a share of the time:

| A test that fails… | 2 runs | 100 runs |
|---|---|---|
| 1 run in 5 | 36% | ~100% |
| 1 in 20 | 10% | 99% |
| 1 in 100 | 2% | 63% |

- **Core: 100 runs.** Most tests and most logic live there, and a run costs milliseconds, so this is where repeats find the most for the least.
- **Device and snapshot: 1 extra run.** They render or read a fixed state, so a second run mostly proves nothing leaks between runs. A rare flake here is caught by the policy below, not by repeats.
- **Journeys: none.** Each run costs seconds; their rules (no sleeps, waits only on accessibility identifiers, fakes injected at launch) keep them deterministic.

## Snapshot tests

Every screen has snapshot tests (D11), with [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) as the proposed library (confirmed in M2). Reference images sit next to their tests, so a visual change shows up as before-and-after images in the PR's file changes, and an accidental one fails `make test`.

- **What's snapshotted:** each screen in each state that looks different: empty, one item, many items, a long name, an error. The view gets its state directly; no store, no network, no waiting.
- **Variants** (front matter): light and dark at the default text size; light at Accessibility XL, where most layouts break; and the smallest supported iPhone width, where most truncation happens. Four images per state; more would bury the change that matters in the PR.
- **Fixed inputs:** fixed dates, IDs, locale and time zone; fixture photos from the test bundle; animations off.
- **Precision:** perceptual precision 0.98 absorbs anti-aliasing between runs and nothing else. If an image fails at that precision, something changed. The threshold is never lowered to make a test pass.
- **Re-recording** is deliberate: `make test RECORD=1` for the suites named, and the PR says which images changed and why (AGENTS.md). An agent never re-records to turn a failure green without saying so.

**Accessibility.** Each journey runs `performAccessibilityAudit()` on every screen it visits: missing labels, text clipped at large sizes, contrast. It's deterministic for a given runtime, so it fails like any other assertion.

## Privacy tests

The non-negotiables are tested like features, so a regression fails `make test` rather than a review.

- **The canary.** Every fixture item carries a unique string in each field, and each fixture photo a known pattern. Tests capture every byte the app writes to disk and every payload handed to the sync fake, and assert the canary appears nowhere: not as UTF-8, UTF-16, Base64 or hex. This is how M1 proves "nothing written to disk contains plaintext" and M4 proves "the server payload is not readable" (non-negotiable 1).
- **Private by default.** A test creates items through every path that creates them and asserts each is `private` (non-negotiable 2).
- **Golden files.** Every format that's ever stored or exported (an encrypted item, the store, the recovery kit) gets a committed sample, encrypted with a fixed test key, made by the first version that writes it. Tests decrypt and read every sample, forever. A change that would orphan data people already have fails here, before it ships (non-negotiable 4). Samples are added, never edited.
- **Tamper and wrong key.** Decryption fails cleanly, with an error the app handles, for a flipped byte, a truncated blob and the wrong key.

## The test-first loop

How an agent works a milestone (the work loop in AGENTS.md, steps 3 to 6):

1. **Name the proof.** For each Definition of Done box being worked, write down the test or tests that will prove it, in the session's plan. A box no test can prove goes on the milestone's on-device checklist instead.
2. **Red first, reviewable alone.** Commit the tests on their own, before any implementation, so I can review what's being built without reading how:
   - **The interface comes with them:** the types and function signatures the tests call, with bodies that throw `Unimplemented` (or a fixed wrong value). The commit compiles, and every new test fails on its assertion, not on a missing name.
   - **Names are the spec.** Each test has a display name that reads as a sentence about behavior: `@Test("A new item is private")`, `@Test("Search finds an item by its location")`. The list of names alone should read as the milestone's Definition of Done in detail.
   - **Inputs are visible.** Fixtures are built in the test or in a named factory beside it (`Item.fixture(name: "Ladder", location: "Garage")`), never hidden in a shared setup, so each test reads top to bottom: given, when, then.
   - **The PR description lists the new test names under each box**, with the failure each produced on the test commit. That's the review: if the names and assertions describe the right behavior, the implementation is checked by the tests; I read it only if I want to.
3. **Green.** Write the least code that passes it. Run Core with `swift test --filter` for seconds-long cycles; run `make test` before each commit.
4. **Refactor** with the tests green.
5. **Prove it.** Green `make test` (which repeats changed suites). The PR ticks each box with the name of the test that proves it.

**Rules that keep tests honest.** Tests are the only thing standing between an agent's confidence and my phone, so:

- **Never weaken a test to pass it.** Deleting a test, loosening an assertion, re-recording a snapshot or raising a budget is allowed only when the behavior is meant to change, and the PR lists it under **Tests changed**, with why.
- **Fakes only at the edges.** Fake what the app doesn't own: the clock, randomness, the Keychain, the file system root, the network, CloudKit, the camera, Face ID. Never mock Hutch's own types; test them for real. A test of a mock proves the mock.
- **Test behavior, not structure.** Assert what a user or caller sees (the item is found, the screen shows the error), not which private method ran, so refactors don't break tests that should still pass.
- **Each fake is tested too.** Each fake comes with a few tests of the behavior the app relies on from the real thing (CloudKit's conflict errors, Keychain's duplicate item). When the real thing turns out to behave differently, the fake and its tests change first.

## When a test fails

- **It fails every time:** the code or the test is wrong. Fix the one that's wrong; never the test just because it's easier.
- **It failed once and passed after:** that's a flake. Stop and reproduce it with `make test REPEAT=100` on that suite. Find its source in the table above, fix the source (usually a clock, ID or directory that wasn't injected), and add the lint rule or trap that would have caught it, if one is missing. If it can't be fixed in this PR, delete the test, prove the behavior at a lower layer, and say so in the PR. There's no list of known flaky tests to add it to.

## How it's enforced

| Where | What | When it lands |
|-------|------|---------------|
| `make test` in `apps/ios` | Builds; runs Core on the Mac, then Core, device and snapshot tests, then journeys, on the pinned simulator; repeats changed suites; fails on any budget above or a retry or skip; prints the simulator, runtime and timings | M0 (Core), M2 (snapshots), the first journey with the first flow |
| SwiftLint (`validate-ios.yml`, *Validate Code*) | Bans `Date()`, `UUID()`, `Task.sleep`, `Thread.sleep`, `sleep`, `.disabled` and `XCTSkip` where the table says; Linux, no build | M0 |
| PR description | Each ticked box names its test; **Tests changed** lists any weakened, deleted or re-recorded test | Every PR |
| My phone, through TestFlight | The milestone's on-device checklist | From T1 |

CI on a macOS runner stays optional (AGENTS.md). If added, it runs Core and device tests only: reference images are recorded on the Mac's GPU, and a different machine's renderer would fail them for reasons that aren't regressions.

## The website

The website's tests are build checks, already deterministic: `npm test` validates the HTML, links, tokens, fonts and performance budgets from the built files, with no browser. Lighthouse timing is noisy by nature; PERFORMANCE.md explains how the PR check compares medians against `main` so noise doesn't fail a PR. The site has no JavaScript; if a page ever needs a script, it needs a test that runs it.
