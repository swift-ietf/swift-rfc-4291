# swift-rfc-4291

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

IPv6 address types, text representation, and scopes of RFC 4291.

## Standard Reference

- **RFC**: 4291
- **Title**: IP Version 6 Addressing Architecture

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-4291.git", from: "0.2.0")
]
```

Add the product to a target that needs it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 4291", package: "swift-rfc-4291")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
