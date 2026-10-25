import CoreGraphics
import Foundation
import Testing
@testable import HutchCore

@Suite struct ItemTests {
    @Test func survivesARoundTrip() throws {
        let item = Item(name: "Ladder", room: "Garage", spot: "Back wall")
        #expect(try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item)) == item)
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

    /// Items saved by earlier builds on my phone: one had `place` and a resale price, a later
    /// one a category, aspects and the suggestion's record. They still open.
    @Test func readsItemsFromEarlierBuilds() throws {
        let first = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Drill","category":"Tools","place":"Garage","resalePrice":45,"currency":"EUR","visibility":"private","createdAt":0}"#
        let drill = try JSONDecoder().decode(Item.self, from: Data(first.utf8))
        #expect(drill.name == "Drill")
        #expect(drill.room == "Garage")
        #expect(drill.spot.isEmpty)

        let later = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Laptop","category":"Electronics","room":"Office","spot":"","aspects":[{"name":"Brand","value":"Apple"}],"visibility":"private","createdAt":0,"capture":{"seconds":12,"suggestionSource":"catalog","keptSuggestedName":true}}"#
        let laptop = try JSONDecoder().decode(Item.self, from: Data(later.utf8))
        #expect(laptop == Item(id: laptop.id, name: "Laptop", room: "Office", createdAt: Date(timeIntervalSinceReferenceDate: 0)))
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
