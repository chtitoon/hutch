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
    #expect(
      Item.roomSuggestions(from: items, homeRooms: ["Kitchen", "Attic", "Garage"]) == [
        "garage", "Attic", "Kitchen",
      ]
    )
    #expect(Item.roomSuggestions(from: [], homeRooms: []).isEmpty)
  }

  @Test func namesStartWithACapital() {
    #expect(Item(name: " cordless drill ").name == "Cordless drill")
    #expect(Item(name: "DeWalt 18V drill").name == "DeWalt 18V drill")
    #expect(Item(name: "iPhone case").name == "iPhone case")
    #expect(Item(name: "eBay box").name == "eBay box")
    #expect(Item(name: "18V battery").name == "18V battery")
    #expect(Item(name: "élan skis").name == "Élan skis")
  }

  @Test func renamedItemsStartWithACapital() {
    var item = Item(name: "Ladder")
    item.name = "step ladder"
    #expect(item.name == "Step ladder")
  }

  @Test func placeJoinsRoomAndSpot() {
    #expect(Item(name: "x", room: "Garage", spot: " left shelf").place == "Garage · left shelf")
    #expect(Item(name: "x", room: "Garage").place == "Garage")
    #expect(Item(name: "x").place.isEmpty)
  }
}

@Suite struct VaultTests {
  @Test func roundTrips() throws {
    let vault = Vault(key: Vault.makeKey())
    let sealed = try vault.seal(Data("hello".utf8), context: "x")
    #expect(try vault.open(sealed, context: "x") == Data("hello".utf8))
  }

  @Test func sealsDifferentlyEachTime() throws {
    let vault = Vault(key: Vault.makeKey())
    #expect(
      try vault.seal(Data("hello".utf8), context: "x")
        != vault.seal(Data("hello".utf8), context: "x")
    )
  }

  @Test func wrongContextFails() throws {
    let vault = Vault(key: Vault.makeKey())
    let sealed = try vault.seal(Data("hello".utf8), context: "a.item")
    #expect(throws: (any Error).self) { try vault.open(sealed, context: "b.item") }
  }

  @Test func tamperingFails() throws {
    let vault = Vault(key: Vault.makeKey())
    var sealed = try vault.seal(Data("hello".utf8), context: "x")
    sealed[sealed.count / 2] ^= 0x01
    #expect(throws: (any Error).self) { try vault.open(sealed, context: "x") }
  }
}

@Suite struct PhotoEncoderTests {
  @Test func downscalesToTheLongEdge() throws {
    let context = CGContext(
      data: nil,
      width: 400,
      height: 200,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    let jpeg = try PhotoEncoder.jpeg(context.makeImage()!, maxPixels: 100)
    let decoded = try #require(PhotoEncoder.image(from: jpeg))
    #expect(decoded.width == 100)
    #expect(decoded.height == 50)
  }
}
