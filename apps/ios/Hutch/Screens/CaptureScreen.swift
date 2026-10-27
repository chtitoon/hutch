import HutchCore
import PhotosUI
import SwiftUI

struct CaptureScreen: View {
  let isCameraAvailable: Bool

  @Environment(\.dismiss) private var dismiss
  @State private var camera: Camera
  @State private var capture: Capture?
  @State private var pickedPhoto: PhotosPickerItem?
  @State private var zoomAtPinchStart: CGFloat = 1

  init(camera: Camera = Camera(), isCameraAvailable: Bool = Camera.isAvailable) {
    self._camera = State(initialValue: camera)
    self.isCameraAvailable = isCameraAvailable
  }

  var body: some View {
    ZStack {
      if isCameraAvailable {
        CameraPreview(camera: camera)
          .ignoresSafeArea()
          .gesture(pinchToZoom)
        Viewfinder { camera.viewfinderFrame = $0 }
      } else {
        NoCameraView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.deep)
    .overlay(alignment: .topLeading) { closeButton }
    .safeAreaInset(edge: .bottom) { controls }
    .sheet(item: $capture) { capture in
      AddItemScreen(photo: capture.image) { dismiss() }
        .brand()
    }
    .task(id: pickedPhoto) { await loadPickedPhoto() }
    .task {
      guard isCameraAvailable else { return }
      await camera.start()
    }
    .onDisappear { camera.stop() }
  }

  private var closeButton: some View {
    Button("Close", systemImage: "xmark") { dismiss() }
      .labelStyle(.iconOnly)
      .font(Typography.labelLg)
      .frame(width: Spacing.s12, height: Spacing.s12)
      .buttonStyle(.glass)
      .padding(Spacing.s4)
  }

  private var controls: some View {
    HStack {
      Spacer()
        .frame(width: Spacing.s14)
      Spacer()
      Button("Take photo", action: takePhoto)
        .buttonStyle(ShutterButtonStyle())
        .disabled(!isCameraAvailable)
      Spacer()
      PhotosPicker(selection: $pickedPhoto, matching: .images) {
        Label("Choose a photo", systemImage: "photo.on.rectangle")
          .labelStyle(.iconOnly)
          .font(Typography.titleMd)
          .frame(width: Spacing.s14, height: Spacing.s14)
      }
      .buttonStyle(.glass)
    }
    .padding(.horizontal, Spacing.s6)
    .padding(.bottom, Spacing.s4)
  }

  private var pinchToZoom: some Gesture {
    MagnifyGesture()
      .onChanged { camera.setZoom(zoomAtPinchStart * $0.magnification) }
      .onEnded { _ in zoomAtPinchStart = camera.zoom }
  }

  private func takePhoto() {
    Task {
      if let photo = await camera.capture() {
        capture = crop(photo)
      }
    }
  }

  // Only what was inside the frame: the hint asks for the item there, so the rest is clutter.
  private func crop(_ photo: UIImage) -> Capture {
    // Twice the stored size, so the crop keeps the stored photo's full detail.
    let maxPixels = CGFloat(PhotoEncoder.photoMaxPixels) * 2
    guard let upright = photo.uprightImage(maxPixels: maxPixels),
      let rect = camera.crop(ofPhoto: CGSize(width: upright.width, height: upright.height)),
      let cropped = upright.cropping(to: rect)
    else { return Capture(image: photo) }
    return Capture(image: UIImage(cgImage: cropped))
  }

  private func loadPickedPhoto() async {
    guard let pickedPhoto else { return }
    defer { self.pickedPhoto = nil }
    if let data = try? await pickedPhoto.loadTransferable(type: Data.self),
      let image = UIImage(data: data)
    {
      capture = Capture(image: image)
    }
  }
}

struct Capture: Identifiable {
  let id = UUID()
  let image: UIImage
}

private struct ShutterButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Circle()
      .strokeBorder(Palette.onDeep, lineWidth: 4)
      .background(Circle().fill(Palette.onDeep).padding(Spacing.s2))
      .frame(width: Spacing.s20, height: Spacing.s20)
      .scaleEffect(configuration.isPressed ? 0.94 : 1)
      .accessibilityLabel(Text("Take photo"))
  }
}

struct Viewfinder: View {
  // Where the frame sits on screen, so the photo can be cropped to it.
  var onFrameChange: (CGRect) -> Void = { _ in }

  var body: some View {
    VStack(spacing: Spacing.s6) {
      ViewfinderCorners()
        .stroke(Palette.onDeep, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .aspectRatio(1, contentMode: .fit)
        .onGeometryChange(for: CGRect.self) {
          $0.frame(in: .global)
        } action: {
          onFrameChange($0)
        }
        .padding(.horizontal, Spacing.s8)
      // A capsule keeps the hint readable over any scene the camera sees.
      Text("Fit the whole item in the frame")
        .font(Typography.titleMd)
        .foregroundStyle(Palette.onDeep)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.s5)
        .padding(.vertical, Spacing.s3)
        .background(.ultraThinMaterial, in: .capsule)
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, Spacing.s6)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

private struct ViewfinderCorners: Shape {
  func path(in rect: CGRect) -> Path {
    let arm = rect.width * 0.18
    var path = Path()
    path.addLines([
      CGPoint(x: rect.minX, y: rect.minY + arm), CGPoint(x: rect.minX, y: rect.minY),
      CGPoint(x: rect.minX + arm, y: rect.minY),
    ])
    path.addLines([
      CGPoint(x: rect.maxX - arm, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
      CGPoint(x: rect.maxX, y: rect.minY + arm),
    ])
    path.addLines([
      CGPoint(x: rect.maxX, y: rect.maxY - arm), CGPoint(x: rect.maxX, y: rect.maxY),
      CGPoint(x: rect.maxX - arm, y: rect.maxY),
    ])
    path.addLines([
      CGPoint(x: rect.minX + arm, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
      CGPoint(x: rect.minX, y: rect.maxY - arm),
    ])
    return path
  }
}

private struct NoCameraView: View {
  var body: some View {
    ContentUnavailableView {
      Label("No camera here", systemImage: "camera")
        .font(Typography.headlineMd)
        .foregroundStyle(Palette.onDeep)
    } description: {
      Text("Choose a photo instead. It stays on this iPhone, encrypted.")
        .font(Typography.bodyMd)
        .foregroundStyle(Palette.onDeepMuted)
    }
  }
}

#Preview {
  CaptureScreen(isCameraAvailable: false)
    .brand()
}
