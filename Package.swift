import PackageDescription

let package = Package(
    name: "Thunder",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 3),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2),
        .Package(url: "https://github.com/jakeheis/Spawn", majorVersion: 0),
    ],
    exclude: [
        "Tests/TestProject"
    ]
)
