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

extension RFC_4291.IPv6.Address.Is {
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
