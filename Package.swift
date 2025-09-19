// swift-tools-version:5.3
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
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(name: "FingerprintPro", url: "https://github.com/fingerprintjs/fingerprintjs-pro-ios", from: "2.10.0"),
        .package(name:"DSJSONSchemaValidation", url: "https://github.com/dashpay/JSONSchemaValidation", from: "2.0.7"),
        .package(name: "JSONSchema", url:"https://github.com/kylef/JSONSchema.swift", from:"0.6.0")

    ],
    targets: [
        .target(
            name: "NeuroID",
            dependencies: ["Alamofire", "FingerprintPro"],
            path: "Source/NeuroID",
            exclude: [
               
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "NeuroIDTests",
            dependencies: ["NeuroID", "DSJSONSchemaValidation", "JSONSchema"],
            path: "SDKTest"
        )
    ]
)
