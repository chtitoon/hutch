import CoreGraphics
import CoreImage
import Testing

@testable import HutchCore

// Vision can't run in the simulator, so these cover what's around it; the cutout itself is
// checked on the phone.
@Suite struct PhotoCutoutTests {
  @Test func largestInstanceIgnoresTheBackground() {
    #expect(PhotoCutout.largestInstance(in: [0, 0, 0, 0, 1, 2, 2, 0]) == 2)
  }

  @Test func noInstanceWhenAllIsBackground() {
    #expect(PhotoCutout.largestInstance(in: [0, 0, 0]) == nil)
  }

  @Test func cutoutIsCenteredOnATransparentSquareWithItsMargin() throws {
    let wide = try #require(Self.opaque(width: 80, height: 40))
    let square = try #require(PhotoCutout.square(wide, margin: 0.1))
    #expect(square.width == 100)
    #expect(square.height == 100)
    let alpha = try Self.alpha(of: square)
    #expect(alpha(50, 50) == 255)
    // 10 px of margin on the long sides, 30 px on the short ones.
    #expect(alpha(9, 50) == 0)
    #expect(alpha(10, 50) == 255)
    #expect(alpha(89, 50) == 255)
    #expect(alpha(90, 50) == 0)
    #expect(alpha(50, 29) == 0)
    #expect(alpha(50, 30) == 255)
    #expect(alpha(50, 69) == 255)
    #expect(alpha(50, 70) == 0)
  }

  @Test func opaqueBoundsCountRowsFromTheTop() {
    let alpha: [UInt8] = [
      0, 0, 0, 0,
      0, 9, 0, 0,
      0, 255, 255, 0,
    ]
    #expect(
      PhotoCutout.opaqueBounds(alpha: alpha, width: 4) == CGRect(x: 1, y: 1, width: 2, height: 2)
    )
    #expect(PhotoCutout.opaqueBounds(alpha: [0, 0], width: 2) == nil)
  }

  // A square mask off-center in the photo, as if the item wasn't framed well.
  @Test func liftedItemHasASoftEdgeAndIsCentered() throws {
    let photo = try #require(Self.opaque(width: 2000, height: 2000))
    let mask = CIImage(color: .white)
      .cropped(to: CGRect(x: 200, y: 600, width: 1000, height: 1000))
      .composited(over: CIImage(color: .black))
      .cropped(to: CGRect(x: 0, y: 0, width: 2000, height: 2000))
    let lifted = try #require(PhotoCutout.lift(photo, mask: mask))
    #expect(lifted.width == lifted.height)
    let alpha = try Self.alpha(of: lifted)
    let middle = lifted.width / 2
    #expect(alpha(middle, middle) == 255)
    #expect(alpha(2, middle) == 0)
    // The edge fades over a few pixels instead of stepping from clear to solid.
    let row = (0..<lifted.width).map { alpha($0, middle) }
    #expect(row.filter { $0 > 0 && $0 < 255 }.count >= 6)
    // Centered: as much clear space on the left as on the right.
    let left = try #require(row.firstIndex { $0 > 0 })
    let right = try #require(row.lastIndex { $0 > 0 })
    #expect(abs(left - (lifted.width - 1 - right)) <= 1)
  }

  static func opaque(width: Int, height: Int) -> CGImage? {
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    context?.setFillColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
    context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return context?.makeImage()
  }

  /// Reads a pixel's alpha, from the top-left corner.
  static func alpha(of image: CGImage) throws -> (Int, Int) -> UInt8 {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress,
          width: image.width,
          height: image.height,
          bitsPerComponent: 8,
          bytesPerRow: image.width * 4,
          space: CGColorSpace(name: CGColorSpace.sRGB)!,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
      return true
    }
    try #require(drawn)
    return { x, y in pixels[(y * image.width + x) * 4 + 3] }
  }
}
