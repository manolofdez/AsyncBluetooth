// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "AsyncBluetooth",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "AsyncBluetooth",
            targets: ["AsyncBluetooth"]
        ),
    ],
    targets: [
        .target(
            name: "AsyncBluetooth",
            path: "Sources",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "AsyncBluetoothTests",
            dependencies: ["AsyncBluetooth"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
