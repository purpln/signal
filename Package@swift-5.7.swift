// swift-tools-version: 5.7

import PackageDescription

let package = Package(name: "Signal", products: [
    .library(name: "Signal", targets: ["Signal"]),
], dependencies: [
    .package(url: "https://github.com/purpln/tinyfoundation.git", branch: "main"),
], targets: [
    .target(name: "Signal", dependencies: [
        .product(name: "TinyFoundation", package: "tinyfoundation"),
    ]),
])
