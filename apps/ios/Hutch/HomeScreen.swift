import HutchCore
import SwiftUI

/// Where Hutch opens: what I own, by room, with adding one tap away at the bottom.
struct HomeScreen: View {
    let library: Library
    @State private var adding = false
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(items: library.items, thumbnails: library.thumbnails)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .room(let room):
                        RoomView(room: room, items: library.items.filter { $0.room == room }, thumbnails: library.thumbnails)
                    case .item(let id):
                        if let item = library.items.first(where: { $0.id == id }) {
                            ItemScreen(item: item, library: library) { path.removeLast() }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    AddButton { adding = true }
                }
        }
        .overlay(alignment: .top) {
            if let error = library.error {
                Text(error)
                    .font(Typography.bodySm)
                    .padding(Spacing.s3)
                    .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
                    .padding(Spacing.s4)
            }
        }
        .fullScreenCover(isPresented: $adding) {
            CaptureScreen(library: library)
                .brand()
        }
    }
}

enum Route: Hashable {
    case room(String)
    case item(UUID)
}

/// The primary action, centered within one-handed reach: forest, like the bands on the website.
struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(Typography.headlineMd)
                .foregroundStyle(Palette.onDeep)
                .frame(width: Spacing.s16, height: Spacing.s16)
                .background(Palette.deep, in: .circle)
        }
        .accessibilityLabel("Add an item")
        .padding(.bottom, Spacing.s2)
    }
}

/// Home, free of any logic so snapshot tests can render it.
struct HomeView: View {
    let items: [Item]
    let thumbnails: [UUID: UIImage]
    @State private var query = ""

    /// Rooms with something in them, most-used first; "" holds what has no room yet.
    private var rooms: [(name: String, count: Int)] {
        Dictionary(grouping: items, by: \.room)
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.name.isEmpty != $1.name.isEmpty ? !$0.name.isEmpty : $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
    }

    private var matches: [Item] {
        let words = query.lowercased().split(separator: " ")
        return items.filter { item in
            let text = "\(item.name) \(item.place)".lowercased()
            return words.allSatisfy { text.contains($0) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s7) {
                HStack {
                    Text("hutch")
                        .font(Typography.headlineSm)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    PrivateBadge(text: "On this phone only")
                }

                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("Everything you own, kept quietly.")
                        .font(Typography.headlineLg)
                        .foregroundStyle(Palette.ink)
                    Text(summary)
                        .font(Typography.bodyMd)
                        .foregroundStyle(Palette.inkMuted)
                }

                if items.isEmpty {
                    Text("Tap + and take a photo of something you own. It stays private, on this iPhone.")
                        .font(Typography.bodyMd)
                        .foregroundStyle(Palette.inkMuted)
                        .padding(Spacing.s5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
                } else {
                    SearchField(query: $query)
                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        roomsSection
                        Section {
                            ItemCard(items: Array(items.prefix(5)), thumbnails: thumbnails)
                        } header: {
                            Eyebrow("Added lately")
                        }
                    } else {
                        Section {
                            if matches.isEmpty {
                                Text("Nothing called that yet.")
                                    .font(Typography.bodyMd)
                                    .foregroundStyle(Palette.inkMuted)
                            } else {
                                ItemCard(items: matches, thumbnails: thumbnails)
                            }
                        } header: {
                            Eyebrow("Found")
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.s5)
            .padding(.top, Spacing.s4)
            .padding(.bottom, Spacing.s6)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private var summary: String {
        let roomCount = rooms.filter { !$0.name.isEmpty }.count
        return items.isEmpty ? "Nothing yet" : "\(items.count) \(items.count == 1 ? "thing" : "things") across \(roomCount) \(roomCount == 1 ? "room" : "rooms")"
    }

    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Eyebrow("Rooms")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s3), GridItem(.flexible(), spacing: Spacing.s3)], spacing: Spacing.s3) {
                ForEach(rooms, id: \.name) { room in
                    NavigationLink(value: Route.room(room.name)) {
                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            Text(room.name.isEmpty ? "No room yet" : room.name)
                                .font(Typography.labelLg)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(2, reservesSpace: false)
                            Text("\(room.count) \(room.count == 1 ? "thing" : "things")")
                                .font(Typography.bodySm)
                                .foregroundStyle(Palette.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.s4)
                        .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// "Where did I put the…": filters by name and place.
private struct SearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.inkMuted)
                .accessibilityHidden(true)
            TextField("Search your things", text: $query, prompt: Text("Where did I put the…"))
                .font(Typography.bodyLg)
                .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(minHeight: Spacing.s12)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
        .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.border))
    }
}

