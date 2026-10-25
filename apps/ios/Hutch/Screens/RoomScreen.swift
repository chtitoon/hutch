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
          Text("^[\(items.count) thing](inflect: true)")
            .font(Typography.bodyMd)
            .foregroundStyle(Palette.inkMuted)
        }
        ItemList(title: "Everything", items: items, showsRoom: false)
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
}

#Preview {
  NavigationStack {
    RoomScreen(room: "Garage")
  }
  .environment(Library.sample)
  .brand()
}
