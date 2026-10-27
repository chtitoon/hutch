import CoreGraphics
import CoreImage
import Vision

/// The item lifted out of its photo by Vision, on the device (D5), and centered on a transparent
/// square so it sits the same way in a thumbnail and on the item screen.
public enum PhotoCutout {
  // Room around the item on each side, as a share of the square's side.
  public static let margin = 0.1
  // Low GPU priority, so drawing the screen and the keyboard come first.
  private static var context: CIContext { CIContext(options: [.priorityRequestLow: true]) }

  public enum Edge: Sendable {
    // Vision's mask stretched to the photo, as Photos lifts a subject: its edge steps.
    case vision
    case smoothed
  }

  /// Nil when Vision finds nothing to lift: the photo is then kept as it is.
  public static func cutout(of photo: CGImage, edge: Edge = .smoothed) async throws -> CGImage? {
    // At the stored size: a bigger photo only costs time.
    let image = try PhotoEncoder.downscale(photo, maxPixels: PhotoEncoder.photoMaxPixels)
    let handler = ImageRequestHandler(image)
    guard let observation = try await handler.perform(GenerateForegroundInstanceMaskRequest()),
      let instance = try item(in: observation)
    else { return nil }
    switch edge {
    case .vision:
      let masked = try observation.generateMaskedImage(
        for: [instance],
        imageFrom: handler,
        croppedToInstancesExtent: true
      )
      let lifted = CIImage(cvPixelBuffer: masked)
      guard let cropped = context.createCGImage(lifted, from: lifted.extent) else { return nil }
      return square(cropped)
    case .smoothed:
      let mask = try observation.generateScaledMask(for: [instance], scaledToImageFrom: handler)
      let grid = observation.allInstancesMask.size
      return lift(
        image,
        mask: smoothed(
          CIImage(cvPixelBuffer: mask),
          guide: CIImage(cgImage: image),
          grid: max(grid.width, grid.height)
        )
      )
    }
  }

  // Vision's mask is a small grid stretched to the photo, so its edge steps. Shrunk back to that
  // grid, each step is a pixel, and Core Image rebuilds it full size along the photo's outlines.
  static func smoothed(_ mask: CIImage, guide: CIImage, grid: Double) -> CIImage {
    let small = mask.applyingFilter(
      "CILanczosScaleTransform",
      parameters: [
        kCIInputScaleKey: grid / max(mask.extent.width, mask.extent.height),
        kCIInputAspectRatioKey: 1,
      ]
    )
    // The upsampling places the edge well but leaves a haze of up to 20% around it: everything
    // under a quarter is cleared and over three quarters made solid, a 35-fold gain in tests.
    return guide.applyingFilter(
      "CIEdgePreserveUpsampleFilter",
      parameters: ["inputSmallImage": small]
    )
    .applyingFilter(
      "CIColorMatrix",
      parameters: [
        "inputRVector": CIVector(x: 2, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 2, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 2, w: 0),
        "inputBiasVector": CIVector(x: -0.5, y: -0.5, z: -0.5, w: 0),
      ]
    )
    .applyingFilter("CIColorClamp")
    .cropped(to: guide.extent)
  }

  /// The image where `mask` is white, centered on a transparent square.
  static func lift(_ image: CGImage, mask: CIImage) -> CGImage? {
    let photo = CIImage(cgImage: image)
    let lifted = photo.applyingFilter(
      "CIBlendWithMask",
      parameters: [kCIInputBackgroundImageKey: CIImage.empty(), kCIInputMaskImageKey: mask]
    )
    guard let full = context.createCGImage(lifted, from: photo.extent),
      let bounds = opaqueBounds(of: full),
      let cropped = full.cropping(to: bounds)
    else { return nil }
    return square(cropped)
  }

  // Found on a small copy, so it's quick; it errs a few pixels wide, never into the item.
  static func opaqueBounds(of image: CGImage) -> CGRect? {
    let scale = min(1, 256 / Double(max(image.width, image.height)))
    let width = max(1, Int((Double(image.width) * scale).rounded(.up)))
    let height = max(1, Int((Double(image.height) * scale).rounded(.up)))
    guard
      let small = opaqueBounds(
        alpha: alpha(of: image, width: width, height: height),
        width: width
      )
    else { return nil }
    let cell = Double(image.width) / Double(width)
    return CGRect(
      x: (small.minX - 1) * cell,
      y: (small.minY - 1) * cell,
      width: (small.width + 2) * cell,
      height: (small.height + 2) * cell
    )
    .integral
    .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
  }

  /// The smallest rectangle, top-left origin, holding every pixel that isn't fully transparent.
  static func opaqueBounds(alpha: [UInt8], width: Int) -> CGRect? {
    var minX = width
    var minY = Int.max
    var maxX = -1
    var maxY = -1
    for (index, value) in alpha.enumerated() where value > 0 {
      let x = index % width
      let y = index / width
      minX = min(minX, x)
      maxX = max(maxX, x)
      minY = min(minY, y)
      maxY = max(maxY, y)
    }
    guard maxX >= 0 else { return nil }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
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

  // Rows top first, as CGImage.cropping(to:) counts them.
  static func alpha(of image: CGImage, width: Int, height: Int) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    pixels.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
      context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
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
