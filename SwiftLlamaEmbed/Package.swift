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
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b5688/llama-b5688-xcframework.zip",
            checksum: "b7d07e66d7d6b4d236224b4130aff47f8cc4a6197eb8b95a06102ceae8e93e86"
        ),
        .testTarget(
            name: "SwiftLlamaEmbedTests",
            dependencies: ["SwiftLlamaEmbed"],
            path: "Tests"
        ),
    ]
) 