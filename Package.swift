// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenTimeWrapped",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ScreenTimeWrapped",
            targets: ["ScreenTimeWrapped"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScreenTimeWrapped",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
