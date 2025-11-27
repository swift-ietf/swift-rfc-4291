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

// RFC_4291.IPv6.Address.Error.swift
// swift-rfc-4291

extension RFC_4291.IPv6.Address {
    /// Error type for IPv6 address parsing
    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
        case invalidCharacter(_ value: String, byte: UInt8)
        case invalidFormat(_ value: String)
        case tooManySegments(_ value: String)
        case tooFewSegments(_ value: String)
        case invalidSegment(_ value: String)
        case multipleCompressions(_ value: String)
    }
}

extension RFC_4291.IPv6.Address.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "IPv6 address cannot be empty"
        case .invalidCharacter(let value, let byte):
            return "Invalid byte 0x\(String(byte, radix: 16)) in IPv6 address '\(value)'"
        case .invalidFormat(let value):
            return "Invalid IPv6 address format: '\(value)'"
        case .tooManySegments(let value):
            return "Too many segments in IPv6 address: '\(value)'"
        case .tooFewSegments(let value):
            return "Too few segments in IPv6 address: '\(value)'"
        case .invalidSegment(let value):
            return "Invalid segment in IPv6 address: '\(value)'"
        case .multipleCompressions(let value):
            return "Multiple :: compressions in IPv6 address: '\(value)'"
        }
    }
}
