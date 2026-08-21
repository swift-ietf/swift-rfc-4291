public import ASCII_Serializer_Primitives

extension RFC_4291.IPv6.Address.Text {

    public struct IPv4Mixed: Serializer.`Protocol` {
        public init() {}
    }
}

extension RFC_4291.IPv6.Address.Text.IPv4Mixed {
    public typealias Output = RFC_4291.IPv6.Address
    public typealias Buffer = [ASCII.Code]
    public typealias Failure = Never
    public typealias Body = Never

    public borrowing func serialize(
        _ address: RFC_4291.IPv6.Address,
        into buffer: inout [ASCII.Code]
    ) {
        let s = address.segments
        let head: [UInt16] = [s.0, s.1, s.2, s.3, s.4, s.5]
        buffer.reserveCapacity(45)

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

        appendDecimal(UInt8((s.6 >> 8) & 0xFF))
        buffer.append(ASCII.Code.period)
        appendDecimal(UInt8(s.6 & 0xFF))
        buffer.append(ASCII.Code.period)
        appendDecimal(UInt8((s.7 >> 8) & 0xFF))
        buffer.append(ASCII.Code.period)
        appendDecimal(UInt8(s.7 & 0xFF))
    }
}

extension Serializer.`Protocol` where Self == RFC_4291.IPv6.Address.Text.IPv4Mixed {

    public static var ipv4Mixed: RFC_4291.IPv6.Address.Text.IPv4Mixed { .init() }
}
