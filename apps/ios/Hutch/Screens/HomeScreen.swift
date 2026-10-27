import HutchCore
import SwiftUI

struct HomeScreen: View {
  @Environment(Library.self) private var library
  @State private var query = ""
  @State private var isAdding = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s7) {
          header
          if library.items.isEmpty {
            emptyState
          } else {
            SearchField(query: $query)
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
              roomGrid
              ItemList(title: "Added lately", items: Array(library.items.prefix(5)))
            } else {
              searchResults
            }
          }
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.vertical, Spacing.s4)
      }
      .scrollDismissesKeyboard(.immediately)
      .background(Palette.background)
      .toolbarVisibility(.hidden, for: .navigationBar)
      .navigationDestination(for: Route.self) { route in
        switch route {
        case .room(let room):
          RoomScreen(room: room)
        case .item(let item):
          ItemScreen(item: item)
        }
      }
      .safeAreaInset(edge: .bottom) {
        AddButton { isAdding = true }
      }
    }
    .alert("Something went wrong", isPresented: showsError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(library.error ?? "")
    }
    .fullScreenCover(isPresented: $isAdding) {
      CaptureScreen()
        .brand()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: Spacing.s7) {
      HStack {
        Text("hutch")
          .font(Typography.headlineSm)
        Spacer()
        PrivateBadge()
      }
      VStack(alignment: .leading, spacing: Spacing.s2) {
        Text("Everything you own, kept quietly.")
          .font(Typography.headlineLg)
        Text(summary)
          .font(Typography.bodyMd)
          .foregroundStyle(Palette.inkMuted)
      }
    }
    .foregroundStyle(Palette.ink)
  }

  private var summary: LocalizedStringKey {
    let items = library.items.count
    let rooms = self.rooms.count { !$0.name.isEmpty }
    return items == 0
      ? "Nothing yet" : "^[\(items) thing](inflect: true) across ^[\(rooms) room](inflect: true)"
  }

  private var emptyState: some View {
    Text("Tap + and take a photo of something you own. It stays private, on this iPhone.")
      .font(Typography.bodyMd)
      .foregroundStyle(Palette.inkMuted)
      .padding(Spacing.s5)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
  }

  // Fullest rooms first; things with no room yet come last.
  private var rooms: [(name: String, count: Int)] {
    Dictionary(grouping: library.items, by: \.room)
      .map { (name: $0.key, count: $0.value.count) }
      .sorted { lhs, rhs in
        if lhs.name.isEmpty != rhs.name.isEmpty { return rhs.name.isEmpty }
        if lhs.count != rhs.count { return lhs.count > rhs.count }
        return lhs.name < rhs.name
      }
  }

  private var roomGrid: some View {
    VStack(alignment: .leading, spacing: Spacing.s3) {
      Eyebrow("Rooms")
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s3), count: 2),
        spacing: Spacing.s3
      ) {
        ForEach(rooms, id: \.name) { room in
          NavigationLink(value: Route.room(room.name)) {
            RoomCard(name: room.name, count: room.count)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var matches: [Item] {
    let words = query.lowercased().split(separator: " ")
    return library.items.filter { item in
      let text = "\(item.name) \(item.room)".lowercased()
      return words.allSatisfy { text.contains($0) }
    }
  }

  @ViewBuilder
  private var searchResults: some View {
    if matches.isEmpty {
      Text("Nothing called that yet.")
        .font(Typography.bodyMd)
        .foregroundStyle(Palette.inkMuted)
    } else {
      ItemList(title: "Found", items: matches)
    }
  }

  private var showsError: Binding<Bool> {
    Binding {
      library.error != nil
    } set: { isPresented in
      if !isPresented { library.error = nil }
    }
  }
}

enum Route: Hashable {
  case room(String)
  case item(Item)
}

private struct RoomCard: View {
  let name: String
  let count: Int

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.s4) {
      Text(name.isEmpty ? "No room yet" : name)
        .font(Typography.labelLg)
        .foregroundStyle(Palette.ink)
        .lineLimit(2)
      Text("^[\(count) thing](inflect: true)")
        .font(Typography.bodySm)
        .foregroundStyle(Palette.inkMuted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.s4)
    .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
  }
}

#Preview("Home") {
  HomeScreen()
    .environment(Library.sample)
    .brand()
}

#Preview("Empty") {
  HomeScreen()
    .environment(Library(store: nil))
    .brand()
}
