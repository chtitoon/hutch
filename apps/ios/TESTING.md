---
# How the iPhone app is tested. Proposed (D22). From M0, `make test` reads these numbers: change one
# here and the check follows. Budgets are targets until M0 measures the real suites; then they're set
# 10 to 25% above what was measured, as PERFORMANCE.md does.
version: 1
simulator:                       # every simulator test and every reference image runs on this one
  device: TBD in M0              # a current 6.1" iPhone that the installed runtime supports
  runtime: TBD in M0             # the newest iOS, exact (e.g. 27.0); upgrading it is its own PR
  minimum_runtime: TBD in M0     # project.yml's deployment target, exact (e.g. 26.4), for `make test RUNTIME=min`
  locale: en_US
  time_zone: UTC
retries: 0                       # no test is ever re-run to get a pass
repeat:                          # on a branch, extra runs of the suites in test files changed from main
  core: 100                      # milliseconds a run: 100 runs of a suite cost under a second
  device: 1                      # device and snapshot suites: one extra run, about 2 s per changed screen
  journeys: 0                    # seconds a run; kept deterministic by their rules instead
budgets:                         # a PR is ready to merge within a minute of the last change
  make_test: 60 s                # `make test` end to end: incremental build, simulator already booted
  build: 20 s                    # incremental build of the app and its test targets
  core_suite: 5 s                # every Core test, `swift test` on the Mac
  core_test: 50 ms               # any one Core test
  device_suite: 20 s             # device and snapshot tests on the simulator
  journeys: 15 s                 # every UI test (XCUITest) together; this, not a count, caps them
snapshots:
  variants: [light, dark, accessibility-xl, smallest-width]   # per screen state; smallest-width is 375 pt
  perceptual_precision: 0.98     # absorbs anti-aliasing only; any real change is far beyond it
---

# Testing the iPhone app

How the app applies the rules in the root [TESTING.md](../../TESTING.md); read that first. The numbers above are the app's; the prose says why each is what it is and how `make test` enforces the rules. Most of it lands with M0 and M2 (the first screens); until then it's the plan.

## What's supported, and what's tested

What the app supports is set in `project.yml` (D9), never here: the deployment target (`IPHONEOS_DEPLOYMENT_TARGET`, iOS 26, D8) and the device family (`TARGETED_DEVICE_FAMILY: 1`, iPhone only, D23). The App Store installs the app on every iPhone that runs that iOS version, so there's no list of models to keep. Tests run against those settings:

- **iOS version.** Every test and every reference image runs on the newest iOS (`runtime`), what most people use. The compiler covers the minimum: with the deployment target at iOS 26, an API newer than that fails the build unless it's behind `#available`. What it can't catch is behavior that changed between versions, so `make test RUNTIME=min` runs Core and device tests (no snapshots, whose images belong to the newest runtime) on `minimum_runtime`. That's a second simulator run, too slow for every PR: it's required before each TestFlight build (T1 onward) and when D8 is revisited each autumn. `make test` fails if either runtime is older than the deployment target.
- **Screen sizes.** The `smallest-width` snapshot variant is 375 pt wide, the narrowest iPhone iOS 26 supports (iPhone SE, 12 mini, 13 mini), where truncation happens first. The other variants use the pinned device. The largest iPhones (440 pt) rarely break a layout that fits both, so they get no variant.
- **iPad.** Not supported (D23): iPads run the iPhone app in an iPhone-sized window, which the iPhone tests already cover.

## The layers

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

**Why some things stay manual.** Face ID, the camera and real iCloud depend on hardware and Apple's servers, which no test controls. The app reaches each through a protocol (`Authenticator`, `Camera`, `SyncService`…), so everything above it is tested with a fake, and the real thing is checked once per milestone on my phone.

## How each rule is enforced

