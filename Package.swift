// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "5.0.0"
let checksum = ""

let fp_version = "4.1.0"
let fp_checksum = "c78d0de3d8a234c1b16a1ce0e1caa2c54cc297ddf12be8fb7eb1f54fee01fbe5"

let package = Package(
    name: "NeuroID",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "NeuroID",
            targets: ["NeuroID", "Fingerprint"]
        ),
    ],
    targets: [
        // .binaryTarget(
        //     name: "NeuroID",
        //     path: "Sources/NeuroID.xcframework"
        // ),
       .binaryTarget(
           name: "NeuroID",
           url: "https://scripts.neuro-dev.com/ios/\(version)/NeuroID-\(version)-\(checksum).xcframework.zip",
           checksum: checksum
       ),
        .binaryTarget(
            name: "Fingerprint",
            url: "https://fpjs-public.s3.amazonaws.com/ios/\(fp_version)/Fingerprint-\(fp_version)-\(fp_checksum).xcframework.zip",
            checksum: fp_checksum
        )
    ]
)
