import CoreGraphics
import CoreImage
import Vision

/// The item lifted out of its photo by Vision, on the device (D5), and centered on a transparent
/// square so it sits the same way in a thumbnail and on the item screen.
public enum PhotoCutout {
  // Room around the item on each side, as a share of the square's side.
  public static let margin = 0.1

  /// Nil when Vision finds nothing to lift: the photo is then kept as it is.
  public static func cutout(of photo: CGImage) async throws -> CGImage? {
    // At the stored size: a bigger photo only costs time.
    let image = try PhotoEncoder.downscale(photo, maxPixels: PhotoEncoder.photoMaxPixels)
    let handler = ImageRequestHandler(image)
    guard let observation = try await handler.perform(GenerateForegroundInstanceMaskRequest()),
      let instance = try item(in: observation)
    else { return nil }
    // Vision's own edge, as Photos lifts a subject; a feathered one of ours looked worse.
    let masked = try observation.generateMaskedImage(
      for: [instance],
      imageFrom: handler,
      croppedToInstancesExtent: true
    )
    let lifted = CIImage(cvPixelBuffer: masked)
    guard let cropped = CIContext().createCGImage(lifted, from: lifted.extent) else { return nil }
    return square(cropped)
  }

  // The camera's frame and its hint put the item in the middle; failing that, the largest thing.
  static func item(in observation: InstanceMaskObservation) throws -> Int? {
    if let centered = observation.instanceAtPoint(NormalizedPoint(x: 0.5, y: 0.5)).first {
      return centered
    }
    return largestInstance(in: labels(of: try observation.allInstancesMask.cgImage))
  }

  /// The label covering the most pixels; 0 is the background.
  static func largestInstance(in labels: [UInt8]) -> Int? {
    var counts = [Int](repeating: 0, count: 256)
    for label in labels where label != 0 { counts[Int(label)] += 1 }
    guard let largest = counts.indices.max(by: { counts[$0] < counts[$1] }), counts[largest] > 0
    else { return nil }
    return largest
  }

  static func square(_ image: CGImage, margin: Double = margin) -> CGImage? {
    let side = Int((Double(max(image.width, image.height)) / (1 - 2 * margin)).rounded(.up))
    guard
      let context = CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }
    context.draw(
      image,
      in: CGRect(
        x: (side - image.width) / 2,
        y: (side - image.height) / 2,
        width: image.width,
        height: image.height
      )
    )
    return context.makeImage()
  }

  // Vision's mask holds one byte per pixel, each its instance's label.
  private static func labels(of mask: CGImage) -> [UInt8] {
    var labels = [UInt8](repeating: 0, count: mask.width * mask.height)
    labels.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: mask.width,
        height: mask.height,
        bitsPerComponent: 8,
        bytesPerRow: mask.width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
      )
      context?.draw(mask, in: CGRect(x: 0, y: 0, width: mask.width, height: mask.height))
    }
    return labels
  }
}
