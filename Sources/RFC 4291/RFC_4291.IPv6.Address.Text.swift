public import ASCII_Serializer_Primitives

extension RFC_4291.IPv6.Address {

    public enum Text {}
}

extension RFC_4291.IPv6.Address {

    public static func serialize<S: Serializer.`Protocol`>(
        _ address: RFC_4291.IPv6.Address,
        into buffer: inout S.Buffer,
        serializer: borrowing S
    ) where S.Output == RFC_4291.IPv6.Address, S.Failure == Never {
        serializer.serialize(address, into: &buffer)
    }
}
