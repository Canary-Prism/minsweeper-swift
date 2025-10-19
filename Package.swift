// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "minsweeper-swift",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "minsweeper-swift",
            targets: ["MinsweeperSwift"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MinsweeperSwift"
        ),
        .testTarget(
            name: "MinsweeperSwiftTests",
            dependencies: ["MinsweeperSwift"]
        )
    ]
)
