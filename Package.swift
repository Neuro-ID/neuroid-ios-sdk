// swift-tools-version:5.3
//
// Package.swift
//
// https://neuro-id.readme.io/docs/overview

import PackageDescription

let package = Package(
    name: "NeuroID",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "NeuroID",
            targets: ["NeuroID"]
        )
    ],
    dependencies: [
        .package(
            name: "Alamofire",
            url: "https://github.com/Alamofire/Alamofire.git",
            from: "5.6.0"
        ),
        .package(
            name: "JSONSchema",
            url: "https://github.com/kylef/JSONSchema.swift.git",
            from: "0.5.0"
        )
    ],
    targets: [
        .target(
            name: "NeuroID",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "NeuroID",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "SDKTest",
            dependencies: [
                "NeuroID",
                .product(name: "Alamofire", package: "Alamofire"),
                "JSONSchema"
            ],
            path: "SDKTest",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "SDKUITest",
            dependencies: [
                "NeuroID",
                .product(name: "Alamofire", package: "Alamofire"),
                "JSONSchema"
            ],
            path: "SDKUITest",
            exclude: ["Info.plist"]
        )
    ]
)
