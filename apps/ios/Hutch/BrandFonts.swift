import CoreText
import SwiftUI

/// Bricolage Grotesque and Instrument Sans (DESIGN.md), bundled under the SIL Open Font
/// License (`Fonts/*-OFL.txt`). Registered at launch rather than in the Info.plist, which
/// XcodeGen generates.
enum BrandFonts {
    static let files = ["BricolageGrotesque", "InstrumentSans"]

    /// Registers the fonts once, and sets navigation titles in them, which SwiftUI styles
    /// only through UIKit's appearance.
    @MainActor static func register() {
        guard !registered else { return }
        registered = true
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        let ink = UIColor(Palette.ink)
        let largeTitle: [NSAttributedString.Key: Any] = [.font: font("Bricolage Grotesque", size: 36, weight: .bold, style: .largeTitle), .foregroundColor: ink]
        let title: [NSAttributedString.Key: Any] = [.font: font("Instrument Sans", size: 17, weight: .semibold, style: .headline), .foregroundColor: ink]
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

    private static func font(_ family: String, size: CGFloat, weight: UIFont.Weight, style: UIFont.TextStyle) -> UIFont {
        let descriptor = UIFontDescriptor(fontAttributes: [.family: family, .traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: size))
    }
}

/// A section's eyebrow: `label-caps`, uppercase and tracked out, in sage (DESIGN.md).
struct Eyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(Typography.labelCaps)
            // label-caps' letterSpacing, 0.08em of its 14px. Tokens.swift carries no tracking yet.
            .tracking(14 * 0.08)
            .foregroundStyle(Palette.sage)
    }
}
