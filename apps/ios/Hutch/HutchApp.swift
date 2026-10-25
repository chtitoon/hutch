import HutchCore
import SwiftUI

@main
struct HutchApp: App {
    @State private var library = Library.onDevice()

    init() {
        BrandFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            CaptureScreen(library: library)
                .brand()
        }
    }
}

extension View {
    /// The brand's defaults for a whole screen: sage tint, and body text in Instrument Sans.
    func brand() -> some View {
        tint(Palette.sage)
            .font(Typography.bodyLg)
    }
}
