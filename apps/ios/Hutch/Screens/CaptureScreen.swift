import PhotosUI
import SwiftUI

struct CaptureScreen: View {
  var isCameraAvailable = CameraView.isAvailable

  @Environment(\.dismiss) private var dismiss
  @State private var shutter = CameraShutter()
  @State private var capture: Capture?
  @State private var pickedPhoto: PhotosPickerItem?

  var body: some View {
    ZStack {
      if isCameraAvailable {
        CameraView(shutter: shutter) { capture = Capture(image: $0) }
          .ignoresSafeArea()
        Viewfinder()
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
      Button("Take photo") { shutter.fire() }
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

private struct Viewfinder: View {
  private static let size = Spacing.s30 * 2.2

  var body: some View {
    VStack(spacing: Spacing.s4) {
      ViewfinderCorners()
        .stroke(Palette.onDeep, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: Self.size, height: Self.size)
      Text("Fit the whole item inside the frame")
        .font(Typography.bodyMd)
        .foregroundStyle(Palette.onDeep)
        .shadow(color: Palette.device, radius: Spacing.s2)
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
