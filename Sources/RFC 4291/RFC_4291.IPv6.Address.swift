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
// Defines the 128-bit IPv6 address structure.

// `Parseable_ASCII_Primitives` / `Binary_Parseable_Primitives` re-export a
// `Collection` / buffer-protocol family that shadows the stdlib protocols within
// this file's scope. Every collection-protocol reference below is therefore
// `Swift.`-qualified so the shadow is harmless — qualify the name, don't isolate
// the conformance into a separate file (principal directive; the file-scoped
// import shadows only here). Same load-bearing re-export as IPv4.Address:306.
// `Parseable_ASCII_Primitives` also re-exports `ASCII_Primitives` (`ASCII.Code`).
public import Parseable_ASCII_Primitives
public import Binary_Parseable_Primitives

extension RFC_4291.IPv6 {
    /// IPv6 Address (RFC 4291)
    ///
    /// A 128-bit address used to identify interfaces and sets of interfaces.
    /// IPv6 addresses are represented as eight 16-bit segments.
    ///
    /// ## Storage
    ///
    /// Internally stored as eight `UInt16` values in host byte order (each
    /// segment as the integer it appears to be — `0x2001` is stored as the
    /// integer `0x2001`, regardless of host endianness). Network-order bytes
    /// are produced by `Binary.Serializable.serialize(_:into:)` at
    /// serialization boundaries, not at the storage layer.
    ///
    /// ## Representations ([FAM-012] format siblings)
    ///
    /// This package (RFC 4291) owns the address value, its **wire** form
    /// (`Binary.Serializable` / `Binary.Parseable`, 16 network-order bytes), and
    /// the RFC 4291 §2.2 **text grammar** (`ASCII.Parseable` — `init(ascii:)`
    /// accepts any §2.2 text form, including the RFC 5952 canonical form). The
    /// RFC 4291 §2.2 non-default text *serializations* — the fully-expanded
    /// (§2.2.1) and IPv4-mixed (§2.2.3) forms — are `Serializer.\`Protocol\``
    /// **witness values** (`RFC_4291.IPv6.Address.Text.Full` / `.IPv4Mixed`)
    /// passed to `serialize(_:into:serializer:)`.
    ///
    /// The **RFC 5952 canonical** text serialization (the default text form,
    /// `description`, `rawValue`, `Codable`) is defined by a *different spec* and
    /// therefore lives in `swift-rfc-5952` as a retroactive conformance
    /// ([FAM-009] namespace-rooted placement / spec-mirroring). `ASCII.Parseable`
    /// deliberately has no `ASCII.Serializable` peer here: the two [FAM-012]
    /// siblings are independent — RFC 4291 owns the grammar (parse), RFC 5952
    /// owns the canonical choice (serialize).
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
    /// let wire: [Byte] = address.bytes   // 16 network-order bytes
    /// // Canonical "2001:db8::1" text requires `import RFC_5952`.
    /// ```
    public struct Address: Sendable {
        /// The eight 16-bit segments of the address in host byte order.
        ///
        /// Each segment is the integer it appears to be in the text
        /// representation — `0x2001` is stored as the integer `0x2001`,
        /// regardless of host endianness. Network-order bytes are produced by
        /// `Binary.Serializable.serialize(_:into:)` at the serialization
        /// boundary.
        public let segments: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)

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
            _ s0: UInt16,
            _ s1: UInt16,
            _ s2: UInt16,
            _ s3: UInt16,
            _ s4: UInt16,
            _ s5: UInt16,
            _ s6: UInt16,
            _ s7: UInt16
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
            _ s0: UInt16,
            _ s1: UInt16,
            _ s2: UInt16,
            _ s3: UInt16,
            _ s4: UInt16,
            _ s5: UInt16,
            _ s6: UInt16,
            _ s7: UInt16
        ) {
            self.segments = (s0, s1, s2, s3, s4, s5, s6, s7)
        }
    }
}

// MARK: - Binary.Serializable Conformance (16-byte wire — network byte order)

extension RFC_4291.IPv6.Address: Binary.Serializable {
    public static func serialize<Buffer>(
        _ address: RFC_4291.IPv6.Address,
        into buffer: inout Buffer
    ) where Buffer: Swift.RangeReplaceableCollection, Buffer.Element == Byte {
        let s = address.segments
        // Network byte order (big-endian): UInt16 segments serialize via the
        // Byte-primary BinaryInteger.bytes(endianness:) — returns [Byte].
        buffer.append(contentsOf: s.0.bytes(endianness: .big))
        buffer.append(contentsOf: s.1.bytes(endianness: .big))
        buffer.append(contentsOf: s.2.bytes(endianness: .big))
        buffer.append(contentsOf: s.3.bytes(endianness: .big))
        buffer.append(contentsOf: s.4.bytes(endianness: .big))
        buffer.append(contentsOf: s.5.bytes(endianness: .big))
        buffer.append(contentsOf: s.6.bytes(endianness: .big))
        buffer.append(contentsOf: s.7.bytes(endianness: .big))
    }

