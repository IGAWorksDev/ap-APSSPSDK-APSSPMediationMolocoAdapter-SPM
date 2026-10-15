// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "APSSPMediationMoloco",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "APSSPMediationMoloco", targets: ["APSSPMediationMoloco"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IGAWorksDev/ap-APSSPSDK-SPM.git", from: "3.4.0"),
        .package(url: "https://github.com/moloco/moloco-sdk-ios-spm.git", exact: "4.7.0"),
    ],
    targets: [
        .target(name: "APSSPMediationMoloco",
                dependencies: [
                    .product(name: "APSSPSDK", package: "ap-APSSPSDK-SPM"),
                    .product(name: "MolocoSDK", package: "moloco-sdk-ios-spm"),
                ],
                path: "Sources/MediationMoloco"),
    ]
)
