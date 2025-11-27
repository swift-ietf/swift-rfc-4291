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

// [UInt8]+RFC_4291.swift
// swift-rfc-4291

extension [UInt8] {
    /// Creates ASCII bytes from RFC_4291.IPv6.Address
    ///
    /// Serializes an IPv6 address to its text representation per RFC 5952
    /// (canonical format).
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_4291.IPv6.Address (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived composition:
    /// ```
    /// Address → [UInt8] (ASCII) → String (UTF-8)
    /// ```
    ///
    /// ## Format
    ///
    /// Per RFC 5952, the canonical text representation:
    /// - Uses lowercase hexadecimal digits
    /// - Omits leading zeros in each segment
    /// - Uses `::` to compress the longest run of consecutive zero segments
    /// - If multiple runs of equal length, compress the first one
    ///
    /// ## Example
    ///
    /// ```swift
    /// let address = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
    /// let bytes = [UInt8](address)
    /// // bytes contains "2001:db8::1"
    /// ```
    public init(_ address: RFC_4291.IPv6.Address) {
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

        self = []
        self.reserveCapacity(39) // Max length: 8 segments * 4 hex + 7 colons

        for (index, segment) in segments.enumerated() {
            // Handle compression
            if shouldCompress && index >= longestZeroRun.start && index < longestZeroRun.start + longestZeroRun.length {
                if index == longestZeroRun.start {
                    // Start of compression
                    if index == 0 {
                        self.append(INCITS_4_1986.GraphicCharacters.colon)
                    }
                    self.append(INCITS_4_1986.GraphicCharacters.colon)
                }
                continue
            }

            // Add colon separator (except before first segment and after ::)
            if index > 0 {
                let afterCompression = shouldCompress && index == longestZeroRun.start + longestZeroRun.length
                if !afterCompression {
                    self.append(INCITS_4_1986.GraphicCharacters.colon)
                }
            }

            // Convert segment to hex (lowercase, no leading zeros per RFC 5952)
            let hexString = String(segment, radix: 16, uppercase: false)
            self.append(contentsOf: hexString.utf8)
        }
    }
}
