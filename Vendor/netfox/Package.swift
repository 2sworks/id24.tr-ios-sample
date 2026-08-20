// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "netfox",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "netfox",
            targets: ["netfox"]
        ),
    ],
    targets: [
        .target(name: "netfox", path: "netfox/")
    ],
    swiftLanguageVersions: [.v5]
)
