import HutchCore
import SwiftUI

/// After the shutter: the phone suggests a name, I confirm it and say where it lives.
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
                suggestionNote: suggestion.flatMap(Self.note(for:)),
                questions: suggestion?.questions ?? [],
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
        // Fill only what I haven't typed myself. The category isn't shown, but is kept.
        if draft.name.isEmpty { draft.name = result.name }
        draft.category = result.category
    }

    /// Which path named it, so a poor guess can be told apart from a model that never ran (X4).
    static func note(for suggestion: Suggestion) -> String? {
        switch suggestion.source {
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
            details: draft.details(for: suggestion?.questions ?? []),
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
    var room = ""
    var spot = ""
    /// My answer to each narrowing question, by its label.
    var answers: [String: String] = [:]

    /// The answered questions, in the order they were asked.
    func details(for questions: [Question]) -> [Detail] {
        questions.compactMap { question in
            answers[question.label].map { Detail(question: question.label, answer: $0) }
        }
    }
}

/// The confirm form, free of any logic so snapshot tests can render each state.
struct ItemForm: View {
    let photo: UIImage
    @Binding var draft: Draft
    let suggesting: Bool
    var suggestionNote: String?
    /// One-tap questions to narrow it down; skipping one is fine.
    var questions: [Question] = []
    /// Rooms I've used, then my Apple Home rooms.
    let rooms: [String]
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
                    TextField("Name", text: $draft.name, prompt: Text(suggesting ? "Looking at your photo…" : "What is it?"), axis: .vertical)
                        .font(Typography.titleMd)
                    if suggesting && draft.name.isEmpty {
                        ProgressView()
                    }
                }
            } footer: {
                if let suggestionNote {
                    Text(suggestionNote)
                }
            }
            .listRowBackground(Palette.surface)

            ForEach(questions, id: \.self) { question in
                Section(question.label) {
                    Chips(options: question.choices, selected: answer(to: question))
                        .listRowInsets(EdgeInsets(top: Spacing.s2, leading: Spacing.s4, bottom: Spacing.s2, trailing: Spacing.s4))
                }
                .listRowBackground(Palette.surface)
            }

            Section("Where it lives") {
                // Typing a room is only for when there's none to pick: no Apple Home rooms, none used yet.
                if rooms.isEmpty {
                    TextField("Room", text: $draft.room, prompt: Text("Room: Garage"))
                } else {
                    Chips(options: rooms, selected: $draft.room)
                        .listRowInsets(EdgeInsets(top: Spacing.s2, leading: Spacing.s4, bottom: Spacing.s2, trailing: Spacing.s4))
                }
                TextField("Spot", text: $draft.spot, prompt: Text("Spot, if you like: left shelf"))
            }
            .listRowBackground(Palette.surface)

            Section {
                PrivateBadge()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } footer: {
                Text("The name is suggested on this iPhone. Nothing about this item leaves it.")
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

    /// The answer to one question as a chip selection; "" is no answer.
    private func answer(to question: Question) -> Binding<String> {
        Binding(
            get: { draft.answers[question.label] ?? "" },
            set: { draft.answers[question.label] = $0.isEmpty ? nil : $0 }
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
                Button(option) { selected = isSelected ? "" : option }
                    .font(Typography.labelSm)
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s2)
                    .foregroundStyle(isSelected ? Palette.onSageTint : Palette.ink)
                    .background(isSelected ? Palette.sageTint : Palette.surfaceSunken, in: .capsule)
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
