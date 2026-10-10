// swift-tools-version: 6.1

import PackageDescription

/// The `Funnel` trait's name, shared by its declaration below and by every product
/// condition that gates on it. The matching `#if Funnel` in the conformer cannot
/// reference this — a compiler condition is not a Swift expression — but these two
/// manifest-level uses can, and a typo in either would silently stop gating.
let funnelTrait = "Funnel"

/// Both targets build on the same dependency trio; the Live target adds FunnelClient on
/// top when the `Funnel` trait is on.
let sharedDependencies: [Target.Dependency] = [
    .product(name: "Dependencies", package: "swift-dependencies"),
    .product(name: "DependenciesMacros", package: "swift-dependencies"),
    .product(name: "CasePaths", package: "swift-case-paths"),
]

let package = Package(
    name: "AdRevenueClient",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .singleTargetLibrary("AdRevenueClient"),
        .singleTargetLibrary("AdRevenueClientLive"),
    ],
    // The funnel conformer is opt-in. This package's own dependencies are two
    // small pointfree libraries; FunnelClient drags in flow-kit, TCA, PopupView,
    // swift-protobuf and LogClient, so a consumer that only calls `publish(_:)`
    // was paying an 18-package graph for a 2-package client. `#if
    // canImport(FunnelClient)` cannot do this: it is evaluated after resolution,
    // so the dependency is already fetched and built by the time the compiler
    // sees it. A trait gates the edge itself.
    //
    // Off by default, so adding this package never widens a graph by surprise:
    //   .package(url: "…/AdRevenueClient.git", from: "4.2.0")                  // no funnel
    //   .package(url: "…/AdRevenueClient.git", from: "4.2.0", traits: ["Funnel"])
    traits: [
        .default(enabledTraits: ["Funnel"]),
        Trait(
            name: funnelTrait,
            description: "Conform AdRevenueClient to FunnelClient's AdRevenue port."
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "1.5.0"),
        .package(url: "https://github.com/mahainc/FunnelClient.git", from: "9.0.0"),
    ],
    targets: [
        .target(
            name: "AdRevenueClient",
            dependencies: sharedDependencies
        ),
        // The only target that knows FunnelClient exists, and only when the
        // `Funnel` trait is on. AdRevenueClient itself stays a plain pub/sub
        // seam any consumer can use without the funnel.
        .target(
            name: "AdRevenueClientLive",
            dependencies: sharedDependencies + [
                .product(
                    name: "FunnelClient",
                    package: "FunnelClient",
                    condition: .when(traits: [funnelTrait])
                ),
                "AdRevenueClient",
            ]
        ),
        // The funnel conformance tests live in their own file behind `#if Funnel`,
        // so this target builds with the trait off. FunnelClient reaches it
        // transitively through AdRevenueClientLive when the trait is on.
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
