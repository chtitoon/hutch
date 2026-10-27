import HutchCore
import SwiftUI

struct AddItemScreen: View {
  let photo: UIImage
  // Called once saved, to go back to Home past the camera.
  var onSave: () -> Void = {}

  @Environment(Library.self) private var library
  @Environment(\.dismiss) private var dismiss
  @State private var draft: Draft
  @State private var cutout: UIImage?
  @State private var keepsBackground = false
  @State private var isSaving = false
  @State private var error: String?

  init(
    photo: UIImage,
    cutout: UIImage? = nil,
    draft: Draft = Draft(),
    onSave: @escaping () -> Void = {}
  ) {
    self.photo = photo
    self.onSave = onSave
    self._cutout = State(initialValue: cutout)
    self._draft = State(initialValue: draft)
  }

  // Saving with the cutout shown is what confirms it.
  private var shownPhoto: UIImage {
    keepsBackground ? photo : cutout ?? photo
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          Photo(image: shownPhoto)
            .overlay(alignment: .bottom) { cutoutButton }
          form.sheetStyle()
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .background(Palette.background)
      .safeAreaInset(edge: .bottom) { saveButton }
      .navigationTitle("New item")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Retake", role: .cancel) { dismiss() }
        }
      }
    }
    .interactiveDismissDisabled(isSaving)
    .onAppear { library.homeRooms.start() }
    .task { await liftItem() }
  }

  @ViewBuilder private var cutoutButton: some View {
    if cutout != nil {
      Button(
        keepsBackground ? "Remove background" : "Background removed · Undo",
        systemImage: keepsBackground ? "wand.and.sparkles" : "arrow.uturn.backward"
      ) {
        withAnimation { keepsBackground.toggle() }
      }
      .font(Typography.labelMd)
      .buttonStyle(.glass)
      // The photo's backdrop stays light in dark mode.
      .environment(\.colorScheme, .light)
      .padding(.bottom, Photo.sheetOverlap + Spacing.s3)
    }
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: Spacing.s6) {
      FormSection("What is it") {
        CardTextField("Name", text: $draft.name, prompt: "Cordless drill")
          .font(Typography.titleMd)
          .textInputAutocapitalization(.sentences)
          .submitLabel(.done)
      }
      FormSection("Where it lives") {
        // A room is typed only when there's none to pick (D25).
        if library.rooms.isEmpty {
          CardTextField("Room", text: $draft.room, prompt: "Garage")
        } else {
          ChipPicker(options: library.rooms, selection: $draft.room)
        }
      }
      if let error {
        Text(error)
          .foregroundStyle(Palette.ink)
      }
    }
  }

  private var saveButton: some View {
    Button(draft.room.trimmed.isEmpty ? "Save" : "Save to \(draft.room.trimmed)", action: save)
      .buttonStyle(.primary)
      .disabled(!draft.canSave || isSaving)
      .padding(.horizontal, Spacing.s5)
      .padding(.vertical, Spacing.s2)
      .background(Palette.background)
  }

  private func liftItem() async {
    guard cutout == nil,
      let image = photo.uprightImage(maxPixels: CGFloat(PhotoEncoder.photoMaxPixels))
    else { return }
    // Not worth an error: when Vision finds nothing, or can't run (the simulator), the photo stays.
    guard let lifted = try? await PhotoCutout.cutout(of: image) else { return }
    withAnimation { cutout = UIImage(cgImage: lifted) }
  }

  private func save() {
    isSaving = true
    Task {
      do {
        guard let image = shownPhoto.uprightImage(maxPixels: CGFloat(PhotoEncoder.photoMaxPixels))
        else {
          throw PhotoEncoderError.encodingFailed
        }
        try await library.add(draft.item, photo: image)
        dismiss()
        onSave()
      } catch {
        self.error = "Couldn't save: \(error.localizedDescription)"
        isSaving = false
      }
    }
  }
}

struct Draft: Equatable {
  var name = ""
  var room = ""

  var canSave: Bool {
    !name.trimmed.isEmpty
  }

  var item: Item {
    Item(name: name, room: room)
  }
}

private extension String {
  var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

#Preview("With rooms") {
  AddItemScreen(
    photo: .sample("wrench.and.screwdriver"),
    draft: Draft(name: "DeWalt 18V cordless drill", room: "Garage")
  )
  .environment(Library.sample)
  .brand()
}

#Preview("Background removed") {
  AddItemScreen(
    photo: .sample("wrench.and.screwdriver"),
    cutout: .sampleCutout("wrench.and.screwdriver"),
    draft: Draft(name: "DeWalt 18V cordless drill", room: "Garage")
  )
  .environment(Library.sample)
  .brand()
}

#Preview("No rooms yet") {
  AddItemScreen(photo: .sample("wrench.and.screwdriver"))
    .environment(Library(store: nil))
    .brand()
}
