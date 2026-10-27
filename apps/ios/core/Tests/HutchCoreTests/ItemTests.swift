import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import HutchCore

@Suite struct ItemTests {
  @Test func survivesARoundTrip() throws {
    let item = Item(name: "Ladder", room: "Garage")
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

  @Test func roomsAreTrimmed() {
    #expect(Item(name: "Ladder", room: " Garage ").room == "Garage")
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

@Suite struct PhotoCropTests {
  // A 3:4 photo on a taller screen: it fills the height, and its sides are cut off.
  let screen = CGSize(width: 400, height: 800)
  let photo = CGSize(width: 3000, height: 4000)

  @Test func mapsTheFrameIntoThePhoto() {
    let frame = CGRect(x: 40, y: 200, width: 320, height: 320)
    #expect(
      PhotoCrop.rect(inside: frame, screen: screen, photo: photo)
        == CGRect(x: 700, y: 1000, width: 1600, height: 1600)
    )
  }

  @Test func theWholeScreenIsTheVisiblePart() {
    let visible = PhotoCrop.rect(
      inside: CGRect(origin: .zero, size: screen),
      screen: screen,
      photo: photo
    )
    #expect(visible == CGRect(x: 500, y: 0, width: 2000, height: 4000))
  }

  @Test func neverReachesOutsideThePhoto() {
    let frame = CGRect(x: -50, y: -50, width: 600, height: 1000)
    #expect(
      PhotoCrop.rect(inside: frame, screen: screen, photo: photo)
        == CGRect(x: 250, y: 0, width: 2750, height: 4000)
    )
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
    let heic = try PhotoEncoder.heic(context.makeImage()!, maxPixels: 100)
    let decoded = try #require(PhotoEncoder.image(from: heic))
    #expect(decoded.width == 100)
    #expect(decoded.height == 50)
    #expect(!decoded.hasAlpha)
  }

  // The camera stores a portrait photo landscape, tagged to be turned a quarter clockwise.
  @Test func decodesACameraPhotoUprightAndSmaller() async throws {
    let landscape = try #require(PhotoCutoutTests.opaque(width: 400, height: 200))
    let data = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
    )
    CGImageDestinationAddImage(
      destination,
      landscape,
      [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue] as CFDictionary
    )
    try #require(CGImageDestinationFinalize(destination))
    let upright = try #require(await PhotoEncoder.uprightImage(from: data as Data, maxPixels: 100))
    #expect(upright.width == 50)
    #expect(upright.height == 100)
  }

  @Test func keepsACutoutsTransparentBackground() throws {
    let opaque = try #require(PhotoCutoutTests.opaque(width: 400, height: 400))
    let cutout = try #require(PhotoCutout.square(opaque))
    let decoded = try #require(
      PhotoEncoder.image(from: try PhotoEncoder.heic(cutout, maxPixels: 100))
    )
    let alpha = try PhotoCutoutTests.alpha(of: decoded)
    #expect(alpha(0, 0) == 0)
    #expect(alpha(50, 50) == 255)
  }
}
