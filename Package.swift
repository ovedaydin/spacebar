// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Spacebar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Spacebar", targets: ["Spacebar"]),
        .executable(name: "spacebar-bench", targets: ["spacebar-bench"]),
    ],
    dependencies: [
        // Auto-updates. Updates are verified with an EdDSA signature (no Apple Developer ID needed).
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        // Read-only: scanning, sizing, catalog of cleanable locations. No deletion code.
        .target(name: "SpacebarCore"),
        // The app. The only target that can delete files.
        .executableTarget(
            name: "Spacebar",
            dependencies: ["SpacebarCore", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        // Read-only benchmark CLI.
        .executableTarget(name: "spacebar-bench", dependencies: ["SpacebarCore"]),
    ]
)
