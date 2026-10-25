import HutchCore
import SwiftUI

/// After the shutter: I name it and say where it lives.
struct AddScreen: View {
    let capture: Capture
    let library: Library
    /// Saved: back to Home, past the camera.
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var draft = Draft()
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ItemForm(photo: capture.image, draft: $draft, rooms: library.rooms, error: error, canSave: !saving, onSave: save)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Retake", role: .cancel) { dismiss() }
                    }
                }
                .navigationTitle("New item")
                .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(saving)
        .onAppear { library.homeRooms.start() }
    }

    private func save() {
        saving = true
        let item = Item(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            room: draft.room.trimmingCharacters(in: .whitespacesAndNewlines),
            spot: draft.spot.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        Task {
            do {
                guard let photo = capture.image.upright(maxPixels: CGFloat(PhotoEncoder.photoMaxPixels)) else { throw PhotoEncoderError.encodingFailed }
                try await library.add(item, photo: photo)
                dismiss()
                onSaved()
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
    var room = ""
    var spot = ""
}

/// The add form, free of any logic so snapshot tests can render it.
struct ItemForm: View {
    let photo: UIImage
    @Binding var draft: Draft
    /// Rooms I've used, then my Apple Home rooms.
    let rooms: [String]
    var error: String?
    var canSave = true
    let onSave: () -> Void

    @FocusState private var naming: Bool

    private var canSubmit: Bool { canSave && !draft.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.s30 * 2.5)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Field("What is it") {
                        TextBox("Name", text: $draft.name, prompt: "Cordless drill", font: Typography.titleMd)
                            .focused($naming)
                            .submitLabel(.done)
                    }

                    Field("Where it lives") {
                        // Typing a room is only for when there's none to pick: no Apple Home rooms, none used yet.
                        if rooms.isEmpty {
                            TextBox("Room", text: $draft.room, prompt: "Room: Garage")
                        } else {
                            Chips(options: rooms, selected: $draft.room)
                        }
                        TextBox("Spot", text: $draft.spot, prompt: "Spot, if you like: left shelf")
                    }

                    PrivateBadge()

                    if let error {
                        Text(error).foregroundStyle(Palette.ink)
                    }
                }
                .padding(.horizontal, Spacing.s5)
                .padding(.vertical, Spacing.s6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.background, in: UnevenRoundedRectangle(topLeadingRadius: Radius.lg, topTrailingRadius: Radius.lg))
                .padding(.top, -Spacing.s7)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background)
        .safeAreaInset(edge: .bottom) {
            Button(action: onSave) {
                Text(draft.room.trimmingCharacters(in: .whitespaces).isEmpty ? "Save" : "Save to \(draft.room)")
                    .font(Typography.labelLg)
                    .foregroundStyle(Palette.onDeep)
                    .frame(maxWidth: .infinity, minHeight: Spacing.s12)
                    .background(Palette.deep, in: .capsule)
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.4)
            .padding(.horizontal, Spacing.s5)
            .padding(.vertical, Spacing.s2)
            .background(Palette.background)
        }
    }
}

/// Options as one-tap chips, wrapping onto as many lines as they need. Tapping the selected
/// one again clears it.
private struct Chips: View {
    let options: [String]
    @Binding var selected: String

    var body: some View {
        FlowLayout(spacing: Spacing.s2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option.caseInsensitiveCompare(selected.trimmingCharacters(in: .whitespaces)) == .orderedSame
                // Selected: an ink pill (DESIGN.md's `pill` pair). Not: outlined.
                Button(option) { selected = isSelected ? "" : option }
                    .font(Typography.labelMd)
                    .padding(.horizontal, Spacing.s4)
                    .frame(minHeight: Spacing.s10)
                    .foregroundStyle(isSelected ? Palette.background : Palette.ink)
                    .background(isSelected ? Palette.ink : Color.clear, in: .capsule)
                    .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Palette.border))
                    .clipShape(.capsule)
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

/// Lays children out left to right, wrapping to a new line when the row is full.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

/// A section of the form: its eyebrow, then its fields.
private struct Field<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Eyebrow(title)
            content
        }
    }
}

/// A text field in a card, like the name's.
private struct TextBox: View {
    let label: String
    @Binding var text: String
    let prompt: String
    var font = Typography.bodyLg

    init(_ label: String, text: Binding<String>, prompt: String, font: Font = Typography.bodyLg) {
        self.label = label
        _text = text
        self.prompt = prompt
        self.font = font
    }

    var body: some View {
        TextField(label, text: $text, prompt: Text(prompt))
            .font(font)
            .padding(.horizontal, Spacing.s4)
            .frame(minHeight: Spacing.s12)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
            .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.border))
    }
}

/// Non-negotiable 2, said out loud, with Hutch's house-and-keyhole mark (never a padlock).
struct PrivateBadge: View {
    var text = "Private. Only you can see it."

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image("Mark")
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.s4, height: Spacing.s4)
                .foregroundStyle(Palette.sage)
        }
            .font(Typography.labelSm)
            .foregroundStyle(Palette.onSageTint)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .background(Palette.sageTint, in: .capsule)
    }
}
