// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ReactiveKit",
    platforms: [
        .macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)
    ],
    products: [
        .library(name: "ReactiveKit", type: .dynamic, targets: ["ReactiveKit"])
    ],
    targets: [
        .target(name: "ReactiveKit", path: "Sources"),
        .testTarget(name: "ReactiveKitTests", dependencies: ["ReactiveKit"])
    ]
)
