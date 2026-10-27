import AVFoundation
import HutchCore
import SwiftUI
import UIKit

/// The back camera, with a preview that fills its view and pinch-to-zoom like the Camera app.
@MainActor
@Observable
final class Camera: NSObject {
  static var isAvailable: Bool {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypes,
      mediaType: .video,
      position: .back
    ).devices.first != nil
  }

  // Lenses Hutch can use, best first. A multi-lens camera reaches 0.5× and switches lenses as it
  // zooms, like the Camera app.
  private static let deviceTypes: [AVCaptureDevice.DeviceType] = [
    .builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera,
  ]
  private static let maxZoom: CGFloat = 10

  /// As the Camera app shows it: 1 is the main lens, 0.5 the ultra wide.
  private(set) var zoom: CGFloat = 1
  @ObservationIgnored let previewLayer = AVCaptureVideoPreviewLayer()
  /// Where the viewfinder's square sits, in window coordinates. Photos are cropped to it.
  @ObservationIgnored var viewfinderFrame = CGRect.zero
  @ObservationIgnored fileprivate weak var previewView: UIView?
  @ObservationIgnored private let session = AVCaptureSession()
  @ObservationIgnored private let output = AVCapturePhotoOutput()
  @ObservationIgnored private var device: AVCaptureDevice?
  // The device's zoom factor at which the main lens takes over: 2 on a camera with an ultra wide.
  @ObservationIgnored private var mainLensFactor: CGFloat = 1
  @ObservationIgnored private var pendingPhoto: CheckedContinuation<Data?, Never>?

  func start() async {
    // No camera, no permission prompt: the simulator, and tests.
    guard Self.isAvailable, await AVCaptureDevice.requestAccess(for: .video), !session.isRunning
    else { return }
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

  /// Where the preview is drawn, in window coordinates (SwiftUI's `.global`). Asked of UIKit:
  /// SwiftUI reports a view's frame inside the safe area, even when it draws past it.
  var previewFrame: CGRect {
    guard let previewView else { return .zero }
    return previewView.convert(previewView.bounds, to: nil)
  }

  /// The part of an upright photo of `size` that was inside the viewfinder, or nil before it's
  /// laid out.
  func crop(ofPhoto size: CGSize) -> CGRect? {
    let preview = previewFrame
    guard !viewfinderFrame.isEmpty, !preview.isEmpty else { return nil }
    let frame = viewfinderFrame.offsetBy(dx: -preview.minX, dy: -preview.minY)
    return PhotoCrop.rect(inside: frame, screen: preview.size, photo: size)
  }

  func setZoom(_ value: CGFloat) {
    guard let device else { return }
    let factor = min(
      max(value * mainLensFactor, device.minAvailableVideoZoomFactor),
      min(device.maxAvailableVideoZoomFactor, Self.maxZoom * mainLensFactor)
    )
    do {
      try device.lockForConfiguration()
    } catch {
      return  // A missed zoom step isn't worth an alert; the next pinch tries again.
    }
    device.videoZoomFactor = factor
    device.unlockForConfiguration()
    zoom = factor / mainLensFactor
  }

  /// The whole photo, upright. The preview shows the same field of view, so a part of the
  /// preview maps onto it with ``PhotoCrop``.
  func capture() async -> UIImage? {
    guard session.isRunning, pendingPhoto == nil else { return nil }
    let data = await withCheckedContinuation { continuation in
      pendingPhoto = continuation
      output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    return data.flatMap(UIImage.init(data:))
  }

  private func configure() {
    let device = AVCaptureDevice.DiscoverySession(
      deviceTypes: Self.deviceTypes,
      mediaType: .video,
      position: .back
    ).devices.first
    session.beginConfiguration()
    session.sessionPreset = .photo
    if let device, let input = try? AVCaptureDeviceInput(device: device),
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
    self.device = device
    mainLensFactor =
      device?.virtualDeviceSwitchOverVideoZoomFactors.first.map { CGFloat(truncating: $0) } ?? 1
    setZoom(1)
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
    camera.previewView = view
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
    // A cutout keeps its transparent background.
    format.opaque = !(cgImage?.hasAlpha ?? false)
    let target = CGSize(
      width: (size.width * scale * factor).rounded(),
      height: (size.height * scale * factor).rounded()
    )
    return UIGraphicsImageRenderer(size: target, format: format).image { _ in
      draw(in: CGRect(origin: .zero, size: target))
    }.cgImage
  }
}
