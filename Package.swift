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
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc4291, targets: [.rfc4291]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.5.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: .rfc4291,
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "Standards", package: "swift-standards"),
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
