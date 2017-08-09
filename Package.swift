// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ReactiveKit",
    targets: [
        .target(name: "ReactiveKit", dependencies: []),
        .testTarget(name: "ReactiveKitTests", dependencies: ["ReactiveKit"])
    ],
	swiftLanguageVersions: [4]
)
