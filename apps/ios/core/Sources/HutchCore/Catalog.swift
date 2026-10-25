import Accelerate
import CoreGraphics
import Foundation

/// The product catalog the phone matches photos against (X5, D27): names built on the Mac by
/// `tools/catalog-index/build.py`, each with a SigLIP 2 text embedding. Matching is a dot
/// product with the photo's embedding, on the phone; nothing is looked up online.
public struct Catalog: Sendable {
    public let names: [String]
    public let dimensions: Int
    /// Row after row, one unit-length vector per name.
    let vectors: [Float]
    /// SigLIP's scale and bias, which turn a similarity into an independent 0–1 score.
    let logitScale: Float
    let logitBias: Float

    public init(names: [String], dimensions: Int, vectors: [Float], logitScale: Float, logitBias: Float) {
        precondition(vectors.count == names.count * dimensions, "one vector per name")
        self.names = names
        self.dimensions = dimensions
        self.vectors = vectors
        self.logitScale = logitScale
        self.logitBias = logitBias
    }

    /// Reads `catalog.json` and `catalog.bin` (float16, little-endian) as `build.py` writes them.
    public init(json: Data, vectors data: Data) throws {
        let meta = try JSONDecoder().decode(Meta.self, from: json)
        guard data.count == meta.names.count * meta.dimensions * 2 else { throw CatalogError.sizeMismatch }
        let vectors = data.withUnsafeBytes { raw in
            raw.bindMemory(to: UInt16.self).map { Float(Float16(bitPattern: UInt16(littleEndian: $0))) }
        }
        self.init(names: meta.names, dimensions: meta.dimensions, vectors: vectors, logitScale: meta.logitScale, logitBias: meta.logitBias)
    }

    /// The closest names to a unit-length photo embedding, best first.
    public func matches(for embedding: [Float], top count: Int = 5) -> [CatalogMatch] {
        guard embedding.count == dimensions, !names.isEmpty else { return [] }
        var similarities = [Float](repeating: 0, count: names.count)
        // similarities = vectors (names × dimensions) · embedding
        vectors.withUnsafeBufferPointer { matrix in
            embedding.withUnsafeBufferPointer { vector in
                similarities.withUnsafeMutableBufferPointer { result in
                    vDSP_mmul(matrix.baseAddress!, 1, vector.baseAddress!, 1, result.baseAddress!, 1,
                              vDSP_Length(names.count), 1, vDSP_Length(dimensions))
                }
            }
        }
        return similarities.indices
            .sorted { similarities[$0] > similarities[$1] }
            .prefix(count)
            .map { CatalogMatch(name: names[$0], score: Self.sigmoid(logitScale * similarities[$0] + logitBias)) }
    }

    static func sigmoid(_ x: Float) -> Float { 1 / (1 + exp(-x)) }

    private struct Meta: Decodable {
        var names: [String]
        var dimensions: Int
        var logitScale: Float
        var logitBias: Float
    }
}

public struct CatalogMatch: Sendable, Equatable {
    public var name: String
    /// SigLIP's independent 0–1 score for "this photo shows this", not a share of a total.
    public var score: Float

    public init(name: String, score: Float) {
        self.name = name
        self.score = score
    }

    /// How sure a match is, from scores on my own photos (E5): at 0.3 and up, 5 of 5 were
    /// right; below that, about half. Provisional until X5's eval has 20+ photos.
    public enum Confidence: Sendable, Equatable {
        /// Use it as the name.
        case high
        /// Offer it, and let Apple Intelligence decide with it as a hint.
        case medium
        /// Ignore it.
        case low
    }

    public var confidence: Confidence {
        score >= 0.3 ? .high : score >= 0.05 ? .medium : .low
    }
}

/// Turns a photo into a unit-length embedding, on the device.
public protocol ImageEmbedding: Sendable {
    func embed(_ image: CGImage) async throws -> [Float]
}

public enum CatalogError: Error {
    case sizeMismatch
}
