// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "QuickDrawPoC",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(name: "QuickDrawCore", targets: ["QuickDrawCore"]),
    .executable(name: "QuickDrawPoC", targets: ["QuickDrawPoC"]),
  ],
  targets: [
    .target(
      name: "QuickDrawCore"
    ),
    .executableTarget(
      name: "QuickDrawPoC",
      dependencies: ["QuickDrawCore"],
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("Carbon"),
        .linkedFramework("CoreGraphics"),
      ]
    ),
    .testTarget(
      name: "QuickDrawCoreTests",
      dependencies: ["QuickDrawCore"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
