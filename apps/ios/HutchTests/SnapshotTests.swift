import HutchCore
import SnapshotTesting
import SwiftUI
import Testing
@testable import Hutch

/// Every screen as reference images, in light, dark and a large Dynamic Type size (D11).
/// A change shows up as before-and-after images in the PR; an accidental one fails `make test`.
/// Re-record on purpose with `make snapshots`.
@MainActor
@Suite struct SnapshotTests {
    static let variants: [(name: String, traits: UITraitCollection)] = [
        ("light", UITraitCollection(userInterfaceStyle: .light)),
        ("dark", UITraitCollection(userInterfaceStyle: .dark)),
        ("large-type", UITraitCollection { traits in
            traits.userInterfaceStyle = .light
            traits.preferredContentSizeCategory = .accessibilityLarge
        }),
    ]

    func check(_ view: some View, named name: String, fileID: StaticString = #fileID, filePath: StaticString = #filePath, line: UInt = #line, column: UInt = #column) {
        let screen = view
            .environment(\.locale, Locale(identifier: "en_IE"))
            .tint(Palette.sage)
        for variant in Self.variants {
            assertSnapshot(
                of: UIHostingController(rootView: screen),
                as: .image(on: .iPhone13Pro, precision: 0.99, perceptualPrecision: 0.98, traits: variant.traits),
                named: variant.name,
                fileID: fileID, file: filePath, testName: name, line: line, column: column
            )
        }
    }

    @Test func captureWithoutCamera() {
        let library = Library(store: nil, suggester: Fixtures.NoSuggestions())
        check(CaptureScreen(library: library, cameraAvailable: false), named: "capture")
    }

    /// No rooms yet: no Apple Home rooms, nothing added.
    @Test func confirmWhileSuggesting() {
        check(form(Draft(), suggesting: true, rooms: []), named: "confirm-suggesting")
    }

    @Test func confirmWithSuggestion() {
        let draft = Draft(name: "DeWalt 18V cordless drill", category: "Tools", room: "Garage", spot: "Left shelf")
        let rooms = ["Garage", "Attic", "Kitchen", "Living Room", "Bedroom", "Office", "Basement"]
        check(form(draft, suggesting: false, rooms: rooms), named: "confirm-suggested")
    }

    @Test func emptyList() {
        check(NavigationStack { ItemList(items: [], thumbnails: [:], stats: CaptureStats(items: [])).navigationTitle("Items") }, named: "list-empty")
    }

    @Test func listWithItems() {
        let items = Fixtures.items
        let thumbnails = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, Fixtures.photo(Fixtures.symbols[$0])) })
        check(NavigationStack { ItemList(items: items, thumbnails: thumbnails, stats: CaptureStats(items: items)).navigationTitle("Items") }, named: "list")
    }

    private func form(_ draft: Draft, suggesting: Bool, rooms: [String]) -> some View {
        NavigationStack {
            ItemForm(photo: Fixtures.photo("wrench.and.screwdriver"), draft: .constant(draft), suggesting: suggesting,
                     rooms: rooms, onSave: {})
        }
    }
}

enum Fixtures {
    struct NoSuggestions: ItemSuggesting {
        func suggest(for image: CGImage) async -> Suggestion { .empty }
    }

    static let symbols = ["wrench.and.screwdriver", "hammer", "tent", "bicycle"]

    static let items: [Item] = [
        Item(name: "DeWalt 18V cordless drill", category: "Tools", room: "Garage", spot: "Left shelf",
             createdAt: Date(timeIntervalSince1970: 4), capture: CaptureRecord(seconds: 11, suggestionSeconds: 1.4, suggestionSource: .modelWithImage, keptSuggestedName: true)),
        Item(name: "Aluminium step ladder", category: "Household", room: "Garage", spot: "Back wall",
             createdAt: Date(timeIntervalSince1970: 3), capture: CaptureRecord(seconds: 14, suggestionSeconds: 1.2, suggestionSource: .modelWithImage, keptSuggestedName: true)),
        Item(name: "Quechua 2-person tent", category: "Camping", room: "Attic",
             createdAt: Date(timeIntervalSince1970: 2), capture: CaptureRecord(seconds: 22, suggestionSeconds: 1.9, suggestionSource: .modelWithLabels, keptSuggestedName: false)),
        Item(name: "Kids' bike", createdAt: Date(timeIntervalSince1970: 1)),
    ]

    /// A stand-in photo: a symbol on a flat background, the same on every run.
    static func photo(_ symbol: String) -> UIImage {
        let size = CGSize(width: 600, height: 450)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(Palette.surfaceSunken).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let configuration = UIImage.SymbolConfiguration(pointSize: 200, weight: .regular)
            let image = UIImage(systemName: symbol, withConfiguration: configuration)!.withTintColor(UIColor(Palette.deep), renderingMode: .alwaysOriginal)
            image.draw(at: CGPoint(x: (size.width - image.size.width) / 2, y: (size.height - image.size.height) / 2))
        }
    }
}
