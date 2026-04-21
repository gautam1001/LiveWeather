// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WeatherHomeFeature",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "WeatherHomeFeatureAPI",
            targets: ["WeatherHomeFeatureAPI"]
        ),
        .library(
            name: "WeatherHomeFeatureImpl",
            targets: ["WeatherHomeFeatureImpl"]
        ),
    ],
    dependencies: [
        .package(path: "../CurrentWeatherFeature"),
        .package(path: "../ForecastFeature"),
        .package(path: "../SearchFeature"),
    ],
    targets: [
        .target(
            name: "WeatherHomeFeatureAPI",
            dependencies: [
                .product(name: "CurrentWeatherFeatureAPI", package: "CurrentWeatherFeature"),
                .product(name: "ForecastFeatureAPI", package: "ForecastFeature"),
                .product(name: "SearchFeatureAPI", package: "SearchFeature"),
            ]
        ),
        .target(
            name: "WeatherHomeFeatureImpl",
            dependencies: [
                "WeatherHomeFeatureAPI",
                .product(name: "CurrentWeatherFeatureAPI", package: "CurrentWeatherFeature"),
                .product(name: "ForecastFeatureAPI", package: "ForecastFeature"),
                .product(name: "SearchFeatureAPI", package: "SearchFeature"),
            ]
        ),
        .testTarget(
            name: "WeatherHomeFeatureTests",
            dependencies: [
                "WeatherHomeFeatureAPI",
                "WeatherHomeFeatureImpl",
                .product(name: "CurrentWeatherFeatureAPI", package: "CurrentWeatherFeature"),
                .product(name: "ForecastFeatureAPI", package: "ForecastFeature"),
                .product(name: "SearchFeatureAPI", package: "SearchFeature"),
            ]
        ),
    ]
)
