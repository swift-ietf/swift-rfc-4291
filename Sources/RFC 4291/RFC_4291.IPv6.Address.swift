// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// RFC_4291.IPv6.Address.swift
// swift-rfc-4291
//
// RFC 4291: IPv6 Addressing Architecture - IPv6 Address
// https://www.rfc-editor.org/rfc/rfc4291.html
//
// Defines the 128-bit IPv6 address structure

public import INCITS_4_1986

extension RFC_4291.IPv6 {
    /// IPv6 Address (RFC 4291)
    ///
    /// A 128-bit address used to identify interfaces and sets of interfaces.
    /// IPv6 addresses are represented as eight 16-bit segments.
    ///
    /// ## Storage
    ///
    /// Internally stored as eight `UInt16` values in network byte order (big-endian).
    ///
    /// ## Text Representation
    ///
    /// Text parsing and serialization are provided by RFC 5952, which defines
    /// the canonical text representation format.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create from segments
    /// let address = RFC_4291.IPv6.Address(
    ///     0x2001, 0x0db8, 0x0000, 0x0000,
    ///     0x0000, 0x0000, 0x0000, 0x0001
    /// )
    ///
    /// // Access segments
    /// let segments = address.segments
    /// ```
    public struct Address: Sendable {
        /// The eight 16-bit segments of the address in network byte order
        public let segments: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)

        /// The raw string representation of the address
        public var rawValue: String {
            String(decoding: [UInt8](self), as: UTF8.self)
        }

        /// Creates an IPv6 address from eight 16-bit segments
        ///
        /// - Parameters:
        ///   - s0: First segment (most significant)
        ///   - s1: Second segment
        ///   - s2: Third segment
        ///   - s3: Fourth segment
        ///   - s4: Fifth segment
        ///   - s5: Sixth segment
        ///   - s6: Seventh segment
        ///   - s7: Eighth segment (least significant)
        ///
        /// ## Example
        ///
        /// ```swift
        /// // 2001:db8::1
        /// let address = RFC_4291.IPv6.Address(
        ///     0x2001, 0x0db8, 0x0000, 0x0000,
        ///     0x0000, 0x0000, 0x0000, 0x0001
        /// )
        /// ```
        public init(
            _ s0: UInt16, _ s1: UInt16, _ s2: UInt16, _ s3: UInt16,
            _ s4: UInt16, _ s5: UInt16, _ s6: UInt16, _ s7: UInt16
        ) {
            self.segments = (s0, s1, s2, s3, s4, s5, s6, s7)
        }

