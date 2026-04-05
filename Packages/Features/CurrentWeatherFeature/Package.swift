// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CurrentWeatherFeature",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "CurrentWeatherFeatureAPI",
            targets: ["CurrentWeatherFeatureAPI"]
        ),
        .library(
            name: "CurrentWeatherFeatureImpl",
            targets: ["CurrentWeatherFeatureImpl"]
        ),
    ],
    dependencies: [
        .package(path: "../../Data"),
        .package(path: "../../Domain"),
        .package(path: "../../Presentation"),
    ],
    targets: [
        .target(
            name: "CurrentWeatherFeatureImpl",
            dependencies: [
                .product(name: "Data", package: "Data"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "Presentation", package: "Presentation"),
            ]
        ),
        .target(
            name: "CurrentWeatherFeatureAPI",
            dependencies: [
                "CurrentWeatherFeatureImpl",
                .product(name: "Presentation", package: "Presentation"),
            ]
        ),
        .testTarget(
            name: "CurrentWeatherFeatureTests",
            dependencies: ["CurrentWeatherFeatureAPI"]
        ),
    ]
)
