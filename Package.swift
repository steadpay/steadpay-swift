// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "gatlio-swift",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "Gatlio", targets: ["Gatlio"]),
        .library(name: "GatlioUI", targets: ["GatlioUI"]),
    ],
    targets: [
        .target(name: "Gatlio", path: "Sources/Gatlio"),
        .target(name: "GatlioUI", dependencies: ["Gatlio"], path: "Sources/GatlioUI"),
        .testTarget(name: "GatlioTests", dependencies: ["Gatlio"], path: "Tests/GatlioTests"),
        .testTarget(name: "GatlioUITests", dependencies: ["GatlioUI"], path: "Tests/GatlioUITests"),
    ]
)
