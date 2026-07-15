// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonGround",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "CommonGroundCore", targets: ["CommonGroundCore"]),
        .library(name: "CommonGroundDesign", targets: ["CommonGroundDesign"]),
        .library(name: "CommonGroundFeatures", targets: ["CommonGroundFeatures"]),
    ],
    targets: [
        .target(
            name: "CommonGroundCore",
            dependencies: [],
            path: "Packages/CommonGroundCore/Sources",
            resources: [.process("Localization/L10nCatalog.json")]
        ),
        .target(
            name: "CommonGroundDesign",
            dependencies: ["CommonGroundCore"],
            path: "Packages/CommonGroundDesign/Sources"
        ),
        .target(
            name: "CommonGroundFeatures",
            dependencies: ["CommonGroundCore", "CommonGroundDesign"],
            path: "Packages/CommonGroundFeatures/Sources"
        ),
        .testTarget(
            name: "CommonGroundCoreTests",
            dependencies: ["CommonGroundCore"],
            path: "Tests/CommonGroundCoreTests"
        ),
        .testTarget(
            name: "CommonGroundFeaturesTests",
            dependencies: ["CommonGroundFeatures", "CommonGroundCore"],
            path: "Tests/CommonGroundFeaturesTests"
        ),
    ]
)
