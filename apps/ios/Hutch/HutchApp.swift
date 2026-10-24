import HutchCore
import SwiftUI

@main
struct HutchApp: App {
    @State private var library = Library.onDevice()

    var body: some Scene {
        WindowGroup {
            CaptureScreen(library: library)
                .tint(Palette.sage)
        }
    }
}
