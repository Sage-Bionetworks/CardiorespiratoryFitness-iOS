// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CardiorespiratoryFitness",
    defaultLocalization: "en",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .macOS(.v10_15),
        .iOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CardiorespiratoryFitness",
            targets: ["CardiorespiratoryFitness"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "JsonModel",
                 url: "https://github.com/Sage-Bionetworks/JsonModel-Swift.git",
                 from: "1.1.0"),
        .package(name: "SageResearch",
                 url: "https://github.com/Sage-Bionetworks/SageResearch.git",
                 from: "3.18.0"),
        
    ],
    targets: [
        .target(
            name: "CardiorespiratoryFitness",
            dependencies: ["CardiorespiratoryFitnessObjC",
                           "JsonModel",
                           .product(name: "Research", package: "SageResearch"),
                           .product(name: "ResearchUI", package: "SageResearch"),
                           .product(name: "ResearchMotion", package: "SageResearch"),
            ],
            path: "CardiorespiratoryFitness/CardiorespiratoryFitness/Swift",
            resources: [
                .process("Resources"),
                .process("iOS/Resources"),
            ]),
        .target(name: "CardiorespiratoryFitnessObjC",
                dependencies: [],
                path: "CardiorespiratoryFitness/CardiorespiratoryFitness/ObjC",
                exclude: ["Info.plist"]),

        .testTarget(
            name: "CardiorespiratoryFitnessTests",
            dependencies: [
                "CardiorespiratoryFitness",
                .product(name: "Research_UnitTest", package: "SageResearch"),
            ],
            path: "CardiorespiratoryFitness/CardiorespiratoryFitnessTests/Tests",
            resources: [
                .process("Resources"),
            ]),
        
    ]
)
