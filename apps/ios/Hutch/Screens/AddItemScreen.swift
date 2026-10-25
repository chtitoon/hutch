import HutchCore
import SwiftUI

struct AddItemScreen: View {
  let photo: UIImage
  // Called once saved, to go back to Home past the camera.
  var onSave: () -> Void = {}

  @Environment(Library.self) private var library
  @Environment(\.dismiss) private var dismiss
  @State private var draft: Draft
  @State private var isSaving = false
  @State private var error: String?

  init(photo: UIImage, draft: Draft = Draft(), onSave: @escaping () -> Void = {}) {
    self.photo = photo
    self.onSave = onSave
    self._draft = State(initialValue: draft)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          Photo(image: photo)
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

  private var form: some View {
    VStack(alignment: .leading, spacing: Spacing.s6) {
      FormSection("What is it") {
        CardTextField("Name", text: $draft.name, prompt: "Cordless drill")
          .font(Typography.titleMd)
          .submitLabel(.done)
      }
      FormSection("Where it lives") {
        // A room is typed only when there's none to pick (D25).
        if library.rooms.isEmpty {
          CardTextField("Room", text: $draft.room, prompt: "Room: Garage")
        } else {
          ChipPicker(options: library.rooms, selection: $draft.room)
        }
        CardTextField("Spot", text: $draft.spot, prompt: "Spot, if you like: left shelf")
      }
      PrivateBadge()
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
  var spot = ""

  var canSave: Bool {
    !name.trimmed.isEmpty
  }

  var item: Item {
    Item(name: name.trimmed, room: room.trimmed, spot: spot.trimmed)
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

#Preview("No rooms yet") {
  AddItemScreen(photo: .sample("wrench.and.screwdriver"))
    .environment(Library(store: nil))
    .brand()
}
