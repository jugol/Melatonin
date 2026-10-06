// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Melatonin",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0"),
    ],
    targets: [
        .target(name: "MelatoninShared"),
        .executableTarget(
            name: "Melatonin",
            dependencies: ["MelatoninShared", .product(name: "Sparkle", package: "Sparkle")]
        ),
        .executableTarget(name: "MelatoninHelper", dependencies: ["MelatoninShared"]),
    ],
    swiftLanguageModes: [.v5]
)
