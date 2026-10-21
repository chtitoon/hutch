# Testing

Hutch is built test-first, mostly by agents, and reviewed from a phone. Tests are how a change proves itself: if they pass, the change works and nothing else broke; if they fail, something real is wrong. That only holds if tests never lie, so this file is about two things: catching regressions in behavior and UI, and keeping every test fast and deterministic enough to trust on the first run.

This file holds the rules for every app. Each app's own file says how it applies them, with its numbers:

| App | How it's tested |
|-----|-----------------|
| iPhone | [apps/ios/TESTING.md](apps/ios/TESTING.md): the layers, the pinned simulator, budgets and repeats, snapshots, and how each rule below is enforced in Swift |
| Website | `npm test` in `apps/web`: build checks on the built files (HTML, links, tokens, fonts, budgets), with no browser, so already deterministic. Speed is checked as described in [apps/web/PERFORMANCE.md](apps/web/PERFORMANCE.md). The site has no JavaScript; a page that ever needs a script needs a test that runs it. |

**A flaky test is a bug, not a property of a test.** A test is flaky if its result can change while the code and its inputs don't. Every flake has a cause: a clock, a random number, a race, shared state, the network, an animation, the environment, the renderer. The rules below take each cause out of the tests by construction, and each app's test command enforces what it can. "Test X is flaky" is never an answer; it's a bug report with a known list of suspects.

## Layers

Most tests sit at the bottom, where they're fastest and can't flake. Each layer up costs more time and has more ways to go wrong, so it only tests what the layer below can't. What no test can control deterministically (hardware, a vendor's servers) is reached through an interface, so everything above it is tested with a fake, and the real thing is checked by hand from a checklist in the milestone's PR. A test that depends on someone else's servers would be flaky by design.

## Where flakiness comes from, and the rule that removes it

| Source | Rule |
|--------|------|
| **Time** (the current date, timers, sleeps, timeouts) | Code takes a clock; tests pass one they control and advance it. No test waits for real time. |
| **Randomness** (IDs, random numbers) | IDs and random values come from injected generators that tests seed. Encryption stays truly random; its tests assert properties (round trip, tamper fails, ciphertext differs each time), not exact bytes. |
| **Concurrency** (races, order of async work) | Tests wait for the work they start to finish, never poll or sleep for it. Tests run in parallel, so one that depends on another's timing fails early, not someday. |
| **Shared state** (settings, files, keychains, singletons) | Each test builds its own world: a fresh temporary directory, its own settings, an in-memory keychain. No singletons in core logic. |
| **Network** | No test touches the network: a trap fails any request. |
| **Animations and async UI** | Screens are tested in a fixed state, animations off. UI tests wait for something to appear, never for time to pass. |
| **Environment** (locale, time zone, text size, device) | Pinned in the app's TESTING.md and set explicitly by every test that depends on it. A test never reads the machine's settings. |
| **Rendering** (OS version, GPU, fonts) | One pinned setup records and checks every reference image. Upgrading it is its own PR that re-records them all. |
| **Test order** | No test depends on another having run. |

**No retries, no skips.** No test is ever re-run to get a pass, and none is skipped or disabled. A test that only runs sometimes, or only passes the second time, hides exactly the bugs this file is about. Platform differences are handled at compile time, not by skipping.

**Repeats are a safety net, sized by cost.** Before merge, each app reruns the suites whose test files changed, to catch what slipped past the rules above. The rules are the defense, so the number of reruns comes from what a run costs, not from a round number. What a number of runs catches, for a test that fails a share of the time:

| A test that fails… | 2 runs | 100 runs |
|---|---|---|
| 1 run in 5 | 36% | ~100% |
| 1 in 20 | 10% | 99% |
| 1 in 100 | 2% | 63% |

**A minute per PR.** Each app's full test command stays under 60 s on a machine that has built it before, so a PR is ready to merge within about a minute of the last change. A test layer grows by fitting that time, not by raising it.

