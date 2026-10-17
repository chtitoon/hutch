import HutchCore
import SwiftUI

/// The empty root screen: just the logo, until M1 adds the inventory.
/// It sits on the forest band in both modes, like the link-preview card; the rest of the app follows the system.
struct ContentView: View {
    var body: some View {
        ZStack {
            Palette.deep.ignoresSafeArea()
            Logo(mark: Palette.sageOnDeep, word: Palette.onDeep)
                .frame(maxWidth: 360)
                .padding(.horizontal, Space.s8)
        }
        .preferredColorScheme(.dark) // light status bar on the forest
    }
}

/// The house-and-keyhole mark beside the "hutch" wordmark, drawn from design/light/logo.svg.
/// Both parts share one canvas so they stay aligned. By default the mark is sage and the wordmark ink, as on the website.
struct Logo: View {
    var mark = Palette.sage
    var word = Palette.ink

    var body: some View {
        ZStack {
            Image("LogoMark").resizable().foregroundStyle(mark)
            Image("LogoWord").resizable().foregroundStyle(word)
        }
        .aspectRatio(LogoCanvas.aspectRatio, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Hutch.name)
        .accessibilityAddTraits(.isImage)
    }
}

#Preview {
    ContentView()
}