/// Items as rows in one card, each opening the item.
struct ItemCard: View {
    let items: [Item]
    let thumbnails: [UUID: UIImage]
    /// In a room, the room is already said: only the spot.
    var showsRoom = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationLink(value: Route.item(item.id)) {
                    ItemRow(item: item, thumbnail: thumbnails[item.id], showsRoom: showsRoom)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                if index < items.count - 1 {
                    Divider().overlay(Palette.border).padding(.leading, Spacing.s4 + Spacing.s12 + Spacing.s3)
                }
            }
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
    }
}

struct ItemRow: View {
    let item: Item
    let thumbnail: UIImage?
    var showsRoom = true

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail).resizable().scaledToFill()
                } else {
                    Palette.surfaceSunken
                }
            }
            .frame(width: Spacing.s12, height: Spacing.s12)
            .clipShape(.rect(cornerRadius: Radius.sm))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s2 / 4) {
                Text(item.name)
                    .font(Typography.labelLg)
                    .foregroundStyle(Palette.ink)
                if let detail {
                    Text(detail)
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
        .accessibilityElement(children: .combine)
    }

    /// Where it lives. In a room, the spot's heading already says where.
    private var detail: String? {
        guard showsRoom else { return nil }
        return item.place.isEmpty ? "No place yet" : item.place
    }
}

/// One room: its things, grouped by spot.
struct RoomView: View {
    let room: String
    let items: [Item]
    let thumbnails: [UUID: UIImage]

    private var spots: [(name: String, items: [Item])] {
        Dictionary(grouping: items, by: \.spot)
            .map { (name: $0.key, items: $0.value) }
            .sorted { $0.name.isEmpty != $1.name.isEmpty ? !$0.name.isEmpty : $0.name < $1.name }
    }

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
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Eyebrow(spot.name.isEmpty ? (spots.count == 1 ? "Everything" : "No spot") : spot.name)
                        ItemCard(items: spot.items, thumbnails: thumbnails, showsRoom: false)
                    }
                }
            }
            .padding(.horizontal, Spacing.s5)
            .padding(.bottom, Spacing.s6)
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: String {
        let named = spots.filter { !$0.name.isEmpty }.count
        let things = "\(items.count) \(items.count == 1 ? "thing" : "things")"
        return named == 0 ? things : "\(things) · \(named) \(named == 1 ? "spot" : "spots")"
    }
}

/// One item: its photo, then a sheet with where it lives and its name.
struct ItemScreen: View {
    let item: Item
    let library: Library
    let onDeleted: () -> Void
    @State private var photo: UIImage?

    var body: some View {
        ItemDetailView(item: item, photo: photo ?? library.thumbnails[item.id]) {
            Task {
                await library.delete(item.id)
                onDeleted()
            }
        }
        .task { photo = await library.photo(of: item.id) }
    }
}

struct ItemDetailView: View {
    let item: Item
    let photo: UIImage?
    var onDelete: () -> Void = {}
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Group {
                    if let photo {
                        Image(uiImage: photo).resizable().scaledToFill()
                    } else {
                        Palette.surfaceSunken
                    }
                }
                .frame(height: Spacing.s30 * 2.5)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text(item.place.isEmpty ? "No place yet" : item.place.replacingOccurrences(of: " · ", with: " › "))
                            .font(Typography.labelMd)
                            .foregroundStyle(Palette.inkMuted)
                        Text(item.name)
                            .font(Typography.headlineLg)
                            .foregroundStyle(Palette.ink)
                    }

                    PrivateBadge()

                    Button(role: .destructive) { confirmingDelete = true } label: {
                        Text("Remove from Hutch")
                            .font(Typography.labelLg)
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: Spacing.s12)
                            .overlay(Capsule().strokeBorder(Palette.border))
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Spacing.s4)
                    .confirmationDialog("Remove \(item.name)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                        Button("Remove", role: .destructive, action: onDelete)
                    } message: {
                        Text("Its photo and details are deleted from this iPhone.")
                    }
                }
                .padding(.horizontal, Spacing.s6)
                .padding(.top, Spacing.s8)
                .padding(.bottom, Spacing.s6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.background, in: UnevenRoundedRectangle(topLeadingRadius: Radius.md, topTrailingRadius: Radius.md))
                .padding(.top, -Spacing.s6)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}
