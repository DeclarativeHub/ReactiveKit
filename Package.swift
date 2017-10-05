// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ReactiveKit",
	targets: [
		.target(name: "ReactiveKit", path: "Sources"),
		.testTarget(name: "ReactiveKitTests", dependencies: ["ReactiveKit"])
	]
)
