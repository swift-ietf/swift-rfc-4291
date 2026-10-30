#if Coder
    import ASCII
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_4291.IPv6.Address {

        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

            public typealias Output = RFC_4291.IPv6.Address

            public typealias Failure = RFC_4291.IPv6.Address.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                var bytes: [Byte] = []
                while true {
                    let mark = input.checkpoint
                    guard let byte = input.next(), Self.isAddressByte(byte.bitPattern) else {
                        input.seek(to: mark)
                        break
                    }
                    bytes.append(byte)
                }

                do throws(Failure) {
                    return try RFC_4291.IPv6.Address(ascii: bytes)
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
                var codes: [ASCII.Code] = []
                RFC_4291.IPv6.Address.Text.Full().serialize(output, into: &codes)
                buffer.append(contentsOf: codes.lazy.map(\.byte))
            }

            private static func isAddressByte(_ byte: UInt8) -> Bool {
                (0x30...0x39).contains(byte)
                    || (0x41...0x46).contains(byte)
                    || (0x61...0x66).contains(byte)
                    || byte == 0x3A
                    || byte == 0x2E
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
