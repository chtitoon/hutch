import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum PhotoEncoder {
  public static let photoMaxPixels = 2048
  // A 56 pt thumbnail at 3x.
  public static let thumbnailMaxPixels = 180

  // HEIC rather than JPEG, so a cutout keeps its transparent background.
  public static func heic(_ image: CGImage, maxPixels: Int, quality: Double = 0.8) throws -> Data {
    let scaled = try downscale(image, maxPixels: maxPixels)
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data,
        UTType.heic.identifier as CFString,
        1,
        nil
      )
    else {
      throw PhotoEncoderError.encodingFailed
    }
    CGImageDestinationAddImage(
      destination,
      scaled,
      [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
    )
    guard CGImageDestinationFinalize(destination) else { throw PhotoEncoderError.encodingFailed }
    return data as Data
  }

  /// A camera or library photo, decoded upright at no more than `maxPixels`, off the main actor.
  public static func uprightImage(from data: Data, maxPixels: Int) async -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    // ImageIO decodes straight to the size asked and applies the photo's rotation in one pass.
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixels,
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }

  public static func image(from data: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }

  static func downscale(_ image: CGImage, maxPixels: Int) throws -> CGImage {
    let longEdge = max(image.width, image.height)
    guard longEdge > maxPixels else { return image }
    let scale = Double(maxPixels) / Double(longEdge)
    let width = max(1, Int((Double(image.width) * scale).rounded()))
    let height = max(1, Int((Double(image.height) * scale).rounded()))
    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: (image.hasAlpha
          ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue
      )
    else { throw PhotoEncoderError.encodingFailed }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let scaled = context.makeImage() else { throw PhotoEncoderError.encodingFailed }
    return scaled
  }
}

extension CGImage {
  var hasAlpha: Bool {
    ![.none, .noneSkipFirst, .noneSkipLast].contains(alphaInfo)
  }
}

public enum PhotoEncoderError: Error {
  case encodingFailed
}
