import SwiftUI
import UIKit

/// The system camera without its own controls, so one tap on Hutch's shutter takes the photo.
struct CameraView: UIViewControllerRepresentable {
  let shutter: CameraShutter
  let onPhoto: (UIImage) -> Void

  static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.showsCameraControls = false
    picker.delegate = context.coordinator
    shutter.picker = picker
    return picker
  }

  func updateUIViewController(_ picker: UIImagePickerController, context: Context) {
    context.coordinator.onPhoto = onPhoto
    // The preview is 4:3 at the top; scale it to fill the screen, centered.
    let bounds = picker.view.bounds
    guard bounds.width > 0 else { return }
    let previewHeight = bounds.width * 4 / 3
    let scale = max(1, bounds.height / previewHeight)
    picker.cameraViewTransform = CGAffineTransform(
      translationX: 0,
      y: (bounds.height - previewHeight) / 2
    ).scaledBy(x: scale, y: scale)
  }

  func makeCoordinator() -> Coordinator { Coordinator(onPhoto: onPhoto) }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {
    var onPhoto: (UIImage) -> Void
    init(onPhoto: @escaping (UIImage) -> Void) { self.onPhoto = onPhoto }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage { onPhoto(image) }
    }
  }
}

@MainActor
final class CameraShutter {
  weak var picker: UIImagePickerController?
  func fire() { picker?.takePicture() }
}

extension UIImage {
  /// Drawn upright, since camera photos are stored rotated.
  func uprightImage(maxPixels: CGFloat) -> CGImage? {
    let longEdge = max(size.width * scale, size.height * scale)
    let factor = min(1, maxPixels / longEdge)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let target = CGSize(
      width: (size.width * scale * factor).rounded(),
      height: (size.height * scale * factor).rounded()
    )
    return UIGraphicsImageRenderer(size: target, format: format).image { _ in
      draw(in: CGRect(origin: .zero, size: target))
    }.cgImage
  }
}
