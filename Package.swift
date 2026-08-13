// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "QuickDrawShortcuts",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(name: "QuickDrawCore", targets: ["QuickDrawCore"]),
    .executable(name: "QuickDrawShortcuts", targets: ["QuickDrawShortcuts"]),
  ],
  targets: [
    .target(
      name: "QuickDrawCore",
      resources: [
        .process("Resources")
      ]
    ),
    .executableTarget(
      name: "QuickDrawShortcuts",
      dependencies: ["QuickDrawCore"],
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("Carbon"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("SwiftUI"),
      ]
    ),
    .testTarget(
      name: "QuickDrawCoreTests",
      dependencies: ["QuickDrawCore", "QuickDrawShortcuts"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
