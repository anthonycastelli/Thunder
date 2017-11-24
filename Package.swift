// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Thunder",
    products: [
        .library(name: "Thunder", targets: ["Thunder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "4.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/jakeheis/Spawn", from: "0.0.6"),
    ],
    targets: [
        .target(name: "Thunder", dependencies: ["Rainbow", "SwiftCLI", "Spawn"]),
        .testTarget(name: "ThunderTests", dependencies: ["Thunder"]),
    ]
)
