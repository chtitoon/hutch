import HutchCore
import PhotosUI
import SwiftUI

/// Where Hutch opens: the camera, one tap from an item (H1).
struct CaptureScreen: View {
    let library: Library
    var cameraAvailable = CameraView.isAvailable

    @State private var shutter = CameraShutter()
    @State private var capture: Capture?
    @State private var showingItems = false
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            if cameraAvailable {
                CameraView(shutter: shutter) { capture = Capture($0) }
                    .ignoresSafeArea()
            } else {
                NoCamera()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.deep)
        .safeAreaInset(edge: .bottom) { bar }
        .overlay(alignment: .top) {
            if let error = library.error {
                Text(error)
                    .font(Typography.bodySm)
                    .foregroundStyle(Palette.ink)
                    .padding(Spacing.s3)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
                    .padding(Spacing.s4)
            }
        }
        .sheet(item: $capture) { capture in
            ConfirmScreen(capture: capture, library: library)
        }
        .sheet(isPresented: $showingItems) {
            ItemListScreen(library: library)
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
            Button { showingItems = true } label: {
                Label("Items", systemImage: "square.grid.2x2")
                    .labelStyle(.iconOnly)
                    .font(Typography.titleMd)
                    .frame(width: Spacing.s14, height: Spacing.s14)
                    .overlay(alignment: .topTrailing) {
                        if !library.items.isEmpty {
                            Text(library.items.count, format: .number)
                                .font(Typography.labelSm)
                                .foregroundStyle(Palette.background)
                                .padding(.horizontal, Spacing.s2)
                                .background(Palette.ink, in: .capsule)
                        }
                    }
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Items, \(library.items.count)")

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
