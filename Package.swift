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
        .package(name: "FingerprintPro", url: "https://github.com/fingerprintjs/fingerprintjs-pro-ios", from: "2.7.0")

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
        )
    ]
)
