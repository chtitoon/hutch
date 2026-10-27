# Working on the iPhone app

Read the root [AGENTS.md](../../AGENTS.md) first. This page covers how Swift in `apps/ios` is written. The bar: an iOS developer opening any file should find code that looks like Apple's own samples.

## The two guides

- **Naming and APIs:** Swift's [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- **Layout and style:** [Google's Swift Style Guide](https://google.github.io/swift/).
  - It's what `swift-format`, which ships with Xcode, does by default: 2-space indents, 100-character lines.
  - The settings are in `.swift-format`.
  - `make format` fixes the layout. `make lint`, part of `make test`, fails on anything left.
  - **Not covered by the formatter:** a `case` or `default` body goes on the lines after its label, never on the same line. `make lint` checks this too.

## Naming

- **Read as a phrase at the call site:** `library.photo(of: item)`, `Item.roomSuggestions(from: items, homeRooms: names)`.
- **Factory methods start with `make`:** `Vault.makeKey()`.
- **Name by what it returns, or by what it does:**
  - A function without side effects is a noun: `uprightImage(maxPixels:)`.
  - One that changes something is a verb: `save`, `delete`.
- **Booleans read as assertions:** `isSaving`, `isCameraAvailable`, `canSave`.
- **No abbreviations** beyond Swift's own (`id`, `URL`, `JPEG`).

## Comments

Few and short.

- **Comment only what the code can't say:** why something is done, a constraint, or a decision (with its D-number).
- **Never restate a name:** no `/// The item's name.`
- **One line where possible.** A `///` doc comment goes on a type or a public API only when its role isn't obvious from the name.
- **A doc comment is one short paragraph, with no empty `///` line.** A longer explanation is a `//` note inside the type, next to the code it explains. `make lint` checks this.
- **Use `//`** for a note inside code.

## Swift

- **Let the compiler write it:** synthesized `Codable`, `Equatable`, `Hashable` and initializers.
  - No hand-written `init(from:)` or `encode(to:)` unless a test shows a real stored format needs it.
- **No compatibility code for builds that never shipped.**
  - Until the first TestFlight build, old local data is disposable.
  - After that, a format change goes through a versioned migration in the store, never lenient decoding in the model.
- **No defensive code for states that can't happen.**
  - No `try?` that swallows an error the user should hear about. Show it (`library.error`) or throw.
- **Everything else:**
  - `let` over `var`.
  - `private` by default.
  - `guard` for early exits.
  - No force-unwraps outside tests and previews.
- **Swift 6 with strict concurrency.** Never silence a warning; warnings are errors.

## SwiftUI

- **One main type per file,** named after it.
  - Small helpers private to that view may share the file.
  - Folders: `App/`, `Screens/`, `Components/`, `Brand/`, `Services/`, `PreviewContent/`.
- **Shared state:**
  - `@Observable` models go through the environment: `.environment(library)` and `@Environment(Library.self)`. Never pass them from view to view by hand.
  - `@State` holds a view's own state.
- **Every view file ends with a `#Preview`.** Previews and snapshot tests share `PreviewContent/SampleData.swift` (`Library.sample`, `Item.samples`).
- **Reusable looks are styles** (`ButtonStyle`, a `View` extension), not long chains of modifiers repeated across views.
- **Plurals use Apple's automatic grammar:** `Text("^[\(count) thing](inflect: true)")`, never `count == 1 ? … : …`.
- **Tokens only:** colors, type, spacing and corners come from `Palette`, `Typography`, `Spacing` and `Radius` ([DESIGN.md](DESIGN.md)). `make lint` fails on raw values.

## Before opening a PR

- `make format`, then a green `make test`. Say which simulator it ran on.
- Re-read the diff as a reviewer who knows iOS. Anything that wouldn't pass review at Apple gets fixed first.
