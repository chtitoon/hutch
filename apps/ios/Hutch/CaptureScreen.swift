import HutchCore
import PhotosUI
import SwiftUI

/// Adding an item: the camera, opened from Home's + (H1). Saving goes straight back to Home.
struct CaptureScreen: View {
    let library: Library
    var cameraAvailable = CameraView.isAvailable

    @Environment(\.dismiss) private var dismiss
    @State private var shutter = CameraShutter()
    @State private var capture: Capture?
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            if cameraAvailable {
                CameraView(shutter: shutter) { capture = Capture($0) }
                    .ignoresSafeArea()
                ViewfinderFrame(hint: "Fit the whole item inside the frame")
            } else {
                NoCamera()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.deep)
        .safeAreaInset(edge: .bottom) { bar }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(Typography.labelLg)
                    .frame(width: Spacing.s12, height: Spacing.s12)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Close")
            .padding(Spacing.s4)
        }
        .sheet(item: $capture) { capture in
            ConfirmScreen(capture: capture, library: library) { dismiss() }
                .brand()
        }
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    capture = Capture(image)
                }
            }
        }
    }

    /// Primary actions along the bottom, within one-handed reach.
    private var bar: some View {
        HStack {
            Color.clear.frame(width: Spacing.s14, height: Spacing.s14)

            Spacer()

            Button { shutter.fire() } label: {
                Circle()
                    .strokeBorder(Palette.onDeep, lineWidth: 4)
                    .background(Circle().fill(Palette.onDeep).padding(Spacing.s2))
                    .frame(width: Spacing.s20, height: Spacing.s20)
            }
            .disabled(!cameraAvailable)
            .accessibilityLabel("Take photo")

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
}

/// Four corners marking where the item goes, and a hint under them.
private struct ViewfinderFrame: View {
    let hint: String

    var body: some View {
        VStack(spacing: Spacing.s4) {
            Corners()
                .stroke(Palette.onDeep, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: Spacing.s30 * 2.2, height: Spacing.s30 * 2.2)
            Text(hint)
                .font(Typography.bodyMd)
                .foregroundStyle(Palette.onDeep)
                .shadow(color: Palette.device, radius: Spacing.s2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Corners: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = rect.width * 0.18
        var path = Path()
        for (corner, dx, dy) in [(CGPoint(x: rect.minX, y: rect.minY), 1.0, 1.0), (CGPoint(x: rect.maxX, y: rect.minY), -1.0, 1.0),
                                 (CGPoint(x: rect.maxX, y: rect.maxY), -1.0, -1.0), (CGPoint(x: rect.minX, y: rect.maxY), 1.0, -1.0)] {
            path.move(to: CGPoint(x: corner.x, y: corner.y + dy * arm))
            path.addLine(to: corner)
            path.addLine(to: CGPoint(x: corner.x + dx * arm, y: corner.y))
        }
        return path
    }
}

/// A photo just taken, waiting to become an item.
struct Capture: Identifiable {
    let id = UUID()
    let image: UIImage
    let takenAt = Date.now

    init(_ image: UIImage) { self.image = image }
}

/// Shown where the camera can't run (the simulator, or no permission).
private struct NoCamera: View {
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
