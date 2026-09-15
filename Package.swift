// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "xcs",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "xcs", targets: ["xcs"]),
        .library(name: "XcsCore", targets: ["XcsCore"]),
        .library(name: "XcsConfig", targets: ["XcsConfig"]),
        .library(name: "XcsKit", targets: ["XcsKit"]),
        .library(name: "XcsCLI", targets: ["XcsCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.2"),
        .package(url: "https://github.com/Ryu0118/FileManagerProtocol", from: "0.1.0"),
        .package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.2.0"),
        .package(url: "https://github.com/tuist/FileSystem", from: "0.13.47"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "XcsCore",
            dependencies: []
        ),
        .target(
            name: "XcsConfig",
            dependencies: [
                "XcsCore",
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Glob", package: "FileSystem"),
            ]
        ),
        .target(
            name: "XcsKit",
            dependencies: [
                "XcsConfig",
                "XcsCore",
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
                .product(name: "Interaction", package: "swift-interaction"),
            ]
        ),
        .target(
            name: "XcsCLI",
            dependencies: [
                "XcsKit",
                "XcsConfig",
                "XcsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "xcs",
            dependencies: ["XcsCLI"]
        ),
        .testTarget(
            name: "XcsCoreTests",
            dependencies: ["XcsCore"]
        ),
        .testTarget(
            name: "XcsConfigTests",
            dependencies: [
                "XcsConfig",
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
                .product(name: "Yams", package: "Yams"),
            ],
            exclude: ["Fixtures"]
        ),
        .testTarget(
            name: "XcsKitTests",
            dependencies: [
                "XcsKit",
                "XcsConfig",
                "XcsCore",
                .product(name: "Interaction", package: "swift-interaction"),
            ]
        ),
        .testTarget(
            name: "XcsCLITests",
            dependencies: ["XcsCLI", "XcsKit", "XcsConfig", "XcsCore"]
        ),
    ]
)
