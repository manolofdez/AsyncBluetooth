// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AsyncBluetooth",
    platforms: [
        .macOS("11.0"),
        .iOS("14.0"),
        .watchOS("7.0")
    ],
    products: [
        .library(
            name: "AsyncBluetooth",
            targets: ["AsyncBluetooth"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncBluetooth",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AsyncBluetoothTests",
            dependencies: ["AsyncBluetooth"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
