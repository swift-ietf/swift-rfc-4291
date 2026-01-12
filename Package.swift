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
        .library(name: .rfc4291, targets: [.rfc4291]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-ascii.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc4291,
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
            ]
        ),
        .testTarget(
            name: .rfc4291.tests,
            dependencies: [.rfc4291]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
