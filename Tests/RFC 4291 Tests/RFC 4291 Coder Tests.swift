#if Coder
    import ASCII
    import Binary
    import Binary_Parseable
    import Byte
    import Coder
    import Cursor
    import Parser
    import RFC_4291
    import Serializer
    import Testing

    @Suite
    struct `RFC 4291 Coder Tests` {
        @Suite struct `Address Coder Tests` {}
        @Suite struct `Octet Tests` {}
        @Suite struct `Text Form Tests` {}
        @Suite struct `Text Conformance Tests` {}
    }

    extension `RFC 4291 Coder Tests`.`Address Coder Tests` {

        @Test
        func `reads a compressed address and stops at the first foreign byte`() throws {
            var input: ArraySlice<Byte> = "2001:db8::1]:8080"
            #expect(try RFC_4291.IPv6.Address.coder.parse(&input) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
            #expect(input.first == Byte(bitPattern: 0x5D))
        }

        @Test
        func `reads the IPv4-mixed form`() throws {
            var input: ArraySlice<Byte> = "::ffff:192.168.1.1"
            #expect(try RFC_4291.IPv6.Address.coder.parse(&input) == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101))
            #expect(input.isEmpty)
        }

        @Test
        func `rejects a malformed address and restores the cursor`() {
            var input: ArraySlice<Byte> = "2001::db8::1 rest"
            #expect(throws: RFC_4291.IPv6.Address.Error.multipleCompressions("2001::db8::1")) {
                try RFC_4291.IPv6.Address.coder.parse(&input)
            }
            #expect(input.count == 17)
        }

        @Test
        func `rejects empty input`() {
            var input: ArraySlice<Byte> = ""
            #expect(throws: RFC_4291.IPv6.Address.Error.empty) {
                try RFC_4291.IPv6.Address.coder.parse(&input)
            }
        }

        @Test
        func `serializes the fully expanded form (RFC 4291 section 2.2.1)`() throws {
            let address = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
            #expect(try RFC_4291.IPv6.Address.coder.serialize(address) == "2001:0db8:0000:0000:0000:0000:0000:0001")
        }

        @Test
        func `round-trips through decoding and encoding`() throws {
            var input: ArraySlice<Byte> = "fe80::1"
            let address = try RFC_4291.IPv6.Address.coder.parse(&input)
            var reread: ArraySlice<Byte> = try RFC_4291.IPv6.Address.coder.serialize(address)[...]
            #expect(try RFC_4291.IPv6.Address.coder.parse(&reread) == address)
        }
    }

    extension `RFC 4291 Coder Tests`.`Octet Tests` {

        @Test
        func `the loopback address is sixteen octets ending in one`() {
            let octets = [Byte](RFC_4291.IPv6.Address.loopback)
            #expect(octets.count == 16)
            #expect(octets == ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] as [UInt8]).map(Byte.init(bitPattern:)))
        }

        @Test
        func `the unspecified address is sixteen zero octets`() {
            #expect(RFC_4291.IPv6.Address.unspecified.bytes.allSatisfy { $0.bitPattern == 0 })
        }

        @Test
        func `every segment serializes in network byte order`() {
            let address = RFC_4291.IPv6.Address(0xAABB, 0xCCDD, 0xEEFF, 0x1122, 0x3344, 0x5566, 0x7788, 0x99AA)
            #expect(
                address.bytes.map(\.bitPattern) == [
                    0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x11, 0x22,
                    0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA,
                ]
            )
        }

        @Test
        func `octets round-trip through the validating octet form`() throws {
            let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0x1234, 0x5678, 0x9abc, 0xdef0, 0x1111)
            #expect(try RFC_4291.IPv6.Address(binary: original.bytes) == original)
        }

        @Test
        func `parsing from octets consumes exactly sixteen and leaves the rest`() throws {
            let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0, 0, 0x8a2e, 0x0370, 0x7334)
            var source: [Byte] = original.bytes + [Byte(bitPattern: 0xFF)]
            #expect(try RFC_4291.IPv6.Address.parse(from: &source) == original)
            #expect(source == [Byte(bitPattern: 0xFF)])
        }

        @Test
        func `parsing from fewer than sixteen octets is refused`() {
            var source: [Byte] = [Byte](repeating: Byte(bitPattern: 0), count: 4)
            #expect(throws: Binary.Parse.Failure.insufficient(needed: 16)) {
                try RFC_4291.IPv6.Address.parse(from: &source)
            }
        }
    }

    extension `RFC 4291 Coder Tests`.`Text Form Tests` {

        @Test
        func `the full text form is fully expanded (RFC 4291 section 2.2.1)`() {
            var full: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1), into: &full, serializer: .full)
            #expect(String(decoding: full.map(\.byte), as: UTF8.self) == "2001:0db8:0000:0000:0000:0000:0000:0001")
        }

        @Test
        func `the IPv4-mixed text form ends in dotted decimal (RFC 4291 section 2.2.3)`() {
            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101), into: &mixed, serializer: .ipv4Mixed)
            #expect(String(decoding: mixed.map(\.byte), as: UTF8.self) == "0:0:0:0:0:ffff:192.168.1.1")
        }

        @Test
        func `the IPv4-mixed form round-trips through the validating text form`() throws {
            let address = RFC_4291.IPv6.Address(0x64, 0xff9b, 0, 0, 0, 0, 0xc000, 0x0221)
            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(address, into: &mixed, serializer: .ipv4Mixed)
            #expect(try RFC_4291.IPv6.Address(ascii: mixed.map(\.byte)) == address)
        }

        @Test
        func `the full and IPv4-mixed text forms differ for the same address`() {
            let address = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
            var full: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(address, into: &full, serializer: .full)
            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(address, into: &mixed, serializer: .ipv4Mixed)
            #expect(full != mixed)
        }
    }

    extension `RFC 4291 Coder Tests`.`Text Conformance Tests` {

        @Test
        func `an address reads from its compressed text`() throws {
            #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001:db8::1")) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
        }

        @Test
        func `an address writes its fully expanded text`() {
            let address = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
            #expect(String(decoding: address.serialized, as: UTF8.self) == "2001:0db8:0000:0000:0000:0000:0000:0001")
            #expect(address.asciiCodes.count == 39)
        }

        @Test
        func `the text and octet forms round-trip and agree with the coder`() throws {
            let address = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
            var wire: [Byte] = []
            RFC_4291.IPv6.Address.serialize(address, into: &wire)
            #expect(wire == address.bytes)
            #expect(try RFC_4291.IPv6.Address(ascii: address.serialized) == address)
            #expect(try RFC_4291.IPv6.Address.coder.serialize(address) == address.serialized)
        }
    }
#endif
