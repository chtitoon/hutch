import HutchCore
import SnapshotTesting
import SwiftUI
import Testing

@testable import Hutch

/// Every screen in light, dark and large type (D11). Re-record on purpose with `make snapshots`.
@MainActor
@Suite struct SnapshotTests {
  static let variants: [(name: String, traits: UITraitCollection)] = [
    ("light", UITraitCollection(userInterfaceStyle: .light)),
    ("dark", UITraitCollection(userInterfaceStyle: .dark)),
    (
      "large-type",
      UITraitCollection { traits in
        traits.userInterfaceStyle = .light
        traits.preferredContentSizeCategory = .accessibilityLarge
      }
    ),
  ]

  @Test func homeEmpty() {
    check(HomeScreen(), library: Library(store: nil), named: "home-empty")
  }

  @Test func homeWithItems() {
    check(HomeScreen(), library: .sample, named: "home")
  }

  @Test func room() {
    check(NavigationStack { RoomScreen(room: "Garage") }, library: .sample, named: "room")
  }

  @Test func item() {
    check(NavigationStack { ItemScreen(item: Item.samples[0]) }, library: .sample, named: "item")
  }

  // The simulator has no camera, so the viewfinder is drawn over the screen's forest.
  @Test func viewfinder() {
    check(
      Viewfinder().frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.deep),
      library: .sample,
      named: "viewfinder"
    )
  }

  @Test func captureWithoutCamera() {
    check(CaptureScreen(isCameraAvailable: false), library: .sample, named: "capture")
  }

  // No Apple Home rooms and nothing added yet, so the room is typed.
  @Test func addWithoutRooms() {
    check(
      AddItemScreen(photo: .sample("wrench.and.screwdriver")),
      library: Library(store: nil),
      named: "add-empty"
    )
  }

  @Test func addWithRooms() {
    let draft = Draft(name: "DeWalt 18V cordless drill", room: "Garage")
    check(
      AddItemScreen(photo: .sample("wrench.and.screwdriver"), draft: draft),
      library: .sample,
      named: "add"
    )
  }

  private func check(
    _ view: some View,
    library: Library,
    named name: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    BrandFonts.register()
    let screen =
      view
      .environment(library)
      .environment(\.locale, Locale(identifier: "en_IE"))
      .brand()
    for variant in Self.variants {
      assertSnapshot(
        of: UIHostingController(rootView: screen),
        as: .image(
          on: .iPhone13Pro,
          precision: 0.99,
          perceptualPrecision: 0.98,
          traits: variant.traits
        ),
        named: variant.name,
        fileID: fileID,
        file: filePath,
        testName: name,
        line: line,
        column: column
      )
    }
  }
}
