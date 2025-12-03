// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeuroID",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "NeuroID",
            targets: ["NeuroID"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.10.2"),
        .package(url: "https://github.com/fingerprintjs/fingerprintjs-pro-ios", exact: "2.11.0"),
        .package(url: "https://github.com/dashpay/JSONSchemaValidation", from: "2.0.7"),
        .package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "NeuroID",
            dependencies: [
                .product(name: "FingerprintPro", package: "fingerprintjs-pro-ios"),
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Source/NeuroID",
            exclude: [
               
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "NeuroIDTests",
            dependencies: [
                "NeuroID",
                .product(name: "DSJSONSchemaValidation", package: "JSONSchemaValidation"),
                .product(name: "JSONSchema", package: "JSONSchema.swift")
            ],
            path: "SDKTest"
        )
    ]
)
