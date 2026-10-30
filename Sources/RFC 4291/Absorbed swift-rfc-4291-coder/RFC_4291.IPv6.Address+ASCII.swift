#if Coder
    public import ASCII

    extension RFC_4291.IPv6.Address: ASCII.Parseable {}

    extension RFC_4291.IPv6.Address: ASCII.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ address: borrowing RFC_4291.IPv6.Address,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            var codes: [ASCII.Code] = []
            RFC_4291.IPv6.Address.Text.Full().serialize(address, into: &codes)
            buffer.append(contentsOf: codes)
        }
    }
#endif