| Source | In Swift | Enforced by |
|--------|----------|-------------|
| **Time** | Code takes a `Clock` and a `now`; tests pass a manual clock and advance it. | SwiftLint bans `Date()`, `Task.sleep` and `Thread.sleep` outside the providers and in all tests |
| **Randomness** | IDs come from an injected generator; CryptoKit's nonces stay random. | SwiftLint bans `UUID()` and `.random` outside the providers |
| **Concurrency** | Swift 6 strict concurrency; tests `await` what they start. Swift Testing runs tests in parallel. | The compiler; parallel runs; repeats |
| **Shared state** | A fresh temporary directory, an in-memory Keychain and its own `UserDefaults` suite per test. Device tests that touch the real Keychain use a service name unique to the test and remove it after. | Parallel runs and repeats expose leaks |
| **Network** | Core and device tests install a `URLProtocol` that fails any request. | That trap fails the test |
| **Animations and async UI** | Snapshots render with animations off. Journeys launch with `-UITests`, which turns animations off and injects fakes, and wait only with `waitForExistence` on accessibility identifiers. | SwiftLint bans `sleep` in UI tests |
| **Environment** | Device, runtime, locale and time zone come from the front matter, and every snapshot and journey sets them. | `make test` creates the simulator from the front matter |
| **Rendering** | One pinned device and runtime record and check every reference image, on the Mac. Upgrading the runtime is its own PR, like Lighthouse in PERFORMANCE.md. | `make setup` checks the runtime is installed; `make test` refuses any other |
| **Retries and skips** | `make test` never passes `-retry-tests-on-failure`; platform differences use `#if os(iOS)`. | SwiftLint fails on `.disabled` and `XCTSkip` |

## Repeats

On a branch, `make test` finds the test files changed from `main` and runs those suites again, in parallel, as many extra times as `repeat` in the front matter says. That's why each test file holds one suite, named after the file. Typically under 3 s, and nothing when no test file changed.

- **Core: 100 runs.** Most tests and most logic live there, and a run costs milliseconds, so this is where repeats find the most for the least.
- **Device and snapshot: 1 extra run.** They render or read a fixed state, so a second run mostly proves nothing leaks between runs. A rare flake here is caught by the policy in the root TESTING.md, not by repeats.
- **Journeys: none.** Each run costs seconds; their rules keep them deterministic.

To reproduce a flake: `make test REPEAT=100` on that suite.

## Snapshot tests

Every screen has snapshot tests (D11), with [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) as the proposed library (confirmed in M2). Reference images sit next to their tests, so a visual change shows up as before-and-after images in the PR's file changes, and an accidental one fails `make test`.

- **What's snapshotted:** each screen in each state that looks different: empty, one item, many items, a long name, an error. The view gets its state directly; no store, no network, no waiting.
- **Variants** (front matter): light and dark at the default text size; light at Accessibility XL, where most layouts break; and the smallest supported iPhone width, where most truncation happens. Four images per state; more would bury the change that matters in the PR.
- **Fixed inputs:** fixed dates, IDs, locale and time zone; fixture photos from the test bundle; animations off.
- **Precision:** perceptual precision 0.98 absorbs anti-aliasing between runs and nothing else. If an image fails at that precision, something changed. The threshold is never lowered to make a test pass.
- **Re-recording** is deliberate: `make test RECORD=1` for the suites named, and the PR says which images changed and why (AGENTS.md).

**Accessibility.** Each journey runs `performAccessibilityAudit()` on every screen it visits: missing labels, text clipped at large sizes, contrast. It's deterministic for a given runtime, so it fails like any other assertion.

## Test-first in Swift

The loop is in the root TESTING.md; in Swift:

- **The stubbed interface** throws `Unimplemented` (or returns a fixed wrong value), so the test commit compiles.
- **Names are display names:** `@Test("A new item is private")`, `@Test("Search finds an item by its location")`.
- **Fixtures are named factories** beside the tests: `Item.fixture(name: "Ladder", location: "Garage")`.
- **Fast cycles:** `swift test --filter <suite>` in `HutchCore`, seconds per cycle; `make test` before each commit.

## How it's enforced

| Where | What | When it lands |
|-------|------|---------------|
| `make test` in `apps/ios` | Builds; runs Core on the Mac, then Core, device and snapshot tests, then journeys, on the pinned simulator; repeats changed suites; fails on any budget above or a retry or skip; prints the simulator, runtime and timings | M0 (Core), M2 (snapshots), the first journey with the first flow |
| `make test RUNTIME=min` | Core and device tests on `minimum_runtime` | Before each TestFlight build, from T1 |
| SwiftLint (`validate-ios.yml`, *Validate Code*) | Bans `Date()`, `UUID()`, `Task.sleep`, `Thread.sleep`, `sleep`, `.disabled` and `XCTSkip` where the table says; Linux, no build | M0 |
| PR description | Each ticked box names its test; **Tests changed** lists any weakened, deleted or re-recorded test | Every PR |
| My phone, through TestFlight | The milestone's on-device checklist | From T1 |

CI on a macOS runner stays optional (AGENTS.md). If added, it runs Core and device tests only: reference images are recorded on the Mac's GPU, and a different machine's renderer would fail them for reasons that aren't regressions.
