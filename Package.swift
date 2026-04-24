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
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AdRevenueClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "AdRevenueClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
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