        /// Creates IPv6 address WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(
            __unchecked: Void,
            _ s0: UInt16, _ s1: UInt16, _ s2: UInt16, _ s3: UInt16,
            _ s4: UInt16, _ s5: UInt16, _ s6: UInt16, _ s7: UInt16
        ) {
            self.segments = (s0, s1, s2, s3, s4, s5, s6, s7)
        }
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_4291.IPv6.Address: UInt8.ASCII.Serializable {
    static public func serialize<Buffer>(
        ascii address: RFC_4291.IPv6.Address,
        into buffer: inout Buffer
    ) where Buffer : RangeReplaceableCollection, Buffer.Element == UInt8 {
        // Convert segments to array for easier processing
        let segments = [
            address.segments.0, address.segments.1, address.segments.2, address.segments.3,
            address.segments.4, address.segments.5, address.segments.6, address.segments.7
        ]

        // Find longest run of consecutive zeros for compression (RFC 5952 Section 4.2.2)
        var longestZeroRun: (start: Int, length: Int) = (0, 0)
        var currentZeroRun: (start: Int, length: Int) = (0, 0)
        var inZeroRun = false

        for (index, segment) in segments.enumerated() {
            if segment == 0 {
                if !inZeroRun {
                    currentZeroRun = (index, 1)
                    inZeroRun = true
                } else {
                    currentZeroRun.length += 1
                }

                if currentZeroRun.length > longestZeroRun.length {
                    longestZeroRun = currentZeroRun
                }
            } else {
                inZeroRun = false
            }
        }

        // Only compress if we have at least 2 consecutive zeros
        let shouldCompress = longestZeroRun.length >= 2

        buffer.reserveCapacity(39) // Max length: 8 segments * 4 hex + 7 colons

        for (index, segment) in segments.enumerated() {
            // Handle compression
            if shouldCompress && index >= longestZeroRun.start && index < longestZeroRun.start + longestZeroRun.length {
                if index == longestZeroRun.start {
                    // Output :: for compression
                    // When index > 0: first colon is separator, second is start of ::
                    //   fe80::1 → "fe80" + ":" + ":" + "1"
                    // When index == 0: both colons are the ::
                    //   ::1 → ":" + ":" + "1"
                    //   :: → ":" + ":"
                    buffer.append(.ascii.colon)
                    buffer.append(.ascii.colon)
                }
                continue
            }

            // Add colon separator (except before first segment and after ::)
            if index > 0 {
                let afterCompression = shouldCompress && index == longestZeroRun.start + longestZeroRun.length
                if !afterCompression {
                    buffer.append(.ascii.colon)
                }
            }

            // Convert segment to hex (lowercase, no leading zeros per RFC 5952)
            let hexString = String(segment, radix: 16, uppercase: false)
            buffer.append(contentsOf: hexString.utf8)
        }
    }

    /// Creates an IPv6 address from ASCII bytes
    ///
    /// Parses IPv6 addresses in the text representation format defined by RFC 4291 Section 2.2
    /// and RFC 5952 (canonical representation).
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_4291.IPv6.Address (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [UInt8] (UTF-8) → Address
    /// ```
    ///
    /// ## Format
    ///
    /// IPv6 addresses are represented as eight 16-bit hexadecimal segments separated by colons:
    /// - Full form: `2001:0db8:0000:0000:0000:0000:0000:0001`
    /// - Compressed form: `2001:db8::1` (using `::` to represent consecutive zero segments)
    ///
    /// ## Constraints
    ///
    /// Per RFC 4291 Section 2.2:
    /// - Eight 16-bit segments separated by colons
    /// - Each segment is 1-4 hexadecimal digits
    /// - `::` may be used once to compress consecutive zero segments
    ///
    /// ## Example
    ///
    /// ```swift
    /// let addr = try RFC_4291.IPv6.Address(ascii: "2001:db8::1".utf8, in: ())
    /// ```
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Context) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let input = String(decoding: bytes, as: UTF8.self)

        // Check for :: compression
        var compressionIndex: Int? = nil
        var searchIndex = bytes.startIndex
        var colonCount = 0

        while searchIndex < bytes.endIndex {
            if bytes[searchIndex] == .ascii.colon {
                colonCount += 1
                if colonCount == 2 {
                    // Found ::
                    if compressionIndex != nil {
                        throw Error.multipleCompressions(input)
                    }
                    compressionIndex = 0 // Will be calculated based on segments before ::
                }
            } else {
                colonCount = 0
            }
            searchIndex = bytes.index(after: searchIndex)
        }

        // Split into parts by colon
        var parts: [[UInt8]] = []
        var currentStart = bytes.startIndex

        for index in bytes.indices {
            if bytes[index] == .ascii.colon {
                if index > currentStart {
                    parts.append(Array(bytes[currentStart..<index]))
                } else if index == currentStart && compressionIndex != nil {
                    // Empty part before or after ::
                    parts.append([])
                }
                currentStart = bytes.index(after: index)
            }
        }

        // Add final part if not ending with colon
        if currentStart < bytes.endIndex {
            parts.append(Array(bytes[currentStart...]))
        }

        // Parse segments
        var segments: [UInt16] = []

        for part in parts {
            if part.isEmpty {
                // This is where :: compression occurs
                if compressionIndex == nil {
                    compressionIndex = segments.count
                }
                continue
            }

            // Parse hex segment (1-4 digits)
            if part.count > 4 {
                throw Error.invalidSegment(String(decoding: part, as: UTF8.self))
            }

            var value: UInt16 = 0
            for byte in part {
                let digit: UInt16
                if byte >= .ascii.`0` && byte <= .ascii.`9` {
                    digit = UInt16(byte - .ascii.`0`)
                } else if byte >= .ascii.A && byte <= .ascii.F {
                    digit = UInt16(byte - .ascii.A + 10)
                } else if byte >= .ascii.a && byte <= .ascii.f {
                    digit = UInt16(byte - .ascii.a + 10)
                } else {
                    throw Error.invalidCharacter(input, byte: byte)
                }
                value = value * 16 + digit
            }
            segments.append(value)
        }

        // Handle compression
        if let compIndex = compressionIndex {
            let zerosNeeded = 8 - segments.count
            if zerosNeeded < 0 {
                throw Error.tooManySegments(input)
            }

            // Insert zeros at compression point
            let before = segments[0..<compIndex]
            let after = segments[compIndex...]
            let zeros = Array(repeating: UInt16(0), count: zerosNeeded)
            segments = Array(before) + zeros + Array(after)
        }

        // Validate we have exactly 8 segments
        guard segments.count == 8 else {
            if segments.count < 8 {
                throw Error.tooFewSegments(input)
            } else {
                throw Error.tooManySegments(input)
            }
        }

        self.init(
            __unchecked: (),
            segments[0], segments[1], segments[2], segments[3],
            segments[4], segments[5], segments[6], segments[7]
        )
    }
}


// MARK: - Required Conformances

extension RFC_4291.IPv6.Address: UInt8.ASCII.RawRepresentable {}
extension RFC_4291.IPv6.Address: CustomStringConvertible {}

// MARK: - Equatable & Hashable

