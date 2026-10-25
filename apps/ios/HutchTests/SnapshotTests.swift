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
        check(NavigationStack { ItemDetailView(item: Fixtures.items[0], photo: Fixtures.photo(Fixtures.symbols[0])) }, named: "item")
    }

    @Test func captureWithoutCamera() {
        check(CaptureScreen(library: Library(store: nil), cameraAvailable: false), named: "capture")
    }

    /// No rooms yet: no Apple Home rooms, nothing added. The room is typed.
    @Test func addWithoutRooms() {
        check(form(Draft(), rooms: []), named: "add-empty")
    }

    @Test func addWithRooms() {
        let draft = Draft(name: "DeWalt 18V cordless drill", room: "Garage", spot: "Left shelf")
        check(form(draft, rooms: ["Garage", "Attic", "Kitchen", "Living Room", "Bedroom", "Office", "Basement"]), named: "add")
    }

    private func home(items: [Item]) -> some View {
        NavigationStack {
            HomeView(items: items, thumbnails: Fixtures.thumbnails)
                .safeAreaInset(edge: .bottom) { AddButton {} }
        }
    }

    private func form(_ draft: Draft, rooms: [String]) -> some View {
        NavigationStack {
            ItemForm(photo: Fixtures.photo("wrench.and.screwdriver"), draft: .constant(draft), rooms: rooms, onSave: {})
        }
    }
}

enum Fixtures {
    static let symbols = ["wrench.and.screwdriver", "hammer", "tent", "bicycle"]

    static let items: [Item] = [
        Item(name: "DeWalt 18V cordless drill", room: "Garage", spot: "Left shelf", createdAt: Date(timeIntervalSince1970: 4)),
        Item(name: "Aluminium step ladder", room: "Garage", spot: "Back wall", createdAt: Date(timeIntervalSince1970: 3)),
        Item(name: "Quechua 2-person tent", room: "Attic", createdAt: Date(timeIntervalSince1970: 2)),
        Item(name: "Kids' bike", createdAt: Date(timeIntervalSince1970: 1)),
    ]

    static var thumbnails: [UUID: UIImage] {
        Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, photo(symbols[$0])) })
    }

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
