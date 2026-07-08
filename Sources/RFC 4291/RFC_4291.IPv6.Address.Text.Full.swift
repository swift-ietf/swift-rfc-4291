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

// RFC_4291.IPv6.Address.Text.Full.swift
// swift-rfc-4291
//
// [FAM-012] text VARIANT witness value: the RFC 4291 §2.2 fully-expanded form.

public import ASCII_Serializer_Primitives

extension RFC_4291.IPv6.Address.Text {
    /// The fully-expanded IPv6 text form (RFC 4291 §2.2 preferred form, no
    /// compression): eight zero-padded four-digit lowercase-hex groups, e.g.
    /// `2001:0db8:0000:0000:0000:0000:0000:0001`.
    ///
    /// A leaf `Serializer.\`Protocol\`` witness VALUE ([FAM-005]) — not a
    /// sibling, not a runtime enum. Obtain it as `.full` and pass it to
    /// `RFC_4291.IPv6.Address.serialize(_:into:serializer:)`.
    public struct Full: Serializer.`Protocol` {
        public init() {}
    }
}

extension RFC_4291.IPv6.Address.Text.Full {
    public typealias Output = RFC_4291.IPv6.Address
    public typealias Buffer = [ASCII.Code]
    public typealias Failure = Never
    public typealias Body = Never

    public borrowing func serialize(
        _ address: RFC_4291.IPv6.Address,
        into buffer: inout [ASCII.Code]
    ) {
        let segments: [UInt16] = [
            address.segments.0, address.segments.1, address.segments.2, address.segments.3,
            address.segments.4, address.segments.5, address.segments.6, address.segments.7,
        ]
        buffer.reserveCapacity(39)

        for (index, segment) in segments.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.colon)
            }
            // Exactly four lowercase-hex digits, zero-padded (no §4.1 suppression).
            var shift: UInt16 = 12
            while true {
                let nibble = UInt8((segment >> shift) & 0xF)
                let code =
                    nibble < 10
                    ? ASCII.Code(ASCII.Code.`0`.underlying &+ nibble)
                    : ASCII.Code(ASCII.Code.a.underlying &+ (nibble &- 10))
                buffer.append(code)
                if shift == 0 { break }
                shift &-= 4
            }
        }
    }
}

// MARK: - Witness value (`.full`)

extension Serializer.`Protocol` where Self == RFC_4291.IPv6.Address.Text.Full {
    /// The fully-expanded IPv6 text variant witness value (RFC 4291 §2.2).
    public static var full: RFC_4291.IPv6.Address.Text.Full { .init() }
}