extension RFC_4291.IPv6.Address: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.segments.0 == rhs.segments.0 &&
        lhs.segments.1 == rhs.segments.1 &&
        lhs.segments.2 == rhs.segments.2 &&
        lhs.segments.3 == rhs.segments.3 &&
        lhs.segments.4 == rhs.segments.4 &&
        lhs.segments.5 == rhs.segments.5 &&
        lhs.segments.6 == rhs.segments.6 &&
        lhs.segments.7 == rhs.segments.7
    }
}

extension RFC_4291.IPv6.Address: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(segments.0)
        hasher.combine(segments.1)
        hasher.combine(segments.2)
        hasher.combine(segments.3)
        hasher.combine(segments.4)
        hasher.combine(segments.5)
        hasher.combine(segments.6)
        hasher.combine(segments.7)
    }
}

// MARK: - Comparable

extension RFC_4291.IPv6.Address: Comparable {
    /// Compares two IPv6 addresses numerically
    ///
    /// Addresses are compared segment by segment from most to least significant.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let addr1 = RFC_4291.IPv6.Address(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1)
    /// let addr2 = RFC_4291.IPv6.Address(0x2001, 0xdb8, 0, 0, 0, 0, 0, 2)
    /// if addr1 < addr2 {
    ///     print("addr1 comes before addr2")
    /// }
    /// ```
    public static func < (lhs: Self, rhs: Self) -> Bool {
        // Compare segment by segment
        if lhs.segments.0 != rhs.segments.0 { return lhs.segments.0 < rhs.segments.0 }
        if lhs.segments.1 != rhs.segments.1 { return lhs.segments.1 < rhs.segments.1 }
        if lhs.segments.2 != rhs.segments.2 { return lhs.segments.2 < rhs.segments.2 }
        if lhs.segments.3 != rhs.segments.3 { return lhs.segments.3 < rhs.segments.3 }
        if lhs.segments.4 != rhs.segments.4 { return lhs.segments.4 < rhs.segments.4 }
        if lhs.segments.5 != rhs.segments.5 { return lhs.segments.5 < rhs.segments.5 }
        if lhs.segments.6 != rhs.segments.6 { return lhs.segments.6 < rhs.segments.6 }
        return lhs.segments.7 < rhs.segments.7
    }
}

// MARK: - Codable

extension RFC_4291.IPv6.Address: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do {
            try self.init(ascii: string.utf8, in: ())
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid IPv6 address: \(error)"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}


// MARK: - Address Types (RFC 4291 Section 2.4)

extension RFC_4291.IPv6.Address {
    /// Whether this is the unspecified address (::)
    ///
    /// RFC 4291 Section 2.5.2: The address 0:0:0:0:0:0:0:0 is called the unspecified address.
    /// It indicates the absence of an address.
    public var isUnspecified: Bool {
        self == .unspecified
    }

    /// Whether this is the loopback address (::1)
    ///
    /// RFC 4291 Section 2.5.3: The loopback address 0:0:0:0:0:0:0:1 is used by a node
    /// to send an IPv6 packet to itself.
    public var isLoopback: Bool {
        self == .loopback
    }

    /// Whether this is a multicast address (ff00::/8)
    ///
    /// RFC 4291 Section 2.7: An IPv6 multicast address is an identifier for a group of interfaces.
    /// Multicast addresses have the format ff00::/8.
    public var isMulticast: Bool {
        (segments.0 & 0xFF00) == 0xFF00
    }

    /// Whether this is a link-local unicast address (fe80::/10)
    ///
    /// RFC 4291 Section 2.5.6: Link-local addresses are for use on a single link.
    /// They have the format fe80::/10.
    public var isLinkLocal: Bool {
        (segments.0 & 0xFFC0) == 0xFE80
    }

    /// Whether this is a unique local address (fc00::/7)
    ///
    /// RFC 4193: Unique Local IPv6 Unicast Addresses
    /// These addresses are not expected to be routable on the global Internet.
    public var isUniqueLocal: Bool {
        (segments.0 & 0xFE00) == 0xFC00
    }

    /// Whether this is a global unicast address
    ///
    /// RFC 4291 Section 2.5.4: Global unicast addresses are identified by
    /// the format prefix 001 (binary), but in practice this includes all
    /// addresses not otherwise classified.
    public var isGlobalUnicast: Bool {
        !isUnspecified && !isLoopback && !isMulticast && !isLinkLocal && !isUniqueLocal
    }
}

// MARK: - Well-Known Addresses

extension RFC_4291.IPv6.Address {
    /// The unspecified address (::)
    ///
    /// RFC 4291 Section 2.5.2
    public static let unspecified = Self(__unchecked: (), 0, 0, 0, 0, 0, 0, 0, 0)

    /// The loopback address (::1)
    ///
    /// RFC 4291 Section 2.5.3
    public static let loopback = Self(__unchecked: (), 0, 0, 0, 0, 0, 0, 0, 1)
}



