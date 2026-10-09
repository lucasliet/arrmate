// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "apple_foundation_models",
  platforms: [
    .iOS("15.0"),
    .macOS("10.15"),
  ],
  products: [
    .library(name: "apple-foundation-models", targets: ["apple_foundation_models"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "apple_foundation_models",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
