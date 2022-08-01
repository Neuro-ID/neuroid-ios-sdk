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
            path: "SDKTest",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "SDKUITest",
            path: "SDKUITest",
            exclude: ["Info.plist"]
        )
    ]
)
