import HutchCore
import SwiftUI

struct RoomScreen: View {
  let room: String

  @Environment(Library.self) private var library

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Spacing.s6) {
        VStack(alignment: .leading, spacing: Spacing.s2) {
          Text(room.isEmpty ? "No room yet" : room)
            .font(Typography.headlineLg)
            .foregroundStyle(Palette.ink)
          Text(summary)
            .font(Typography.bodyMd)
            .foregroundStyle(Palette.inkMuted)
        }
        ForEach(spots, id: \.name) { spot in
          ItemList(title: title(of: spot.name), items: spot.items, showsPlace: false)
        }
      }
      .padding(.horizontal, Spacing.s5)
      .padding(.bottom, Spacing.s6)
    }
    .background(Palette.background)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var items: [Item] {
    library.items(in: room)
  }

  // Named spots alphabetically, then things with no spot.
  private var spots: [(name: String, items: [Item])] {
    Dictionary(grouping: items, by: \.spot)
      .map { (name: $0.key, items: $0.value) }
      .sorted { lhs, rhs in
        if lhs.name.isEmpty != rhs.name.isEmpty { return rhs.name.isEmpty }
        return lhs.name < rhs.name
      }
  }

  private func title(of spot: String) -> String {
    guard spot.isEmpty else { return spot }
    return spots.count == 1 ? "Everything" : "No spot"
  }

  private var summary: LocalizedStringKey {
    let namedSpots = spots.count { !$0.name.isEmpty }
    if namedSpots == 0 {
      return "^[\(items.count) thing](inflect: true)"
    }
    return "^[\(items.count) thing](inflect: true) · ^[\(namedSpots) spot](inflect: true)"
  }
}

#Preview {
  NavigationStack {
    RoomScreen(room: "Garage")
  }
  .environment(Library.sample)
  .brand()
}
