import SwiftUI
import Testing

@testable import Hutch

/// The capture screen in a real window, with the safe areas a phone has, so the crop is measured
/// against what the camera preview really covers.
@MainActor
@Suite struct CaptureLayoutTests {
  @Test func cropsToTheViewfinderMeasuredOnTheFullScreen() async throws {
    let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
    let window = UIWindow(windowScene: scene)
    let camera = Camera()
    let screen = CaptureScreen(camera: camera, isCameraAvailable: true)
      .environment(Library.sample)
      .brand()
    window.rootViewController = UIHostingController(rootView: screen)
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    for _ in 0..<40 where camera.viewfinderFrame.isEmpty {
      try await Task.sleep(for: .milliseconds(50))
    }

    // The bug: the preview was measured inside the status and shutter bars, not the full screen.
    #expect(window.safeAreaInsets.top > 0)
    #expect(camera.previewFrame == window.bounds)

    // A 3:4 photo on a taller screen fills its height; the square frame is centered across.
    let photo = CGSize(width: 3024, height: 4032)
    let scale = window.bounds.height / photo.height
    let crop = try #require(camera.crop(ofPhoto: photo))
    #expect(abs(crop.width - camera.viewfinderFrame.width / scale) <= 1)
    #expect(abs(crop.width - crop.height) <= 1)
    #expect(abs(crop.midX - photo.width / 2) <= 1)
    #expect(abs(crop.midY - camera.viewfinderFrame.midY / scale) <= 1)
  }
}
