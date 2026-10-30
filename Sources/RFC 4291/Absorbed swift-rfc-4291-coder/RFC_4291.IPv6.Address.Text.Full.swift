#if Coder
    public import ASCII
    import Serializer

    extension RFC_4291.IPv6.Address.Text {

        public struct Full: Serializer::Serializing {

            public init() {}
        }
    }

    extension RFC_4291.IPv6.Address.Text.Full {
        public typealias Output = RFC_4291.IPv6.Address
        public typealias Buffer = [ASCII.Code]
        public typealias Failure = Never

        public borrowing func serialize(
            _ address: RFC_4291.IPv6.Address,
            into buffer: inout [ASCII.Code]
        ) {
            let s = address.segments
            let segments: [UInt16] = [s.0, s.1, s.2, s.3, s.4, s.5, s.6, s.7]
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

    extension Serializer::Serializing where Self == RFC_4291.IPv6.Address.Text.Full {

        public static var full: RFC_4291.IPv6.Address.Text.Full { .init() }
    }
#endif
