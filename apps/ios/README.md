# Hutch for iPhone

SwiftUI app, iOS 26 and later, bundle ID `app.myhutch.ios`. Built and tested locally on the Mac with Xcode and the iPhone simulator; see [AGENTS.md](../../AGENTS.md).

## Commands

Run from `apps/ios` (or `make ios-<task>` from the top of the repo):

| Command | What it does |
|---------|--------------|
| `make setup` | Check Xcode and XcodeGen, generate `Hutch.xcodeproj` from `project.yml` |
| `make test` | Check generated files are current, then build and run all tests on an iPhone simulator, naming it |
| `make run` | Build, boot the simulator, install and launch the app |
| `make tokens` | Regenerate colors, sizes, logo images and the app icon from `design/` |

The simulator is a booted iPhone, else the first available one; pick one with `make test SIMULATOR="iPhone 17"`.

## Where things live

- `project.yml`: the XcodeGen spec. The `.xcodeproj` is generated and never committed (D9); run `make setup` after changing it.
- `Hutch/`: the app target (SwiftUI views only).
- `HutchCore/`: a local Swift package for the logic (models, crypto, sync), tested with Swift Testing. Keep logic here so tests cover it.
- `tokens.swift`: the generator behind `make tokens`. It writes `Hutch/Tokens.swift` (`Palette`, `Radius`, `Space`, `FontFamily`) and `Hutch/Assets.xcassets` (the logo's mark and wordmark as template images, the app icon). These are generated: never edit them by hand, and `make test` fails if they're stale.
- `design/`: the M1 screen spec, once #22 lands.
