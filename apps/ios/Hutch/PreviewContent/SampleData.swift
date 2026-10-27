#if DEBUG
  import HutchCore
  import UIKit

  // Items and photos for previews and snapshot tests. Never in a release build.

  extension Library {
    static var sample: Library {
      Library(store: nil, items: Item.samples, thumbnails: Item.sampleThumbnails)
    }
  }

  extension Item {
    static let samples: [Item] = [
      Item(
        name: "DeWalt 18V cordless drill",
        room: "Garage",
        createdAt: Date(timeIntervalSince1970: 4)
      ),
      Item(
        name: "Aluminium step ladder",
        room: "Garage",
        createdAt: Date(timeIntervalSince1970: 3)
      ),
      Item(name: "Quechua 2-person tent", room: "Attic", createdAt: Date(timeIntervalSince1970: 2)),
      Item(name: "Kids' bike", createdAt: Date(timeIntervalSince1970: 1)),
    ]

    static var sampleThumbnails: [Item.ID: UIImage] {
      let symbols = ["wrench.and.screwdriver", "hammer", "tent", "bicycle"]
      return Dictionary(uniqueKeysWithValues: zip(samples.map(\.id), symbols.map(UIImage.sample)))
    }
  }

  extension UIImage {
    static func sample(_ symbol: String) -> UIImage {
      let size = CGSize(width: 600, height: 450)
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      return UIGraphicsImageRenderer(size: size, format: format).image { context in
        UIColor(Palette.surfaceSunken).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        let configuration = UIImage.SymbolConfiguration(pointSize: 200, weight: .regular)
        guard
          let image = UIImage(systemName: symbol, withConfiguration: configuration)?
            .withTintColor(UIColor(Palette.deep), renderingMode: .alwaysOriginal)
        else { return }
        image.draw(
          at: CGPoint(
            x: (size.width - image.size.width) / 2,
            y: (size.height - image.size.height) / 2
          )
        )
      }
    }
  }
#endif