    /// Creates an IPv6 address from 16 binary bytes in network byte order
    ///
    /// - Parameter bytes: Exactly 16 bytes in network byte order (big-endian)
    /// - Throws: `Error.invalidFormat` if not exactly 16 bytes
    public init<Bytes: Swift.Collection>(binary bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard bytes.count == 16 else {
            throw .invalidFormat("Expected 16 bytes, got \(bytes.count)")
        }
        var iterator = bytes.makeIterator()
        // UInt16 segments are arithmetic-domain; cross the byte-domain boundary
        // via .underlying at the conformance boundary.
        func next16() -> UInt16 {
            let hi = UInt16(iterator.next()!.underlying)
            let lo = UInt16(iterator.next()!.underlying)
            return (hi << 8) | lo
        }
        self.init(
            next16(), next16(), next16(), next16(),
            next16(), next16(), next16(), next16()
        )
    }
}

// MARK: - Binary.Parseable Conformance (16-octet wire — network byte order)

extension RFC_4291.IPv6.Address: Binary.Parseable {
    /// Parses a 16-octet IPv6 address from the front of `source` (network order).
    ///
    /// [FAM-012] wire sibling carrying the fixed-concrete `Binary.Parse.Failure`
    /// (minimal-B): the binary form's only structural defect is insufficient
    /// input — any sixteen bytes are a valid address. Consumes exactly sixteen
    /// bytes from the front of `source` on success (cursor semantics); leaves
    /// `source` unmodified on failure.
    public static func parse<Source>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> RFC_4291.IPv6.Address
    where Source: Swift.RangeReplaceableCollection, Source.Element == Byte {
        guard source.count >= 16 else {
            throw .insufficient(needed: 16)
        }

        var iterator = source.makeIterator()
        func next16() -> UInt16 {
            let hi = UInt16(iterator.next()!.underlying)
            let lo = UInt16(iterator.next()!.underlying)
            return (hi << 8) | lo
        }
        let s0 = next16(), s1 = next16(), s2 = next16(), s3 = next16()
        let s4 = next16(), s5 = next16(), s6 = next16(), s7 = next16()
        source.removeFirst(16)

        return RFC_4291.IPv6.Address(s0, s1, s2, s3, s4, s5, s6, s7)
    }
}

// MARK: - ASCII.Parseable Conformance (RFC 4291 §2.2 text grammar)

extension RFC_4291.IPv6.Address: ASCII.Parseable {
    public typealias Failure = RFC_4291.IPv6.Address.Error
}

extension RFC_4291.IPv6.Address {
    /// Creates an IPv6 address from ASCII bytes in RFC 4291 §2.2 text notation.
    ///
    /// [FAM-012] text-sibling canonical parse — the RFC 4291 §2.2 **grammar**.
    /// Accepts the full/preferred form and the `::`-compressed form (any valid
    /// §2.2 text, including the RFC 5952 canonical form). String parsing is
    /// derived composition: `String → [Byte] (UTF-8) → Address`.
    ///
    /// This parse verb lives in RFC 4291 because RFC 4291 §2.2 owns the text
    /// *grammar*; the RFC 5952 canonical *serialization* choice lives in
    /// `swift-rfc-5952`. The two [FAM-012] siblings are independent.
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
    /// let addr = try RFC_4291.IPv6.Address(ascii: Array<Byte>("2001:db8::1".utf8))
    /// ```
    ///
    /// - Parameter bytes: ASCII bytes representing IPv6 text notation
    /// - Throws: `Error` if the format is invalid
    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.empty }

        let input = String(decoding: bytes, as: UTF8.self)

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 4291 grammar is strict
        // ASCII; non-ASCII bytes are fail-state).
        let arr: [ASCII.Code]
        do {
            // `Swift.Array`-qualified: `Binary_Parseable_Primitives`'s
            // load-bearing re-export brings the institute `Array`
            // (Store&Buffer-constrained) into scope, shadowing the stdlib type
            // at this explicit `Array<…>` spelling. Same qualify-the-name
            // pattern as the collection-protocol references above.
            arr = try Swift.Array<ASCII.Code>(bytes)
        } catch {
            throw Error.invalidFormat(input)
        }

        // Find :: compression marker position
        var doubleColonPosition: Int? = nil
        var prevColonIndex: Int? = nil

        for index in arr.indices {
            if arr[index] == ASCII.Code.colon {
                if let prevIdx = prevColonIndex {
                    // Two consecutive colons - found ::
                    if doubleColonPosition != nil {
                        throw Error.multipleCompressions(input)
                    }
                    // Position is at the first colon of ::
                    doubleColonPosition = prevIdx
                }
                prevColonIndex = index
            } else {
                prevColonIndex = nil
            }
        }

        // Helper to parse a hex segment
        func parseSegment(_ part: Swift.ArraySlice<ASCII.Code>) throws(Error) -> UInt16 {
            guard !part.isEmpty else {
                throw Error.invalidFormat(input)
            }
            if part.count > 4 {
                throw Error.invalidSegment(String(decoding: part, as: UTF8.self))
            }

            var value: UInt16 = 0
            for code in part {
                guard let nibble = code.hexValue else {
                    throw Error.invalidCharacter(input, code: code)
                }
                value = value * 16 + UInt16(nibble)
            }
            return value
        }

        // Helper to split by colon and parse segments
        func parseSegments(_ slice: Swift.ArraySlice<ASCII.Code>) throws(Error) -> [UInt16] {
            var segments: [UInt16] = []
            var start = slice.startIndex

            for index in slice.indices {
                if slice[index] == ASCII.Code.colon {
                    if index > start {
                        let part = slice[start..<index]
                        try segments.append(parseSegment(part))
                    }
                    start = slice.index(after: index)
                }
            }

            // Handle final segment
            if start < slice.endIndex {
                let part = slice[start...]
                try segments.append(parseSegment(part))
            }

            return segments
        }

        var segments: [UInt16]

        if let dcPos = doubleColonPosition {
            // Has :: compression
            let beforeDC = arr[arr.startIndex..<dcPos]
            let afterDCStart = arr.index(dcPos, offsetBy: 2)
            let afterDC = arr[afterDCStart..<arr.endIndex]

            let beforeSegments = beforeDC.isEmpty ? [] : try parseSegments(beforeDC)
            let afterSegments = afterDC.isEmpty ? [] : try parseSegments(afterDC)

            let totalSegments = beforeSegments.count + afterSegments.count
            let zerosNeeded = 8 - totalSegments

            if zerosNeeded < 0 {
                throw Error.tooManySegments(input)
            }

            segments = beforeSegments + Swift.Array(repeating: 0, count: zerosNeeded) + afterSegments
        } else {
            // No compression - must have exactly 8 segments
            segments = try parseSegments(arr[...])
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
            segments[0],
            segments[1],
            segments[2],
            segments[3],
            segments[4],
            segments[5],
            segments[6],
            segments[7]
        )
    }
}

