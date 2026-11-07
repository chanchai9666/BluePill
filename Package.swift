// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BluePill",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BluePill", targets: ["BluePill"])
    ],
    targets: [
        .executableTarget(
            name: "BluePill",
            path: "Sources/BluePill"
        ),
        .testTarget(
            name: "BluePillTests",
            dependencies: ["BluePill"],
            path: "Tests/BluePillTests"
        )
    ]
)
