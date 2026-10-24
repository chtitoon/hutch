import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns a captured image into the JPEGs the store keeps, in memory only: the bytes go
/// straight to `ItemStore`, which seals them before anything touches the disk.
public enum PhotoEncoder {
    /// Long edge of the stored photo, enough to recognize the thing and read a label on it.
    public static let photoMaxPixels = 2048
    /// Long edge of the list thumbnail (56 pt at 3x, rounded up).
    public static let thumbnailMaxPixels = 180

    public static func jpeg(_ image: CGImage, maxPixels: Int, quality: Double = 0.8) throws -> Data {
        let scaled = try downscale(image, maxPixels: maxPixels)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoEncoderError.encodingFailed
        }
        CGImageDestinationAddImage(destination, scaled, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoEncoderError.encodingFailed }
        return data as Data
    }

    public static func image(from jpeg: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(jpeg as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    static func downscale(_ image: CGImage, maxPixels: Int) throws -> CGImage {
        let longEdge = max(image.width, image.height)
        guard longEdge > maxPixels else { return image }
        let scale = Double(maxPixels) / Double(longEdge)
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw PhotoEncoderError.encodingFailed }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage() else { throw PhotoEncoderError.encodingFailed }
        return scaled
    }
}

public enum PhotoEncoderError: Error {
    case encodingFailed
}
