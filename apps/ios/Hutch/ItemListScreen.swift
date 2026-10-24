import HutchCore
import SwiftUI

/// Everything I've added: photo, name and place.
struct ItemListScreen: View {
    let library: Library
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ItemList(items: library.items, thumbnails: library.thumbnails, stats: library.stats) { id in
                Task { await library.delete(id) }
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// The list itself, free of any logic so snapshot tests can render it.
struct ItemList: View {
    let items: [Item]
    let thumbnails: [UUID: UIImage]
    let stats: CaptureStats
    var onDelete: (UUID) -> Void = { _ in }

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label("Nothing yet", systemImage: "house")
            } description: {
                Text("Take a photo of something you own. It stays private, on this iPhone.")
            }
            .background(Palette.background)
        } else {
            List {
                Section {
                    ForEach(items) { item in
                        ItemRow(item: item, thumbnail: thumbnails[item.id])
                            .listRowBackground(Palette.surface)
                    }
                    .onDelete { offsets in offsets.forEach { onDelete(items[$0].id) } }
                } footer: {
                    StatsFooter(stats: stats)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
        }
    }
}

struct ItemRow: View {
    let item: Item
    let thumbnail: UIImage?

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail).resizable().scaledToFill()
                } else {
                    Palette.surfaceSunken
                }
            }
            .frame(width: Spacing.s14, height: Spacing.s14)
            .clipShape(.rect(cornerRadius: Radius.sm))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s2 / 2) {
                Text(item.name)
                    .font(Typography.labelLg)
                    .foregroundStyle(Palette.ink)
                if !item.aspects.isEmpty {
                    Text(item.aspects.map(\.value).joined(separator: " · "))
                        .font(Typography.bodySm)
                        .foregroundStyle(Palette.ink)
                }
                Text(item.place.isEmpty ? "No place yet" : item.place)
                    .font(Typography.bodySm)
                    .foregroundStyle(Palette.inkMuted)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// H1's and X4's signals, counted here on the phone and never sent.
private struct StatsFooter: View {
    let stats: CaptureStats

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2 / 2) {
            Text("^[\(stats.itemCount) item](inflect: true)")
            if let median = stats.medianSeconds {
                Text("Median \(median, format: .number.precision(.fractionLength(0))) s to add · \(stats.underTargetCount) of \(stats.timedCount) under \(Int(CaptureStats.targetSeconds)) s")
            }
            if stats.suggestedCount > 0 {
                Text("Kept the suggested name \(stats.keptSuggestionCount) of \(stats.suggestedCount) times")
            }
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.inkSubtle)
        .padding(.top, Spacing.s2)
    }
}
