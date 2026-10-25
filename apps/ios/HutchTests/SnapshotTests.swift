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
        BrandFonts.register()
        let screen = view
            .environment(\.locale, Locale(identifier: "en_IE"))
            .environment(\.animatesScan, false)
            .brand()
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
        let note = ConfirmScreen.note(for: Suggestion(name: draft.name, source: .modelWithImage))
        check(form(draft, suggesting: false, note: note, rooms: rooms), named: "confirm-suggested")
    }

    /// A broad-but-specific name, and its aspects: brand and color read off the photo, the
    /// rest one tap away.
    @Test func confirmWithAspects() {
        let aspects = [
            SuggestedAspect(name: "Brand", value: "Apple", choices: ["Apple"]),
            SuggestedAspect(name: "Color", value: "Silver", choices: ["Silver", "Space Gray", "Starlight", "Midnight"]),
            SuggestedAspect(name: "Chip and year", choices: ["M1, 2020", "M2, 2022", "M3, 2024", "M4, 2025"]),
            SuggestedAspect(name: "Memory", choices: ["8 GB", "16 GB", "24 GB"]),
            SuggestedAspect(name: "Storage", choices: ["256 GB", "512 GB", "1 TB", "2 TB"]),
        ]
        let draft = Draft(name: "Apple MacBook Air", room: "Office", values: ["Brand": "Apple", "Color": "Silver", "Storage": "256 GB"])
        let note = ConfirmScreen.note(for: Suggestion(name: draft.name, source: .modelWithImage))
        check(form(draft, suggesting: false, note: note, aspects: aspects, rooms: ["Office", "Garage"]), named: "confirm-aspects")
        #expect(draft.aspects(for: aspects) == [
            Aspect(name: "Brand", value: "Apple"), Aspect(name: "Color", value: "Silver"), Aspect(name: "Storage", value: "256 GB"),
        ])
    }

    /// The catalog was sure: its name, how sure, and the runners-up one tap away.
    @Test func confirmFromTheCatalog() {
        let suggestion = Suggestion(name: "Dell Inspiron Zino HD", alternatives: ["Dell Inspiron desktop", "mini PC"], catalogScore: 0.94, source: .catalog)
        let draft = Draft(name: suggestion.name, room: "Office", values: ["Brand": "Dell", "Color": "Black"])
        let aspects = [
            SuggestedAspect(name: "Brand", value: "Dell", choices: ["Dell"]),
            SuggestedAspect(name: "Color", value: "Black", choices: ["Black", "White", "Red"]),
            SuggestedAspect(name: "Memory", choices: ["2 GB", "4 GB", "8 GB"]),
        ]
        let view = NavigationStack {
            ItemForm(photo: Fixtures.photo("desktopcomputer"), draft: .constant(draft), suggesting: false,
                     suggestionNote: ConfirmScreen.note(for: suggestion), alternatives: suggestion.alternatives,
                     aspects: aspects, rooms: ["Office", "Garage"], onSave: {})
        }
        check(view, named: "confirm-catalog")
        #expect(ConfirmScreen.note(for: suggestion) == "Matched on this iPhone against Hutch's catalog, 94% sure.")
    }

    /// Apple Intelligence off: Vision's label, and why.
    @Test func confirmWithFallback() {
        let suggestion = VisionFindings(labels: ["bookshelf"], text: []).fallbackSuggestion(because: "Apple Intelligence is off. Turn it on in Settings.")
        let draft = Draft(name: suggestion.name)
        check(form(draft, suggesting: false, note: ConfirmScreen.note(for: suggestion), rooms: ["Garage"]), named: "confirm-fallback")
    }

    @Test func notesSayWhichPathNamedIt() {
        #expect(ConfirmScreen.note(for: Suggestion(name: "x", source: .modelWithImage))?.contains("from the photo") == true)
        #expect(ConfirmScreen.note(for: Suggestion(name: "x", source: .labelsOnly, fallbackReason: "Off.")) == "Off. This is Vision's rough label.")
        #expect(ConfirmScreen.note(for: Suggestion(name: "", source: .none, fallbackReason: "Off.")) == "Off.")
    }

    @Test func homeEmpty() {
        check(home(items: []), named: "home-empty")
    }

    @Test func homeWithItems() {
        check(home(items: Fixtures.items), named: "home")
    }

    @Test func room() {
        let garage = Fixtures.items.filter { $0.room == "Garage" }
        check(NavigationStack { RoomView(room: "Garage", items: garage, thumbnails: Fixtures.thumbnails) }, named: "room")
    }

    @Test func itemDetail() {
        let item = Fixtures.items[0]
        check(NavigationStack { ItemDetailView(item: item, photo: Fixtures.photo(Fixtures.symbols[0])) }, named: "item")
    }

    private func home(items: [Item]) -> some View {
        NavigationStack {
            HomeView(items: items, thumbnails: Fixtures.thumbnails, stats: CaptureStats(items: items))
                .safeAreaInset(edge: .bottom) { AddButton {} }
        }
    }

    private func form(_ draft: Draft, suggesting: Bool, note: String? = nil, aspects: [SuggestedAspect] = [], rooms: [String]) -> some View {
        NavigationStack {
            ItemForm(photo: Fixtures.photo("wrench.and.screwdriver"), draft: .constant(draft), suggesting: suggesting,
                     suggestionNote: note, aspects: aspects, rooms: rooms, onSave: {})
        }
    }
}

enum Fixtures {
    struct NoSuggestions: ItemSuggesting {
        func suggest(for image: CGImage) async -> Suggestion { .empty }
    }

    static let symbols = ["wrench.and.screwdriver", "hammer", "tent", "bicycle"]

    static var thumbnails: [UUID: UIImage] {
        Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, photo(symbols[$0])) })
    }

    static let items: [Item] = [
        Item(name: "DeWalt 18V cordless drill", category: "Tools", room: "Garage", spot: "Left shelf",
             aspects: [Aspect(name: "Brand", value: "DeWalt"), Aspect(name: "Battery", value: "2 × 2 Ah")],
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
