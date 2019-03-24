// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ReactiveKit",
    products: [
        .library(name: "ReactiveKit", targets: ["ReactiveKit"])
    ],
    targets: [
        .target(name: "ReactiveKit", path: "Sources"),
        .testTarget(name: "ReactiveKitTests", dependencies: ["ReactiveKit"])
    ]
)
