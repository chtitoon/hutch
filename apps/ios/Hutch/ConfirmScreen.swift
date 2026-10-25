import HutchCore
import SwiftUI

/// After the shutter: the phone suggests a name, I confirm it and say where it lives.
struct ConfirmScreen: View {
    let capture: Capture
    let library: Library
    /// Saved: back to Home, past the camera.
    var onSaved: () -> Void = {}

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
                suggestionNote: suggestion.flatMap(Self.note(for:)),
                alternatives: suggestion?.alternatives ?? [],
                aspects: suggestion?.aspects ?? [],
                rooms: library.rooms,
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
        .onAppear { library.homeRooms.start() }
        .task { await suggest() }
    }

    private func suggest() async {
        guard let image = capture.image.upright(maxPixels: 1024) else {
            suggestion = .empty
            return
        }
        let result = await library.suggester.suggest(for: image)
        suggestionSeconds = Date.now.timeIntervalSince(capture.takenAt)
        suggestion = result
        // Fill only what I haven't typed or picked myself. The category isn't shown, but is kept.
        if draft.name.isEmpty { draft.name = result.name }
        draft.category = result.category
        for aspect in result.aspects where !aspect.value.isEmpty && draft.values[aspect.name] == nil {
            draft.values[aspect.name] = aspect.value
        }
    }

    /// Which path named it, so a poor guess can be told apart from a model that never ran (X4).
    static func note(for suggestion: Suggestion) -> String? {
        switch suggestion.source {
        case .catalog:
            [
                "Matched on this iPhone against Hutch's catalog\(suggestion.catalogScore.map { ", \(Int(($0 * 100).rounded()))% sure" } ?? "").",
                suggestion.fallbackReason,
            ].compactMap(\.self).joined(separator: " ")
        case .modelWithImage: "Named by Apple Intelligence on this iPhone, from the photo."
        case .modelWithLabels: "Named by Apple Intelligence on this iPhone, from Vision's labels."
        case .labelsOnly: [suggestion.fallbackReason, "This is Vision's rough label."].compactMap(\.self).joined(separator: " ")
        case .none: suggestion.fallbackReason
        }
    }

    private func save() {
        saving = true
        let source = suggestion?.source ?? .none
        let item = Item(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            room: draft.room.trimmingCharacters(in: .whitespacesAndNewlines),
            spot: draft.spot.trimmingCharacters(in: .whitespacesAndNewlines),
            aspects: draft.aspects(for: suggestion?.aspects ?? []),
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
    var category = ""
    var room = ""
    var spot = ""
    /// The value of each aspect, by its name: read off the photo, or picked.
    var values: [String: String] = [:]

    /// The aspects with a value, in the order suggested.
    func aspects(for suggested: [SuggestedAspect]) -> [Aspect] {
        suggested.compactMap { aspect in
            values[aspect.name].map { Aspect(name: aspect.name, value: $0) }
        }
    }
}

/// The confirm form, free of any logic so snapshot tests can render each state.
struct ItemForm: View {
    let photo: UIImage
    @Binding var draft: Draft
    let suggesting: Bool
    var suggestionNote: String?
    /// Other likely names from the catalog: one tap makes one the name.
    var alternatives: [String] = []
    /// Its aspects: values the photo showed are already picked; the rest take a tap, or none.
    var aspects: [SuggestedAspect] = []
    /// Rooms I've used, then my Apple Home rooms.
    let rooms: [String]
    var error: String?
    var canSave = true
    let onSave: () -> Void

    /// Picked aspects I've tapped to change, shown with their choices again.
    @State private var editing: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // The photo, on forest like the camera it came from, with the scanner over it.
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.s30 * 2.5)
                    .clipped()
                    .overlay {
                        if suggesting {
                            ScanOverlay().transition(.opacity)
                        }
                    }
                    .animation(.easeOut, value: suggesting)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Field("What is it") {
                        HStack {
                            TextField("Name", text: $draft.name, prompt: Text(suggesting ? "Looking at your photo…" : "What is it?"), axis: .vertical)
                                .font(Typography.titleMd)
                            if suggesting && draft.name.isEmpty {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                        .frame(minHeight: Spacing.s12)
                        .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.border))

                        if !alternatives.isEmpty {
                            Text("Or is it…")
                                .font(Typography.labelSm)
                                .foregroundStyle(Palette.inkSubtle)
                                .padding(.top, Spacing.s2)
                            Chips(options: alternatives, selected: Binding(
                                get: { draft.name },
                                set: { if !$0.isEmpty { draft.name = $0 } }
                            ))
                        }
                        if let suggestionNote {
                            Text(suggestionNote).modifier(Footnote())
                        }
                    }

                    if !aspects.isEmpty {
                        Field("About it") {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(aspects.enumerated()), id: \.element) { index, aspect in
                                    aspectRow(aspect)
                                        .padding(.horizontal, Spacing.s4)
                                        .padding(.vertical, Spacing.s3)
                                    if index < aspects.count - 1 {
                                        Divider().overlay(Palette.border).padding(.leading, Spacing.s4)
                                    }
                                }
                            }
                            .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
                        }
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

                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        PrivateBadge()
                        Text("The name is suggested on this iPhone. Nothing about this item leaves it.").modifier(Footnote())
                    }

                    if let error {
                        Text(error).foregroundStyle(Palette.ink)
                    }
                }
                .padding(.horizontal, Spacing.s5)
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s6)
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
            .disabled(!canSave || draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(!canSave || draft.name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            .padding(.horizontal, Spacing.s5)
            .padding(.vertical, Spacing.s2)
            .background(Palette.background)
        }
    }

    /// Picked: one line, "Color   Silver", tap to change. Otherwise its choices, or a field.
    @ViewBuilder private func aspectRow(_ aspect: SuggestedAspect) -> some View {
        let current = draft.values[aspect.name] ?? ""
        if !current.isEmpty && !editing.contains(aspect.name) {
            Button { editing.insert(aspect.name) } label: {
                HStack {
                    Text(aspect.name).foregroundStyle(Palette.inkMuted)
                    Spacer()
                    Text(current).foregroundStyle(Palette.ink)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Change")
        } else {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(aspect.name)
                    .font(Typography.labelSm)
                    .foregroundStyle(Palette.inkMuted)
                if aspect.choices.count > 1 {
                    Chips(options: aspect.choices, selected: value(of: aspect))
                } else {
                    TextField(aspect.name, text: value(of: aspect))
                        .onSubmit { editing.remove(aspect.name) }
                }
            }
        }
    }

    /// One aspect's value as a chip selection or text; "" is no value. Picking a chip folds
    /// the aspect back into one line.
    private func value(of aspect: SuggestedAspect) -> Binding<String> {
        Binding(
            get: { draft.values[aspect.name] ?? "" },
            set: { newValue in
                draft.values[aspect.name] = newValue.isEmpty ? nil : newValue
                if !newValue.isEmpty && aspect.choices.count > 1 { editing.remove(aspect.name) }
            }
        )
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

/// A section's footer: `caption` in `ink-subtle`, as captions are in DESIGN.md.
struct Footnote: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.caption)
            .foregroundStyle(Palette.inkSubtle)
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

    init(_ label: String, text: Binding<String>, prompt: String) {
        self.label = label
        _text = text
        self.prompt = prompt
    }

    var body: some View {
        TextField(label, text: $text, prompt: Text(prompt))
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
