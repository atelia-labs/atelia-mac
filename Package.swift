// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AteliaMacWorkspace",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "AteliaMacCore",
            targets: ["AteliaMacCore"]
        )
    ],
    dependencies: [
        .package(path: "../atelia-kit")
    ],
    targets: [
        .target(
            name: "AteliaMacCore",
            dependencies: [
                .product(name: "AteliaKit", package: "atelia-kit")
            ]
        ),
        .testTarget(
            name: "AteliaMacCoreTests",
            dependencies: ["AteliaMacCore"]
        )
    ]
)
