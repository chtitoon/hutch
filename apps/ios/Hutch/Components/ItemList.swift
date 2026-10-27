import HutchCore
import SwiftUI

struct ItemList: View {
  let title: String
  let items: [Item]
  // Off in a room's own list, where it would repeat the title.
  var showsRoom = true

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.s3) {
      Eyebrow(title)
      VStack(spacing: 0) {
        ForEach(items) { item in
          NavigationLink(value: Route.item(item)) {
            ItemRow(item: item, showsRoom: showsRoom)
          }
          .buttonStyle(.plain)
          if item.id != items.last?.id {
            Divider()
              .overlay(Palette.border)
              .padding(.leading, ItemRow.textInset)
          }
        }
      }
      .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
    }
  }
}

struct ItemRow: View {
  let item: Item
  var showsRoom = true

  @Environment(Library.self) private var library

  static let textInset = Spacing.s4 + thumbnailSize + Spacing.s3
  private static let thumbnailSize = Spacing.s12

  var body: some View {
    HStack(spacing: Spacing.s3) {
      thumbnail
      VStack(alignment: .leading, spacing: Spacing.s2 / 4) {
        Text(item.name)
          .font(Typography.labelLg)
          .foregroundStyle(Palette.ink)
        if showsRoom {
          Text(item.room.isEmpty ? "No room yet" : item.room)
            .font(Typography.bodySm)
            .foregroundStyle(Palette.inkMuted)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Image(systemName: "chevron.right")
        .font(Typography.labelSm)
        .foregroundStyle(Palette.inkSubtle)
        .accessibilityHidden(true)
    }
    .padding(.horizontal, Spacing.s4)
    .padding(.vertical, Spacing.s3)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
  }

  private var thumbnail: some View {
    // The sunken surface shows around a cutout, as on the item screen.
    Palette.surfaceSunken
      .overlay {
        if let image = library.thumbnail(of: item) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        }
      }
      .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
      .clipShape(.rect(cornerRadius: Radius.sm))
      .accessibilityHidden(true)
  }
}

#Preview {
  NavigationStack {
    ItemList(title: "Added lately", items: Item.samples)
      .padding()
  }
  .environment(Library.sample)
  .brand()
}