// MARK: - Equatable & Hashable

extension RFC_4291.IPv6.Address: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.segments.0 == rhs.segments.0 && lhs.segments.1 == rhs.segments.1
            && lhs.segments.2 == rhs.segments.2 && lhs.segments.3 == rhs.segments.3
            && lhs.segments.4 == rhs.segments.4 && lhs.segments.5 == rhs.segments.5
            && lhs.segments.6 == rhs.segments.6 && lhs.segments.7 == rhs.segments.7
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

// MARK: - Address Type Predicates (RFC 4291 Section 2.4)

extension RFC_4291.IPv6.Address {
    /// Namespace for address type predicates
    public struct Is: Sendable {
        @usableFromInline
        let address: RFC_4291.IPv6.Address

        @usableFromInline
        init(_ address: RFC_4291.IPv6.Address) {
            self.address = address
        }

        /// Whether this is the unspecified address (::)
        ///
        /// RFC 4291 Section 2.5.2: The address 0:0:0:0:0:0:0:0 is called the unspecified address.
        /// It indicates the absence of an address.
        @inlinable
        public var unspecified: Bool {
            address == .unspecified
        }

        /// Whether this is the loopback address (::1)
        ///
        /// RFC 4291 Section 2.5.3: The loopback address 0:0:0:0:0:0:0:1 is used by a node
        /// to send an IPv6 packet to itself.
        @inlinable
        public var loopback: Bool {
            address == .loopback
        }

        /// Whether this is a multicast address (ff00::/8)
        ///
        /// RFC 4291 Section 2.7: An IPv6 multicast address is an identifier for a group of interfaces.
        /// Multicast addresses have the format ff00::/8.
        @inlinable
        public var multicast: Bool {
            (address.segments.0 & 0xFF00) == 0xFF00
        }

        /// Whether this is a link-local unicast address (fe80::/10)
        ///
        /// RFC 4291 Section 2.5.6: Link-local addresses are for use on a single link.
        /// They have the format fe80::/10.
        @inlinable
        public var linkLocal: Bool {
            (address.segments.0 & 0xFFC0) == 0xFE80
        }

        /// Whether this is a unique local address (fc00::/7)
        ///
        /// RFC 4193: Unique Local IPv6 Unicast Addresses
        /// These addresses are not expected to be routable on the global Internet.
        @inlinable
        public var uniqueLocal: Bool {
            (address.segments.0 & 0xFE00) == 0xFC00
        }

        /// Whether this is a global unicast address
        ///
        /// RFC 4291 Section 2.5.4: Global unicast addresses are identified by
        /// the format prefix 001 (binary), but in practice this includes all
        /// addresses not otherwise classified.
        @inlinable
        public var globalUnicast: Bool {
            !unspecified && !loopback && !multicast && !linkLocal && !uniqueLocal
        }
    }

    /// Access address type predicates
    ///
    /// ## Example
    ///
    /// ```swift
    /// let address = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
    /// if address.is.linkLocal { ... }
    /// if address.is.multicast { ... }
    /// ```
    public var `is`: Is {
        Is(self)
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
