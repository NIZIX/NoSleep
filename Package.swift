// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "NoSleep",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NoSleep", targets: ["NoSleep"]),
        .executable(name: "NoSleepVerifier", targets: ["NoSleepVerifier"])
    ],
    targets: [
        .target(
            name: "NoSleepCore",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "NoSleep",
            dependencies: ["NoSleepCore"],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .executableTarget(
            name: "NoSleepVerifier",
            dependencies: ["NoSleepCore"]
        )
    ]
)
