// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ForecastFeature",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "ForecastFeatureAPI",
            targets: ["ForecastFeatureAPI"]
        ),
        .library(
            name: "ForecastFeatureImpl",
            targets: ["ForecastFeatureImpl"]
        ),
    ],
    dependencies: [
        .package(path: "../../Data"),
    ],
    targets: [
        .target(
            name: "ForecastFeatureImpl",
            dependencies: [
                "ForecastFeatureAPI",
                .product(name: "Data", package: "Data"),
            ]
        ),
        .target(
            name: "ForecastFeatureAPI",
            dependencies: []
        ),
        .testTarget(
            name: "ForecastFeatureTests",
            dependencies: [
                "ForecastFeatureAPI",
                "ForecastFeatureImpl",
            ]
        ),
    ]
)
