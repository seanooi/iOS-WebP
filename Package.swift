// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

 let package = Package(
    name: "iOSWebP",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "iOSWebP",
            targets: ["iOSWebP"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/libwebp-Xcode.git", from: .init(1, 2, 4))
    ],
    targets: [
        .target(
            name: "iOSWebP",
            path: "iOS-WebP",
            sources: [""],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("")
            ]
        ),
    ]
 )
