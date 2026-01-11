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
        .package(path: "../swift-incits-4-1986"),
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
    ],
    targets: [
        .target(
            name: .rfc4291,
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
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
