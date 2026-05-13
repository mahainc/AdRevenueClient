// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AdRevenueClient",
    platforms: [
        .iOS(.v16), .macOS(.v13)
    ],
    products: [
        .singleTargetLibrary("AdRevenueClient"),
        .singleTargetLibrary("AdRevenueClientLive"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "AdRevenueClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
            ]
        ),
        .target(
            name: "AdRevenueClientLive",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                "AdRevenueClient",
            ]
        ),
        .testTarget(
            name: "AdRevenueClientTests",
            dependencies: ["AdRevenueClient", "AdRevenueClientLive"]
        ),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
