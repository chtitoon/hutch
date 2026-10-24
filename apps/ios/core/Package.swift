// swift-tools-version: 6.2
// Hutch's core logic (models, crypto, storage, on-device suggestions), kept out of the app
// target so unit tests cover it.
import PackageDescription

let package = Package(
    name: "HutchCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "HutchCore", targets: ["HutchCore"]),
    ],
    targets: [
        .target(name: "HutchCore"),
        .testTarget(name: "HutchCoreTests", dependencies: ["HutchCore"]),
    ]
)
