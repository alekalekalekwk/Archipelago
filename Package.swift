// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Archipelago",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Archipelago", targets: ["Archipelago"])
    ],
    targets: [
        .executableTarget(
            name: "Archipelago",
            dependencies: [],
            path: "Sources/Archipelago"
        )
    ]
)
