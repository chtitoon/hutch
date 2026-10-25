import CoreGraphics

public enum PhotoCrop {
  /// The part of a photo inside `frame`, when the photo fills `screen` the way the camera preview
  /// does: scaled to fill and centered, its overflow cut off.
  public static func rect(inside frame: CGRect, screen: CGSize, photo: CGSize) -> CGRect {
    let scale = max(screen.width / photo.width, screen.height / photo.height)
    let overflowX = (photo.width * scale - screen.width) / 2
    let overflowY = (photo.height * scale - screen.height) / 2
    let rect = CGRect(
      x: (frame.minX + overflowX) / scale,
      y: (frame.minY + overflowY) / scale,
      width: frame.width / scale,
      height: frame.height / scale
    )
    return rect.intersection(CGRect(origin: .zero, size: photo)).integral
  }
}
