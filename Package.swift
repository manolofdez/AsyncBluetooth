// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AsyncBluetooth",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v13)
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
    ]
)
