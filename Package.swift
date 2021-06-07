// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RedCat",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RedCat",
            targets: ["RedCat"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", .exact(Version(0, 2, 0)))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RedCat",
            dependencies: [.product(name: "CasePaths", package: "swift-case-paths")]),
        .testTarget(
            name: "RedCatTests",
            dependencies: ["RedCat"]),
    ]
)
