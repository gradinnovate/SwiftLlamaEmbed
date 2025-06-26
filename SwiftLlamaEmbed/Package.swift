// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLlamaEmbed",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftLlamaEmbed",
            targets: ["SwiftLlamaEmbed"]
        ),
        .executable(
            name: "Demo",
            targets: ["Demo"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftLlamaEmbed",
            dependencies: ["llama"],
            path: "Sources/SwiftLlamaEmbed"
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["SwiftLlamaEmbed"],
            path: "Sources/Demo"
        ),
        .binaryTarget(
            name: "llama",
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b5751/llama-b5751-xcframework.zip",
            checksum: "f99861e83bb8a53745f05f8c9e328c8c0df1a465389487a81571849c021e49cc"
        ),
        .testTarget(
            name: "SwiftLlamaEmbedTests",
            dependencies: ["SwiftLlamaEmbed"],
            path: "Tests"
        ),
    ]
) 