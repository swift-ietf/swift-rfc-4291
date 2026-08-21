extension RFC_4291.IPv6.Address {

    public struct Is: Sendable {
        @usableFromInline
        let address: RFC_4291.IPv6.Address

        @usableFromInline
        init(_ address: RFC_4291.IPv6.Address) {
            self.address = address
        }
    }

    public var `is`: Is {
        Is(self)
    }
}

extension RFC_4291.IPv6.Address.Is {

    @inlinable
    public var unspecified: Bool {
        address == .unspecified
    }

    @inlinable
    public var loopback: Bool {
        address == .loopback
    }

    @inlinable
    public var multicast: Bool {
        (address.segments.0 & 0xFF00) == 0xFF00
    }

    @inlinable
    public var linkLocal: Bool {
        (address.segments.0 & 0xFFC0) == 0xFE80
    }

    @inlinable
    public var uniqueLocal: Bool {
        (address.segments.0 & 0xFE00) == 0xFC00
    }

    @inlinable
    public var globalUnicast: Bool {
        !unspecified && !loopback && !multicast && !linkLocal && !uniqueLocal
    }
}
