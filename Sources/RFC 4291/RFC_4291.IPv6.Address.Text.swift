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

// RFC_4291.IPv6.Address.Text.swift
// swift-rfc-4291
//
// [FAM-012] text-variant witness namespace + the witness-passing serialize verb.

public import ASCII_Serializer_Primitives

extension RFC_4291.IPv6.Address {
    /// Namespace for the non-default IPv6 text-form variants ([FAM-012] §10).
    ///
    /// The default text form is the **RFC 5952 canonical** representation —
    /// `Address.serialize(_:into:)` keyed on `Buffer.Element == ASCII.Code`.
    /// The other RFC 4291 §2.2 text forms are NOT siblings and NOT a runtime
    /// enum: each is a distinct `Serializer.\`Protocol\`` **witness value**
    /// (compile-time, typed) passed to ``serialize(_:into:serializer:)``:
    ///
    /// ```swift
    /// let canonical: [ASCII.Code] = address.asciiCodes                 // default verb (RFC 5952)
    ///
    /// var full: [ASCII.Code] = []
    /// RFC_4291.IPv6.Address.serialize(address, into: &full, serializer: .full)        // witness value
    ///
    /// var mixed: [ASCII.Code] = []
    /// RFC_4291.IPv6.Address.serialize(address, into: &mixed, serializer: .ipv4Mixed)  // witness value
    /// ```
    ///
    /// This is the Rendel–Ostermann "N concrete syntaxes = N printer
    /// descriptions" realised as N typed witness values ([FAM-005]).
    public enum Text {}
}

// MARK: - Witness-passing serialize verb

extension RFC_4291.IPv6.Address {
    /// Serializes `address` using an explicit text-variant witness value.
    ///
    /// The witness (`serializer`) is a `Serializer.\`Protocol\`` value whose
    /// `Output` is `RFC_4291.IPv6.Address`; it carries the chosen text VARIANT
    /// (the [FAM-005] leaf-instance axis). The canonical/default RFC 5952 form
    /// is the `ASCII.Serializable` verb body and needs no witness.
    ///
    /// - Parameters:
    ///   - address: The address to serialize.
    ///   - buffer: The sink the witness writes into (`[ASCII.Code]` for the
    ///     shipped text variants).
    ///   - serializer: The variant witness value (e.g. `.full`, `.ipv4Mixed`).
    public static func serialize<S: Serializer.`Protocol`>(
        _ address: RFC_4291.IPv6.Address,
        into buffer: inout S.Buffer,
        serializer: borrowing S
    ) where S.Output == RFC_4291.IPv6.Address, S.Failure == Never {
        serializer.serialize(address, into: &buffer)
    }
}
