import AVFoundation
import SwiftUI
import UIKit

/// The back camera, with a preview that fills the screen and photos cropped to a part of it.
@MainActor
@Observable
final class Camera: NSObject {
  static var isAvailable: Bool {
    AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
  }

  @ObservationIgnored let previewLayer = AVCaptureVideoPreviewLayer()
  @ObservationIgnored private let session = AVCaptureSession()
  @ObservationIgnored private let output = AVCapturePhotoOutput()
  @ObservationIgnored private var pendingPhoto: CheckedContinuation<Data?, Never>?

  func start() async {
    guard await AVCaptureDevice.requestAccess(for: .video), !session.isRunning else { return }
    if session.inputs.isEmpty {
      configure()
    }
    // Apple suggests starting off the main thread, but the session isn't Sendable, so Swift 6
    // can't move it. It blocks briefly while the screen slides in. AVCam's capture actor is the fix.
    session.startRunning()
  }

  func stop() {
    session.stopRunning()
  }

  /// The photo, cropped to `rect` in the preview's coordinates.
  func capture(inside rect: CGRect) async -> UIImage? {
    guard session.isRunning, pendingPhoto == nil else { return nil }
    // AVFoundation maps the preview's rect into the photo, so the crop matches what was framed.
    let crop = previewLayer.metadataOutputRectConverted(fromLayerRect: rect)
    let data = await withCheckedContinuation { continuation in
      pendingPhoto = continuation
      output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    guard let data, let photo = UIImage(data: data) else { return nil }
    return photo.cropped(toNormalized: crop)
  }

  private func configure() {
    session.beginConfiguration()
    session.sessionPreset = .photo
    if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input), session.canAddOutput(output)
    {
      session.addInput(input)
      session.addOutput(output)
    }
    session.commitConfiguration()
    previewLayer.session = session
    previewLayer.videoGravity = .resizeAspectFill
    // Hutch is portrait only.
    for connection in [previewLayer.connection, output.connection(with: .video)] {
      if let connection, connection.isVideoRotationAngleSupported(90) {
        connection.videoRotationAngle = 90
      }
    }
  }

  private func finish(with data: Data?) {
    pendingPhoto?.resume(returning: data)
    pendingPhoto = nil
  }
}

extension Camera: AVCapturePhotoCaptureDelegate {
  nonisolated func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: (any Error)?
  ) {
    let data = photo.fileDataRepresentation()
    Task { @MainActor in finish(with: data) }
  }
}

/// Shows the camera's preview layer, filling the view.
struct CameraPreview: UIViewRepresentable {
  let camera: Camera

  func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    view.previewLayer = camera.previewLayer
    return view
  }

  func updateUIView(_ view: PreviewView, context: Context) {}

  final class PreviewView: UIView {
    var previewLayer: CALayer? {
      didSet {
        oldValue?.removeFromSuperlayer()
        if let previewLayer { layer.addSublayer(previewLayer) }
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      previewLayer?.frame = bounds
    }
  }
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

  /// `rect` is in 0–1 units of the stored pixels, before any rotation, as AVFoundation gives it.
  func cropped(toNormalized rect: CGRect) -> UIImage {
    guard let cgImage else { return self }
    let pixels = CGRect(
      x: rect.minX * CGFloat(cgImage.width),
      y: rect.minY * CGFloat(cgImage.height),
      width: rect.width * CGFloat(cgImage.width),
      height: rect.height * CGFloat(cgImage.height)
    ).integral
    guard let cropped = cgImage.cropping(to: pixels) else { return self }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }
}
