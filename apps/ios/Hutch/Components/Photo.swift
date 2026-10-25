import SwiftUI

struct Photo: View {
  let image: UIImage?

  static let height = Spacing.s30 * 2.5

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Palette.surfaceSunken
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: Self.height)
    .clipped()
    .accessibilityHidden(true)
  }
}

extension View {
  func sheetStyle() -> some View {
    padding(.horizontal, Spacing.s5)
      .padding(.vertical, Spacing.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        Palette.background,
        in: UnevenRoundedRectangle(topLeadingRadius: Radius.lg, topTrailingRadius: Radius.lg)
      )
      .padding(.top, -Spacing.s7)
  }
}
