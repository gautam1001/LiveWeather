// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppComposition",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "AppComposition",
            targets: ["AppComposition"]
        ),
    ],
    dependencies: [
        .package(path: "../Features/CurrentWeatherFeature"),
        .package(path: "../Features/ForecastFeature"),
        .package(path: "../Features/SearchFeature"),
        .package(path: "../Features/WeatherHomeFeature"),
    ],
    targets: [
        .target(
            name: "AppComposition",
            dependencies: [
                .product(name: "CurrentWeatherFeatureAPI", package: "CurrentWeatherFeature"),
                .product(name: "CurrentWeatherFeatureImpl", package: "CurrentWeatherFeature"),
                .product(name: "ForecastFeatureAPI", package: "ForecastFeature"),
                .product(name: "ForecastFeatureImpl", package: "ForecastFeature"),
                .product(name: "SearchFeatureAPI", package: "SearchFeature"),
                .product(name: "SearchFeatureImpl", package: "SearchFeature"),
                .product(name: "WeatherHomeFeatureAPI", package: "WeatherHomeFeature"),
                .product(name: "WeatherHomeFeatureImpl", package: "WeatherHomeFeature"),
            ]
        ),
    ]
)
