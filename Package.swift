// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "define",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "define", targets: ["Define"])],
    targets: [
        .executableTarget(name: "Define"),
        .testTarget(name: "DefineTests", dependencies: ["Define"]),
    ]
)
