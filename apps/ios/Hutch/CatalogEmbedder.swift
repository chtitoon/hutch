import CoreML
import HutchCore
import Vision

/// SigLIP 2's image half in Core ML (X5): a photo in, a unit-length embedding out, on the
/// phone. Built by `make catalog` into `Hutch/Catalog/`, which isn't committed; without it,
/// the app runs with Apple Intelligence and Vision alone.
actor CatalogEmbedder: ImageEmbedding {
    private let model: MLModel
    private let constraint: MLImageConstraint

    /// The model and catalog from the app bundle, or nil when `make catalog` hasn't been run.
    static func fromBundle() -> (Catalog, CatalogEmbedder)? {
        guard let modelURL = Bundle.main.url(forResource: "ImageEncoder", withExtension: "mlmodelc"),
              let jsonURL = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let vectorsURL = Bundle.main.url(forResource: "catalog", withExtension: "bin"),
              let catalog = try? Catalog(json: Data(contentsOf: jsonURL), vectors: Data(contentsOf: vectorsURL)),
              let embedder = try? CatalogEmbedder(modelURL: modelURL) else { return nil }
        return (catalog, embedder)
    }

    init(modelURL: URL) throws {
        let configuration = MLModelConfiguration()
        // CPU and GPU, not the Neural Engine: with the int8 weights, the GPU path matches
        // PyTorch (cosine 0.9998) and the Neural Engine and CPU paths drift (0.97), enough to
        // reorder close matches. `build.py --check` checks the same units on the Mac. The
        // simulator's GPU path returns zeros, so it runs on the CPU, drift and all.
        #if targetEnvironment(simulator)
        configuration.computeUnits = .cpuOnly
        #else
        configuration.computeUnits = .cpuAndGPU
        #endif
        model = try MLModel(contentsOf: modelURL, configuration: configuration)
        guard let constraint = model.modelDescription.inputDescriptionsByName["image"]?.imageConstraint else {
            throw CatalogEmbedderError.unexpectedModel
        }
        self.constraint = constraint
    }

    func embed(_ image: CGImage) async throws -> [Float] {
        // Stretched to 224×224 without cropping, as SigLIP's own preprocessing does.
        let input = try MLFeatureValue(cgImage: image, constraint: constraint, options: [
            .cropAndScale: VNImageCropAndScaleOption.scaleFill.rawValue,
        ])
        let output = try Self.predict(model, MLDictionaryFeatureProvider(dictionary: ["image": input]))
        guard let embedding = output.featureValue(for: "embedding")?.multiArrayValue else {
            throw CatalogEmbedderError.unexpectedModel
        }
        // Read through MLShapedArray, which follows the array's strides: Core ML may pad
        // them, and reading element by element then picks up the padding.
        let vector = MLShapedArray<Float>(converting: embedding).scalars
        // Unit length again, so SigLIP's scores mean what they did on the Mac; int8 weights
        // can drift it slightly.
        let length = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        return length > 0 ? vector.map { $0 / length } : vector
    }

    /// Synchronous on purpose: the actor already runs one prediction at a time, off the main
    /// thread, and the async variant would hand the model across isolation. A synchronous
    /// function is the only place Swift picks the synchronous `prediction`.
    private static func predict(_ model: MLModel, _ input: MLFeatureProvider) throws -> MLFeatureProvider {
        try model.prediction(from: input)
    }
}

enum CatalogEmbedderError: Error {
    case unexpectedModel
}
