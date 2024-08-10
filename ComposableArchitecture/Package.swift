// swift-tools-version: 5.4

import PackageDescription

let package = Package (
  name: "StateManagement",
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-enum-properties.git",
      from: "0.1.0"
    )
  ]
)
