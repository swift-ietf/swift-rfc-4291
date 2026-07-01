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

// RFC_4291.IPv6.Address.Text.IPv4Mixed.swift
// swift-rfc-4291
//
// [FAM-012] text VARIANT witness value: the RFC 4291 §2.2 IPv4-mixed form.

public import ASCII_Serializer_Primitives

extension RFC_4291.IPv6.Address.Text {
    /// The IPv4-mixed IPv6 text form (RFC 4291 §2.2 third form): the six leading
    /// 16-bit groups in lowercase hex, then the trailing 32 bits as dotted-
    /// decimal IPv4, e.g. `0:0:0:0:0:ffff:192.168.1.1`.
    ///
    /// A leaf `Serializer.\`Protocol\`` witness VALUE ([FAM-005]) — not a
    /// sibling, not a runtime enum. Obtain it as `.ipv4Mixed` and pass it to
    /// `RFC_4291.IPv6.Address.serialize(_:into:serializer:)`.
    ///
    /// > Note (template scope): this witness emits the leading six groups
    /// > **uncompressed** (no RFC 5952 §5 `::`). The `::`-compressed mixed form
    /// > is a refinement orthogonal to the witness-value mechanism this template
    /// > demonstrates.
    public struct IPv4Mixed: Serializer.`Protocol` {
        public typealias Output = RFC_4291.IPv6.Address
        public typealias Buffer = [ASCII.Code]
        public typealias Failure = Never
        public typealias Body = Never

        public init() {}

        public borrowing func serialize(
            _ address: RFC_4291.IPv6.Address,
            into buffer: inout [ASCII.Code]
        ) {
            let s = address.segments
            let head: [UInt16] = [s.0, s.1, s.2, s.3, s.4, s.5]
            buffer.reserveCapacity(45)

            // §4.1 leading-zero suppression + §4.3 lowercase hex.
            func appendHex(_ value: UInt16) {
                if value == 0 {
                    buffer.append(ASCII.Code.`0`)
                    return
                }
                var started = false
                var shift: UInt16 = 12
                while true {
                    let nibble = UInt8((value >> shift) & 0xF)
                    if started || nibble != 0 {
                        started = true
                        let code =
                            nibble < 10
                            ? ASCII.Code(ASCII.Code.`0`.underlying &+ nibble)
                            : ASCII.Code(ASCII.Code.a.underlying &+ (nibble &- 10))
                        buffer.append(code)
                    }
                    if shift == 0 { break }
                    shift &-= 4
                }
            }

            func appendDecimal(_ value: UInt8) {
                if value >= 100 {
                    buffer.append(ASCII.Code(ASCII.Code.`0`.underlying &+ value / 100))
                }
                if value >= 10 {
                    buffer.append(ASCII.Code(ASCII.Code.`0`.underlying &+ (value / 10) % 10))
                }
                buffer.append(ASCII.Code(ASCII.Code.`0`.underlying &+ value % 10))
            }

            for (index, segment) in head.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.colon)
                }
                appendHex(segment)
            }

            buffer.append(ASCII.Code.colon)

            // Trailing 32 bits (segments 6 and 7) as dotted-decimal IPv4.
            appendDecimal(UInt8((s.6 >> 8) & 0xFF))
            buffer.append(ASCII.Code.period)
            appendDecimal(UInt8(s.6 & 0xFF))
            buffer.append(ASCII.Code.period)
            appendDecimal(UInt8((s.7 >> 8) & 0xFF))
            buffer.append(ASCII.Code.period)
            appendDecimal(UInt8(s.7 & 0xFF))
        }
    }
}

// MARK: - Witness value (`.ipv4Mixed`)

extension Serializer.`Protocol` where Self == RFC_4291.IPv6.Address.Text.IPv4Mixed {
    /// The IPv4-mixed IPv6 text variant witness value (RFC 4291 §2.2).
    public static var ipv4Mixed: RFC_4291.IPv6.Address.Text.IPv4Mixed { .init() }
}
