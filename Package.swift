// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AteliaMacWorkspace",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "AteliaMacClient",
            targets: ["AteliaMacClient"]
        ),
        .library(
            name: "AteliaMacCore",
            targets: ["AteliaMacCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/atelia-labs/atelia-kit.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "AteliaMacClient",
            dependencies: [
                "AteliaMacClientModels",
                "AteliaMacCore"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AteliaMacClientModels"
        ),
        .target(
            name: "AteliaMacCore",
            dependencies: [
                .product(name: "AteliaKit", package: "atelia-kit")
            ]
        ),
        .testTarget(
            name: "AteliaMacClientModelsTests",
            dependencies: ["AteliaMacClientModels"]
        ),
        .testTarget(
            name: "AteliaMacCoreTests",
            dependencies: ["AteliaMacCore"]
        ),
        .testTarget(
            name: "AteliaMacClientTests",
            dependencies: ["AteliaMacClient"]
        )
    ]
)
