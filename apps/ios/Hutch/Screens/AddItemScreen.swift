import HutchCore
import SwiftUI

struct AddItemScreen: View {
  let capture: Capture
  // Called once saved, to go back to Home past the camera.
  var onSave: () -> Void = {}

  @Environment(Library.self) private var library
  @Environment(\.dismiss) private var dismiss
  @State private var draft: Draft
  @State private var isSaving = false
  @State private var error: String?
  @State private var isCheckingCrop = false

  init(capture: Capture, draft: Draft = Draft(), onSave: @escaping () -> Void = {}) {
    self.capture = capture
    self.onSave = onSave
    self._draft = State(initialValue: draft)
  }

  private var photo: UIImage {
    capture.image
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          header
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
  }

  @ViewBuilder
  private var header: some View {
    #if DEBUG
      // Hold the photo to see the whole shot with the crop outlined.
      if isCheckingCrop, let check = capture.cropCheck {
        CropCheckView(check: check)
          .onLongPressGesture { isCheckingCrop = false }
      } else {
        Photo(image: photo)
          .onLongPressGesture { isCheckingCrop = true }
      }
    #else
      Photo(image: photo)
    #endif
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

  private func save() {
    isSaving = true
    Task {
      do {
        guard let image = photo.uprightImage(maxPixels: CGFloat(PhotoEncoder.photoMaxPixels)) else {
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
    capture: Capture(image: .sample("wrench.and.screwdriver")),
    draft: Draft(name: "DeWalt 18V cordless drill", room: "Garage")
  )
  .environment(Library.sample)
  .brand()
}

#Preview("No rooms yet") {
  AddItemScreen(capture: Capture(image: .sample("wrench.and.screwdriver")))
    .environment(Library(store: nil))
    .brand()
}
