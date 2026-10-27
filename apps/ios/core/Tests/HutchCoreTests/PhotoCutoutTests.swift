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

  // Vision's mask, stretched from a small grid, steps where the photo's edge is a smooth curve.
  @Test func smoothedMaskFollowsThePhotosOutline() throws {
    let circle = CGRect(x: 120, y: 140, width: 260, height: 260)
    let photo = try #require(Self.disc(in: circle, size: 512, ink: 0.1, paper: 0.9))
    let truth = try Self.gray(of: try #require(Self.disc(in: circle, size: 512, ink: 1, paper: 0)))
    let blocky = try #require(Self.disc(in: circle, size: 512, ink: 1, paper: 0, grid: 32))
    let smoothed = try #require(
      CIContext().createCGImage(
        PhotoCutout.smoothed(CIImage(cgImage: blocky), guide: CIImage(cgImage: photo), grid: 32),
        from: CGRect(x: 0, y: 0, width: 512, height: 512)
      )
    )
    let blockyError = Self.edgeError(try Self.gray(of: blocky), truth: truth)
    let smoothedError = Self.edgeError(try Self.gray(of: smoothed), truth: truth)
    #expect(smoothedError < blockyError / 10, "smoothed \(smoothedError), blocky \(blockyError)")
  }

  @Test func liftedItemIsCenteredHoweverItWasFramed() throws {
    let circle = CGRect(x: 40, y: 220, width: 200, height: 200)
    let photo = try #require(Self.disc(in: circle, size: 512, ink: 0.1, paper: 0.9))
    let mask = try #require(Self.disc(in: circle, size: 512, ink: 1, paper: 0))
    let lifted = try #require(PhotoCutout.lift(photo, mask: CIImage(cgImage: mask)))
    #expect(lifted.width == lifted.height)
    let alpha = try Self.alpha(of: lifted)
    let middle = lifted.width / 2
    #expect(alpha(middle, middle) == 255)
    let row = (0..<lifted.width).map { alpha($0, middle) }
    let left = try #require(row.firstIndex { $0 > 0 })
    let right = try #require(row.lastIndex { $0 > 0 })
    #expect(abs(left - (lifted.width - 1 - right)) <= lifted.width / 50)
  }

  /// A gray disc on a gray ground; with a `grid`, drawn on that grid and blown up, blocky.
  static func disc(
    in rect: CGRect,
    size: Int,
    ink: CGFloat,
    paper: CGFloat,
    grid: Int? = nil
  ) -> CGImage? {
    let side = grid ?? size
    let scale = CGFloat(side) / CGFloat(size)
    let context = CGContext(
      data: nil,
      width: side,
      height: side,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: CGImageAlphaInfo.none.rawValue
    )
    context?.setFillColor(gray: paper, alpha: 1)
    context?.fill(CGRect(x: 0, y: 0, width: side, height: side))
    context?.setFillColor(gray: ink, alpha: 1)
    context?.fillEllipse(
      in: CGRect(
        x: rect.minX * scale,
        y: rect.minY * scale,
        width: rect.width * scale,
        height: rect.height * scale
      )
    )
    guard let image = context?.makeImage() else { return nil }
    guard grid != nil else { return image }
    let large = CGContext(
      data: nil,
      width: size,
      height: size,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: CGImageAlphaInfo.none.rawValue
    )
    large?.interpolationQuality = .none
    large?.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    return large?.makeImage()
  }

  static func gray(of image: CGImage) throws -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height)
    let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress,
          width: image.width,
          height: image.height,
          bitsPerComponent: 8,
          bytesPerRow: image.width,
          space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
      return true
    }
    try #require(drawn)
    return pixels
  }

  /// How far a mask is from the true one, summed over every pixel, per thousand pixels.
  static func edgeError(_ mask: [UInt8], truth: [UInt8]) -> Double {
    var total = 0
    for (value, expected) in zip(mask, truth) where value != expected {
      total += abs(Int(value) - Int(expected))
    }
    return Double(total) / Double(mask.count) * 1000
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
