// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "steadpay-swift",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "Steadpay", targets: ["Steadpay"]),
        .library(name: "SteadpayUI", targets: ["SteadpayUI"]),
    ],
    targets: [
        .target(name: "Steadpay", path: "Sources/Steadpay"),
        .target(name: "SteadpayUI", dependencies: ["Steadpay"], path: "Sources/SteadpayUI"),
        .testTarget(name: "SteadpayTests", dependencies: ["Steadpay"], path: "Tests/SteadpayTests"),
        .testTarget(name: "SteadpayUITests", dependencies: ["SteadpayUI"], path: "Tests/SteadpayUITests"),
    ]
)