## Privacy tests

The non-negotiables (AGENTS.md) are tested like features, so a regression fails the tests rather than a review.

- **The canary.** Every fixture item carries a unique string in each field, and each fixture photo a known pattern. Tests capture every byte the app writes to disk and every payload handed to the sync fake, and assert the canary appears nowhere: not as UTF-8, UTF-16, Base64 or hex. This is how M1 proves "nothing written to disk contains plaintext" and M4 proves "the server payload is not readable" (non-negotiable 1).
- **Private by default.** A test creates items through every path that creates them and asserts each is `private` (non-negotiable 2).
- **Golden files.** Every format that's ever stored or exported (an encrypted item, the store, the recovery kit) gets a committed sample, encrypted with a fixed test key, made by the first version that writes it. Tests decrypt and read every sample, forever. A change that would orphan data people already have fails here, before it ships (non-negotiable 4). Samples are added, never edited.
- **Tamper and wrong key.** Decryption fails cleanly, with an error the app handles, for a flipped byte, a truncated blob and the wrong key.

## The test-first loop

How an agent works a milestone (the work loop in AGENTS.md, steps 3 to 6):

1. **Name the proof.** For each Definition of Done box being worked, write down the test or tests that will prove it, in the session's plan. A box no test can prove goes on the milestone's by-hand checklist instead.
2. **Red first, reviewable alone.** Commit the tests on their own, before any implementation, so I can review what's being built without reading how:
   - **The interface comes with them:** the types and function signatures the tests call, with bodies that fail (or return a fixed wrong value). The commit builds, and every new test fails on its assertion, not on a missing name.
   - **Names are the spec.** Each test's name reads as a sentence about behavior: "A new item is private", "Search finds an item by its location". The list of names alone should read as the milestone's Definition of Done in detail.
   - **Inputs are visible.** Fixtures are built in the test or in a named factory beside it, never hidden in a shared setup, so each test reads top to bottom: given, when, then.
   - **The PR description lists the new test names under each box**, with the failure each produced on the test commit. That's the review: if the names and assertions describe the right behavior, the implementation is checked by the tests; I read it only if I want to.
3. **Green.** Write the least code that passes. Run the narrowest tests that cover the change for fast cycles (the app's TESTING.md says how), and the full command before each commit.
4. **Refactor** with the tests green.
5. **Prove it.** The app's full test command is green, repeats included. The PR ticks each box with the name of the test that proves it.

**Rules that keep tests honest.** Tests are the only thing standing between an agent's confidence and my phone, so:

- **Never weaken a test to pass it.** Deleting a test, loosening an assertion, re-recording a reference image or raising a budget is allowed only when the behavior is meant to change, and the PR lists it under **Tests changed**, with why.
- **Fakes only at the edges.** Fake what the app doesn't own: the clock, randomness, the keychain, the file system root, the network, the sync service, the camera, biometrics. Never mock Hutch's own types; test them for real. A test of a mock proves the mock.
- **Test behavior, not structure.** Assert what a user or caller sees (the item is found, the screen shows the error), not which private method ran, so refactors don't break tests that should still pass.
- **Each fake is tested too.** Each fake comes with a few tests of the behavior the app relies on from the real thing (the sync service's conflict errors, the keychain's duplicate item). When the real thing turns out to behave differently, the fake and its tests change first.

## When a test fails

- **It fails every time:** the code or the test is wrong. Fix the one that's wrong; never the test just because it's easier.
- **It failed once and passed after:** that's a flake. Stop and reproduce it by running that suite many times (the app's TESTING.md says how). Find its source in the table above, fix the source (usually a clock, ID or directory that wasn't injected), and add the lint rule or trap that would have caught it, if one is missing. If it can't be fixed in this PR, delete the test, prove the behavior at a lower layer, and say so in the PR. There's no list of known flaky tests to add it to.
