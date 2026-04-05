// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SearchFeature",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SearchFeatureAPI",
            targets: ["SearchFeatureAPI"]
        ),
        .library(
            name: "SearchFeatureImpl",
            targets: ["SearchFeatureImpl"]
        ),
    ],
    targets: [
        .target(name: "SearchFeatureImpl"),
        .target(
            name: "SearchFeatureAPI",
            dependencies: ["SearchFeatureImpl"]
        ),
        .testTarget(
            name: "SearchFeatureTests",
            dependencies: ["SearchFeatureAPI"]
        ),
    ]
)
