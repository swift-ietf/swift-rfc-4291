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

// RFC_4291.swift
// swift-rfc-4291
//
// RFC 4291: IPv6 Addressing Architecture (February 2006)
// https://www.rfc-editor.org/rfc/rfc4291.html
//
// This package implements the IPv6 Addressing Architecture specification (RFC 4291)
// which defines the 128-bit IPv6 address structure and address types.
//
// Key types:
// - RFC_4291.IPv6.Address - IPv6 address (128-bit)
//
// Note: Text representation is defined by RFC 5952

/// IPv6 Addressing Architecture namespace (RFC 4291)
///
/// This namespace contains types representing IPv6 addressing as defined in RFC 4291,
/// the IPv6 Addressing Architecture specification from February 2006.
///
/// RFC 4291 defines:
/// - 128-bit address structure
/// - Address types (unicast, anycast, multicast)
/// - Address scope
/// - Interface identifiers
///
/// Text representation (parsing and serialization) is handled by RFC 5952.
public enum RFC_4291 {}

/// IPv6 namespace
///
/// Contains types for IPv6 addressing
extension RFC_4291 {
    public enum IPv6 {}
}
