// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuSwitch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MenuSwitch",
            targets: ["MenuSwitch"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MenuSwitch",
            dependencies: [],
            path: "Sources/MenuSwitch"
        ),
        .testTarget(
            name: "MenuSwitchTests",
            dependencies: ["MenuSwitch"],
            path: "Tests/MenuSwitchTests"
        )
    ]
)
