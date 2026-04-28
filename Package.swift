// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClearViewApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClearViewApp", targets: ["ClearViewApp"])
    ],
    targets: [
        .executableTarget(
            name: "ClearViewApp",
            path: "Sources/ClearViewApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
