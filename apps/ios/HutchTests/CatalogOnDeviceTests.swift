import HutchCore
import Testing
import UIKit
@testable import Hutch

/// The real catalog and Core ML model, when `make catalog` built them into the app. On the
/// Mac, SigLIP 2 names this photo "Apple MacBook Air" first, at 0.30, just ahead of "desk".
/// The simulator runs Core ML on the CPU, which drifts enough to reorder such close calls,
/// so this checks the pipeline end to end (a real, unit-length embedding; the laptop near
/// the top), not exact parity: `build.py --check` does that, on the phone's compute units.
/// Fixtures/laptop-on-a-desk.jpg is Aleksi Tappura's, CC0, from Wikimedia Commons.
@Suite(.enabled(if: CatalogEmbedder.fromBundle() != nil, "Run `make catalog` to build the catalog into the app."))
struct CatalogOnDeviceTests {
    @Test func namesTheLaptopAsTheMacDoes() async throws {
        let (catalog, embedder) = try #require(CatalogEmbedder.fromBundle())
        let url = try #require(Bundle(for: FixtureAnchor.self).url(forResource: "laptop-on-a-desk", withExtension: "jpg"))
        let image = try #require(UIImage(contentsOfFile: url.path)?.cgImage)

        let embedding = try await embedder.embed(image)
        #expect(embedding.count == catalog.dimensions)
        let length = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        #expect(abs(length - 1) < 0.01, "a real, unit-length embedding, not zeros")

        let top = catalog.matches(for: embedding, top: 3).map(\.name)
        #expect(top.contains("Apple MacBook Air"), "top 3: \(top)")
    }
}

private final class FixtureAnchor {}
