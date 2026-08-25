// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WebBar",
            targets: ["WebBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WebBar",
            dependencies: [],
            path: "Sources/WebBar"
        )
    ]
)
