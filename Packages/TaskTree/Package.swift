// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaskTree",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.1.5"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation", exact: "1.2.0"),
        .package(url: "https://github.com/Ryu0118/swift-fullscreen-popup", exact: "0.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppFeature",
            dependencies: [
                "TodoClient",
                "Utils",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
                .product(name: "FullscreenPopup", package: "swift-fullscreen-popup"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SwiftDataModel"
        ),
        .target(
            name: "SwiftDataUtils"
        ),
        .target(
            name: "TodoClient",
            dependencies: [
                "SwiftDataModel",
                "SwiftDataUtils",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "Utils",
            dependencies: [
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            ],
            resources: [
                .process("Resources")
            ]
        ),

        .testTarget(
            name: "TaskTreeTests",
            dependencies: ["AppFeature"]
        ),
    ]
)
