import SwiftUI

/// An item's photo, square and full width, shown whole: a camera photo is cropped square when it's
/// taken, so this is exactly what was saved.
struct Photo: View {
  let image: UIImage?

  // The sheet below rises this far over the photo; the photo leaves room for it.
  static let sheetOverlap = Spacing.s7

  var body: some View {
    // The square sets the size; a fill-scaled image would otherwise overflow it.
    Palette.surfaceSunken
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .itemShadow(radius: Spacing.s3)
        }
      }
      .clipped()
      .padding(.bottom, Self.sheetOverlap)
      .accessibilityHidden(true)
  }
}

extension View {
  // A cut-out item rests on the surface instead of looking pasted on (DESIGN.md, Elevation). A
  // full photo casts it outside its square, where it's clipped away.
  func itemShadow(radius: CGFloat) -> some View {
    shadow(color: Palette.device.opacity(0.18), radius: radius, y: radius / 2)
      // Drawn once into one image: a live shadow is redrawn on every frame, and stalled typing.
      .drawingGroup()
  }

  func sheetStyle() -> some View {
    padding(.horizontal, Spacing.s5)
      .padding(.vertical, Spacing.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        Palette.background,
        in: UnevenRoundedRectangle(topLeadingRadius: Radius.lg, topTrailingRadius: Radius.lg)
      )
      .padding(.top, -Photo.sheetOverlap)
  }
}
