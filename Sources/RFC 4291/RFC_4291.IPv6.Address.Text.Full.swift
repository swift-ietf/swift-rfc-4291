public import ASCII_Serializer

extension RFC_4291.IPv6.Address.Text {

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

extension Serializer.`Protocol` where Self == RFC_4291.IPv6.Address.Text.Full {

    public static var full: RFC_4291.IPv6.Address.Text.Full { .init() }
}
