import HutchCore
import SwiftUI

/// After the shutter: the phone suggests, I confirm, say where it lives and what I'd resell it for.
struct ConfirmScreen: View {
    let capture: Capture
    let library: Library

    @Environment(\.dismiss) private var dismiss
    @State private var draft = Draft()
    @State private var suggestion: Suggestion?
    @State private var suggestionSeconds: Double?
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ItemForm(
                photo: capture.image,
                draft: $draft,
                suggesting: suggestion == nil,
                places: library.places,
                currency: library.currency,
                error: error,
                canSave: !saving,
                onSave: save
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retake", role: .cancel) { dismiss() }
                }
            }
            .navigationTitle("New item")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(saving)
        .task { await suggest() }
    }

    private func suggest() async {
        guard let image = capture.image.upright(maxPixels: 1024) else {
            suggestion = .empty
            return
        }
        let result = await library.suggester.suggest(for: image, currency: library.currency)
        suggestionSeconds = Date.now.timeIntervalSince(capture.takenAt)
        suggestion = result
        // Fill only what I haven't typed myself.
        if draft.name.isEmpty { draft.name = result.name }
        if draft.category.isEmpty { draft.category = result.category }
        if draft.price == nil { draft.price = result.resaleEstimate }
    }

    private func save() {
        saving = true
        let source = suggestion?.source ?? .none
        let item = Item(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category.trimmingCharacters(in: .whitespacesAndNewlines),
            place: draft.place.trimmingCharacters(in: .whitespacesAndNewlines),
            resalePrice: draft.price,
            currency: library.currency,
            capture: CaptureRecord(
                seconds: Date.now.timeIntervalSince(capture.takenAt),
                suggestionSeconds: suggestionSeconds,
                suggestionSource: source,
                keptSuggestedName: source != .none && draft.name == suggestion?.name
            )
        )
        Task {
            do {
                guard let photo = capture.image.upright(maxPixels: CGFloat(PhotoEncoder.photoMaxPixels)) else { throw PhotoEncoderError.encodingFailed }
                try await library.add(item, photo: photo)
                dismiss()
            } catch {
                self.error = "Couldn't save: \(error.localizedDescription)"
                saving = false
            }
        }
    }
}

/// What I'm about to save.
struct Draft: Equatable {
    var name = ""
    var category = ""
    var place = ""
    var price: Decimal?
}

/// The confirm form, free of any logic so snapshot tests can render each state.
struct ItemForm: View {
    let photo: UIImage
    @Binding var draft: Draft
    let suggesting: Bool
    let places: [String]
    let currency: String
    var error: String?
    var canSave = true
    let onSave: () -> Void

    var body: some View {
        Form {
            Section {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.s30 * 2)
                    .clipped()
                    .listRowInsets(EdgeInsets())
            }

            Section {
                HStack {
                    TextField("Name", text: $draft.name, prompt: Text(suggesting ? "Looking at your photo…" : "What is it?"))
                        .font(Typography.titleMd)
                    if suggesting && draft.name.isEmpty {
                        ProgressView()
                    }
                }
                TextField("Category", text: $draft.category, prompt: Text("Category"))
            }
            .listRowBackground(Palette.surface)

            Section("Where it lives") {
                TextField("Place", text: $draft.place, prompt: Text("Garage, left shelf"))
                if !places.isEmpty {
                    PlaceChips(places: places, selected: $draft.place)
                        .listRowInsets(EdgeInsets(top: Spacing.s2, leading: Spacing.s4, bottom: Spacing.s2, trailing: Spacing.s4))
                }
            }
            .listRowBackground(Palette.surface)

            Section {
                TextField("Resale price", value: $draft.price, format: .currency(code: currency), prompt: Text("What you'd sell it for"))
                    .keyboardType(.decimalPad)
            } header: {
                Text("I'd resell it for")
            } footer: {
                Text("Your own estimate. Any suggestion comes from this iPhone; nothing about this item leaves it.")
            }
            .listRowBackground(Palette.surface)

            Section {
                PrivateBadge()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            if let error {
                Text(error).foregroundStyle(Palette.ink)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .safeAreaInset(edge: .bottom) {
            Button(action: onSave) {
                Text("Save")
                    .font(Typography.labelLg)
                    .frame(maxWidth: .infinity, minHeight: Spacing.s12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Palette.ink)
            .foregroundStyle(Palette.background)
            .disabled(!canSave || draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s2)
            .background(Palette.background)
        }
    }
}

/// Places I've used before, most recent first: one tap instead of typing.
private struct PlaceChips: View {
    let places: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(places, id: \.self) { place in
                    let isSelected = place.caseInsensitiveCompare(selected.trimmingCharacters(in: .whitespaces)) == .orderedSame
                    Button(place) { selected = place }
                        .font(Typography.labelSm)
                        .padding(.horizontal, Spacing.s3)
                        .padding(.vertical, Spacing.s2)
                        .foregroundStyle(isSelected ? Palette.onSageTint : Palette.ink)
                        .background(isSelected ? Palette.sageTint : Palette.surfaceSunken, in: .capsule)
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Non-negotiable 2, said out loud.
struct PrivateBadge: View {
    var body: some View {
        Label("Private. Only you can see it.", systemImage: "house")
            .font(Typography.labelSm)
            .foregroundStyle(Palette.onSageTint)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .background(Palette.sageTint, in: .capsule)
    }
}
