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
    targets: [
        .target(name: "ForecastFeatureImpl"),
        .target(
            name: "ForecastFeatureAPI",
            dependencies: ["ForecastFeatureImpl"]
        ),
        .testTarget(
            name: "ForecastFeatureTests",
            dependencies: ["ForecastFeatureAPI"]
        ),
    ]
)
