// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ReactiveKit",
    platforms: [
        .macOS(.v10_11), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)
    ],
    products: [
        .library(name: "ReactiveKit", targets: ["ReactiveKit"])
    ],
    targets: [
        .target(name: "ReactiveKit", path: "Sources"),
        .testTarget(name: "ReactiveKitTests", dependencies: ["ReactiveKit"])
    ]
)
