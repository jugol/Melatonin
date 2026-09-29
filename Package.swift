// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Melatonin",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MelatoninShared"),
        .executableTarget(name: "Melatonin", dependencies: ["MelatoninShared"]),
        .executableTarget(name: "MelatoninHelper", dependencies: ["MelatoninShared"]),
    ],
    swiftLanguageModes: [.v5]
)
