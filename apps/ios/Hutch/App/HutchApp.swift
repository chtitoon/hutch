import SwiftUI

@main
struct HutchApp: App {
  @State private var library = Library.onDevice()

  init() {
    BrandFonts.register()
  }

  var body: some Scene {
    WindowGroup {
      HomeScreen()
        .environment(library)
        .brand()
    }
  }
}
