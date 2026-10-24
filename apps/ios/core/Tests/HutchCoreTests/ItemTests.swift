import CoreGraphics
import Foundation
import Testing
@testable import HutchCore

@Suite struct ItemTests {
    /// Non-negotiable 2: new items are private.
    @Test func newItemsArePrivate() {
        #expect(Item(name: "Ladder").visibility == .private)
    }

    @Test func privateSurvivesAStoreRoundTrip() throws {
        let item = Item(name: "Ladder")
        let decoded = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item))
        #expect(decoded.visibility == .private)
    }

    @Test func roomsUsedComeFirstThenHomeRoomsEachOnce() {
        let items = [
            Item(name: "a", room: "Garage", createdAt: .init(timeIntervalSince1970: 1)),
            Item(name: "b", room: " Attic ", createdAt: .init(timeIntervalSince1970: 3)),
            Item(name: "c", room: "garage", createdAt: .init(timeIntervalSince1970: 4)),
            Item(name: "d", room: "", createdAt: .init(timeIntervalSince1970: 5)),
        ]
        #expect(Item.rooms(used: items, home: ["Kitchen", "Attic", "Garage"]) == ["garage", "Attic", "Kitchen"])
        #expect(Item.rooms(used: [], home: []).isEmpty)
    }

    @Test func placeJoinsRoomAndSpot() {
        #expect(Item(name: "x", room: "Garage", spot: " left shelf").place == "Garage · left shelf")
        #expect(Item(name: "x", room: "Garage").place == "Garage")
        #expect(Item(name: "x").place.isEmpty)
    }
}

@Suite struct VaultTests {
    @Test func roundTrips() throws {
        let vault = Vault(key: Vault.newKey())
        let sealed = try vault.seal(Data("hello".utf8), context: "x")
        #expect(try vault.open(sealed, context: "x") == Data("hello".utf8))
    }

    @Test func sealsDifferentlyEachTime() throws {
        let vault = Vault(key: Vault.newKey())
        #expect(try vault.seal(Data("hello".utf8), context: "x") != vault.seal(Data("hello".utf8), context: "x"))
    }

    @Test func wrongContextFails() throws {
        let vault = Vault(key: Vault.newKey())
        let sealed = try vault.seal(Data("hello".utf8), context: "a.item")
        #expect(throws: (any Error).self) { try vault.open(sealed, context: "b.item") }
    }

    @Test func tamperingFails() throws {
        let vault = Vault(key: Vault.newKey())
        var sealed = try vault.seal(Data("hello".utf8), context: "x")
        sealed[sealed.count / 2] ^= 0x01
        #expect(throws: (any Error).self) { try vault.open(sealed, context: "x") }
    }
}

@Suite struct CaptureStatsTests {
    func item(_ seconds: Double, _ source: SuggestionSource, kept: Bool) -> Item {
        Item(name: "x", capture: CaptureRecord(
            seconds: seconds, suggestionSeconds: source == .none ? nil : 1.5, suggestionSource: source, keptSuggestedName: kept))
    }

    @Test func countsH1AndX4Signals() {
        let stats = CaptureStats(items: [
            item(12, .modelWithImage, kept: true),
            item(25, .labelsOnly, kept: false),
            item(8, .none, kept: false),
            Item(name: "typed in"),
        ])
        #expect(stats.itemCount == 4)
        #expect(stats.timedCount == 3)
        #expect(stats.medianSeconds == 12)
        #expect(stats.underTargetCount == 2)
        #expect(stats.suggestedCount == 2)
        #expect(stats.keptSuggestionCount == 1)
        #expect(stats.medianSuggestionSeconds == 1.5)
    }

    @Test func medianOfEvenCount() {
        #expect(CaptureStats.median([4, 1, 3, 2]) == 2.5)
        #expect(CaptureStats.median([]) == nil)
    }
}

@Suite struct SuggestionTests {
    @Test func fallbackSkipsGenericLabels() {
        let findings = VisionFindings(labels: ["tool", "power_drill", "machine"], text: ["DEWALT"])
        #expect(findings.fallbackSuggestion(because: "off") == Suggestion(name: "DEWALT Power drill", source: .labelsOnly, fallbackReason: "off"))
    }

    @Test func brandIsTheFirstWordThatLooksLikeOne() {
        let charger = VisionFindings(labels: ["computer"], text: ["INPUT 100-240V", "RAVPOWER", "USB-C 61W"])
        #expect(charger.brand == "RAVPOWER")
        #expect(charger.fallbackName == "RAVPOWER Computer")
    }

    @Test func noBrandFromLabelWordsOrNumbers() {
        #expect(VisionFindings(labels: [], text: ["Made in China", "61W", "USB-C"]).brand == nil)
        #expect(VisionFindings(labels: ["ladder"], text: []).fallbackName == "Ladder")
    }

    @Test func brandAloneWhenThereIsNoLabel() {
        #expect(VisionFindings(labels: [], text: ["Anker"]).fallbackName == "Anker")
    }

    /// E2: a laptop on a wooden table, its screen full of text, was named "Wooden Box".
    @Test func screenTextAndSceneLabelsDontNameTheObject() {
        let laptop = VisionFindings(
            labels: ["wood_processed", "table", "computer", "laptop"],
            text: [
                "func suggest(for image: CGImage) async -> Suggestion {",
                "Wooden Box was named by the model on this iPhone today",
                "let findings = await Self.see(subject) and then more code",
                "You help someone catalog the things they own at home",
                "MacBook Pro",
            ]
        )
        #expect(laptop.objectLabels == ["computer", "laptop"])
        #expect(laptop.sceneLabels == ["wood_processed", "table"])
        #expect(laptop.printedText == ["MacBook Pro"])
        #expect(laptop.brand == "MacBook")
        #expect(laptop.fallbackName == "MacBook Computer")
        let details = OnDeviceSuggester.details(laptop)
        #expect(details.contains("not the object: wood_processed, table"))
        #expect(details.contains("probably a screen"))
        #expect(!details.contains("Wooden Box"))
    }

    @Test func promptPassesTheBrandOn() {
        #expect(OnDeviceSuggester.details(VisionFindings(labels: ["computer"], text: ["RAVPOWER"])).contains("The brand is probably RAVPOWER."))
    }

    @Test func fallbackUsesAGenericLabelIfThatsAllThereIs() {
        #expect(VisionFindings(labels: ["furniture"], text: []).fallbackName == "Furniture")
    }

    @Test func noLabelsNoSuggestionButStillAReason() {
        #expect(VisionFindings(labels: [], text: []).fallbackSuggestion(because: "off") == Suggestion(name: "", source: .none, fallbackReason: "off"))
    }

    @Test func unknownIsNoName() {
        #expect(Suggestion.isPlaceholder("Unknown"))
        #expect(Suggestion.isPlaceholder("unknow."))
        #expect(Suggestion.isPlaceholder("  "))
        #expect(!Suggestion.isPlaceholder("Laptop charger"))
    }

    @Test func promptCarriesWhatVisionSaw() {
        let details = OnDeviceSuggester.details(VisionFindings(labels: ["ladder"], text: ["Werner"]))
        #expect(details.contains("ladder"))
        #expect(details.contains("Werner"))
    }
}

@Suite struct PhotoEncoderTests {
    @Test func downscalesToTheLongEdge() throws {
        let context = CGContext(data: nil, width: 400, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let jpeg = try PhotoEncoder.jpeg(context.makeImage()!, maxPixels: 100)
        let decoded = try #require(PhotoEncoder.image(from: jpeg))
        #expect(decoded.width == 100)
        #expect(decoded.height == 50)
    }
}
