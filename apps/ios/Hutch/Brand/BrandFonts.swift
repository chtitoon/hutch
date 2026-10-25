import CoreText
import SwiftUI

/// Registered at launch rather than in the Info.plist, which XcodeGen writes.
enum BrandFonts {
  static let files = ["BricolageGrotesque", "InstrumentSans"]

  // SwiftUI styles navigation titles only through UIKit's appearance.
  @MainActor static func register() {
    guard !registered else { return }
    registered = true
    for name in files {
      guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
    let ink = UIColor(Palette.ink)
    let largeTitle: [NSAttributedString.Key: Any] = [
      .font: font("Bricolage Grotesque", size: 36, weight: .bold, style: .largeTitle),
      .foregroundColor: ink,
    ]
    let title: [NSAttributedString.Key: Any] = [
      .font: font("Instrument Sans", size: 17, weight: .semibold, style: .headline),
      .foregroundColor: ink,
    ]
    let standard = UINavigationBarAppearance()
    standard.configureWithDefaultBackground()
    let edge = UINavigationBarAppearance()
    edge.configureWithTransparentBackground()
    for appearance in [standard, edge] {
      appearance.largeTitleTextAttributes = largeTitle
      appearance.titleTextAttributes = title
    }
    let bar = UINavigationBar.appearance()
    bar.standardAppearance = standard
    bar.compactAppearance = standard
    bar.scrollEdgeAppearance = edge
  }

  @MainActor private static var registered = false

  private static func font(
    _ family: String,
    size: CGFloat,
    weight: UIFont.Weight,
    style: UIFont.TextStyle
  ) -> UIFont {
    let descriptor = UIFontDescriptor(fontAttributes: [
      .family: family, .traits: [UIFontDescriptor.TraitKey.weight: weight],
    ])
    return UIFontMetrics(forTextStyle: style).scaledFont(
      for: UIFont(descriptor: descriptor, size: size)
    )
  }
}
