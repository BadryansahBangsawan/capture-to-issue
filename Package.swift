// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CaptureToIssue",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CaptureToIssue", targets: ["CaptureToIssue"])
    ],
    targets: [
        .executableTarget(name: "CaptureToIssue", path: "Sources")
    ]
)
