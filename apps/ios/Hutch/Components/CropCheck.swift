#if DEBUG
  import SwiftUI

  /// Development builds only: the whole photo with the crop outlined, to see which edge is off.
  /// Held in memory, never saved.
  struct CropCheck {
    let original: CGImage
    let crop: CGRect
  }

  struct CropCheckView: View {
    let check: CropCheck

    var body: some View {
      Image(decorative: check.original, scale: 1)
        .resizable()
        .scaledToFit()
        .overlay {
          GeometryReader { geometry in
            let scale = geometry.size.width / CGFloat(check.original.width)
            Rectangle()
              .stroke(Palette.accent, lineWidth: 3)
              .frame(width: check.crop.width * scale, height: check.crop.height * scale)
              .offset(x: check.crop.minX * scale, y: check.crop.minY * scale)
          }
        }
        .padding(.bottom, Photo.sheetOverlap)
    }
  }
#endif
