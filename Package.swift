// swift-tools-version:4.1
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
