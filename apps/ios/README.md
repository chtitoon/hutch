# Hutch for iPhone

SwiftUI app, iOS 26 and up. The Xcode project is generated from `project.yml` with XcodeGen and never committed (D9). Built and tested locally on the Mac with Xcode and the iPhone simulator; see [AGENTS.md](../../AGENTS.md).

Design: the root [DESIGN.md](../../DESIGN.md) for values and rules, and [DESIGN.md](DESIGN.md) here for how SwiftUI applies them.

## Layout

- `Hutch/`: the app's screens, laid out after the Hutch iPhone app canvas in the brand's fonts and colors.
  - Opens on Home (`HomeScreen`): search, rooms with their counts, what was added lately, and a + at the bottom. A room lists its things by spot; an item shows its photo and place.
  - + opens the camera (`CaptureScreen`). After the shutter, type its name and pick a room (`AddScreen`); Save goes back to Home. Rooms come from Apple Home (`HomeRooms`, D25).
  - `BrandFonts`: the bundled fonts and section eyebrows.
  - `Assets.xcassets`: the app icon and the logo's house-and-keyhole mark, traced from the website's.
- `Hutch/Generated/Tokens.swift`: written by `make tokens` from DESIGN.md. Never edit it by hand.
- `core/`: the `HutchCore` Swift package, with its tests. It holds:
  - the item: a name, a room and an optional spot
  - encryption (`Vault`, `KeychainKeyStore`)
  - the encrypted store (`ItemStore`)
- `HutchTests/`: snapshot tests of every screen, with their reference images in `__Snapshots__/`.

## Tasks

Run them in this folder.

- `make setup`: checks Xcode and XcodeGen, then generates the project.
- `make test`: checks the tokens and lint, then runs every test on the iPhone 17 Pro simulator. Pick another with `SIMULATOR="iPhone 17"`, but reference images are recorded on the 17 Pro.
- `make run`: builds the app and launches it in the simulator.
- `make tokens`: regenerates `Tokens.swift` from DESIGN.md, and the app icon from the logo's mark (`icon.swift`).
- `make snapshots`: re-records every reference image. Only do this on purpose, and say why in the PR.

## On my phone

Open `Hutch.xcodeproj` in Xcode, pick the phone, and set a personal team under Signing & Capabilities. Never commit that change: the project is regenerated from `project.yml` anyway.
