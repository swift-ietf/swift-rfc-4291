// swift-tools-version: 6.2
import PackageDescription

extension String {
    static let rfc4291 = "RFC 4291"
    var tests: Self { "\(self) Tests" }
}

extension Target.Dependency {
    static let rfc4291 = Self.target(name: .rfc4291)
}

let package = Package(
    name: "swift-rfc-4291",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 4291", targets: ["RFC 4291"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-ascii-serializer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-serializer-primitives.git", branch: "main")
    ],
    targets: [
        .target(
            name: "RFC 4291",
            dependencies: [
                .product(name: "ASCII Serializer Primitives", package: "swift-ascii-serializer-primitives"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Binary Serializable Primitives", package: "swift-binary-serializer-primitives")
            ]
        ),
        .testTarget(
            name: "RFC 4291 Tests",
            dependencies: [
                "RFC 4291",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
