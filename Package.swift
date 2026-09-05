// swift-tools-version: 6.0

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

for target in package.targets {
    guard ![.system, .plugin].contains(target.type) else { continue }
    
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings? += [
        //swift 6
        .enableUpcomingFeature("StrictConcurrency"),
        
        //swift 7
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
    ]
}
