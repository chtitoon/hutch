import HutchCore
import SwiftUI

/// The empty root screen: just the logo, until M1 adds the inventory.
struct ContentView: View {
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            Logo()
                .frame(maxWidth: 240)
                .padding(Space.s8)
        }
    }
}

/// The house-and-keyhole mark beside the "hutch" wordmark, drawn from design/light/logo.svg.
/// Both parts share one canvas so they stay aligned; the mark is sage and the wordmark ink, as on the website.
struct Logo: View {
    var body: some View {
        ZStack {
            Image("LogoMark").resizable().foregroundStyle(Palette.sage)
            Image("LogoWord").resizable().foregroundStyle(Palette.ink)
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
