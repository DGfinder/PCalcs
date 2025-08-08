// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PerfCalcCore",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "PerfCalcCore", targets: ["PerfCalcCore"])
    ],
    targets: [
        .target(
            name: "PerfCalcCore",
            dependencies: [],
            path: "Sources/PerfCalcCore"
        ),
        .testTarget(
            name: "PerfCalcCoreTests",
            dependencies: ["PerfCalcCore"],
            path: "Tests/PerfCalcCoreTests"
        )
    ]
)