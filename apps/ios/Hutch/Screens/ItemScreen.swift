import HutchCore
import SwiftUI

struct ItemScreen: View {
  let item: Item

  @Environment(Library.self) private var library
  @Environment(\.dismiss) private var dismiss
  @State private var photo: UIImage?
  @State private var isConfirmingDelete = false

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Photo(image: photo ?? library.thumbnail(of: item))
        VStack(alignment: .leading, spacing: Spacing.s5) {
          VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(item.room.isEmpty ? "No room yet" : item.room)
              .font(Typography.labelMd)
              .foregroundStyle(Palette.inkMuted)
            Text(item.name)
              .font(Typography.headlineLg)
              .foregroundStyle(Palette.ink)
          }
          Button("Remove from Hutch") { isConfirmingDelete = true }
            .buttonStyle(.outlined)
            // On the button, so its popover points at it rather than at the whole screen.
            .confirmationDialog(
              "Remove \(item.name)?",
              isPresented: $isConfirmingDelete,
              titleVisibility: .visible
            ) {
              Button("Remove", role: .destructive, action: delete)
            } message: {
              Text("Its photo and details are deleted from this iPhone.")
            }
            .padding(.top, Spacing.s4)
        }
        .sheetStyle()
      }
    }
    .ignoresSafeArea(edges: .top)
    .background(Palette.background)
    .navigationBarTitleDisplayMode(.inline)
    .task { await loadPhoto() }
  }

  private func loadPhoto() async {
    do {
      photo = try await library.photo(of: item)
    } catch {
      library.error = "Couldn't open the photo. (\(error.localizedDescription))"
    }
  }

  private func delete() {
    Task {
      do {
        try await library.delete(item)
        dismiss()
      } catch {
        library.error = "Couldn't remove it. (\(error.localizedDescription))"
      }
    }
  }
}

#Preview {
  NavigationStack {
    ItemScreen(item: Item.samples[0])
  }
  .environment(Library.sample)
  .brand()
}
