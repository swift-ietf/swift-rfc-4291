import Byte
import Testing

@testable import RFC_4291

extension RFC_4291.IPv6.Address {
    @Suite("IPv6 Address Binary Serialization")
    struct Test {

        @Test
        func `Loopback (::1) serializes to 16 bytes with last byte = 1`() {
            let addr = RFC_4291.IPv6.Address.loopback
            let bytes = [Byte](addr)
            #expect(bytes.count == 16)
            #expect(bytes == ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] as [UInt8]).map(Byte.init(bitPattern:)))
        }

        @Test
        func `Unspecified (::) serializes to 16 zero bytes`() {
            let addr = RFC_4291.IPv6.Address.unspecified
            let bytes = [Byte](addr)
            #expect(bytes.count == 16)
            #expect(bytes.allSatisfy { $0.bitPattern == 0 })
        }

        @Test
        func `2001:db8::1 serializes correctly in network byte order`() {
            let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
            let bytes = [Byte](addr)
            #expect(bytes.count == 16)

            #expect(bytes[0].bitPattern == 0x20)
            #expect(bytes[1].bitPattern == 0x01)
            #expect(bytes[2].bitPattern == 0x0d)
            #expect(bytes[3].bitPattern == 0xb8)

            #expect(bytes[4...13].allSatisfy { $0.bitPattern == 0 })

            #expect(bytes[14].bitPattern == 0x00)
            #expect(bytes[15].bitPattern == 0x01)
        }

        @Test
        func `Binary round-trip preserves address`() throws {
            let original = RFC_4291.IPv6.Address(
                0x2001,
                0x0db8,
                0x85a3,
                0x1234,
                0x5678,
                0x9abc,
                0xdef0,
                0x1111
            )
            let bytes = [Byte](original)
            let parsed = try RFC_4291.IPv6.Address(binary: bytes)
            #expect(parsed == original)
        }

        @Test
        func `Link-local address binary round-trip`() throws {
            let original = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
            let bytes = [Byte](original)
            let parsed = try RFC_4291.IPv6.Address(binary: bytes)
            #expect(parsed == original)
        }

        @Test
        func `Binary parsing rejects wrong byte count`() {
            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(binary: [Byte](repeating: Byte(bitPattern: 0), count: 4))
            }
            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(binary: [Byte](repeating: Byte(bitPattern: 0), count: 20))
            }
        }

        @Test
        func `All segments serialize in network byte order`() {
            let addr = RFC_4291.IPv6.Address(
                0xAABB,
                0xCCDD,
                0xEEFF,
                0x1122,
                0x3344,
                0x5566,
                0x7788,
                0x99AA
            )
            let bytes = [Byte](addr)
            #expect(
                bytes.map(\.bitPattern) == [
                    0xAA, 0xBB,
                    0xCC, 0xDD,
                    0xEE, 0xFF,
                    0x11, 0x22,
                    0x33, 0x44,
                    0x55, 0x66,
                    0x77, 0x88,
                    0x99, 0xAA,
                ]
            )
        }
    }
}

extension RFC_4291.IPv6.Address.Test {
    @Suite
    struct `Wire And Grammar Parse` {

        @Test
        func `Binary.Serializable wire form is sixteen network-order octets`() {
            let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
            #expect(addr.bytes.count == 16)
            #expect(addr.bytes[0].bitPattern == 0x20 && addr.bytes[1].bitPattern == 0x01)
            #expect(addr.bytes[15].bitPattern == 0x01)
        }

        @Test
        func `Binary.Parseable round-trips the wire form with cursor semantics`() throws {
            let original = RFC_4291.IPv6.Address(
                0x2001,
                0x0db8,
                0x85a3,
                0,
                0,
                0x8a2e,
                0x0370,
                0x7334
            )
            var source: [Byte] = original.bytes + [Byte(bitPattern: 0xFF)]
            let parsed = try RFC_4291.IPv6.Address.parse(from: &source)
            #expect(parsed == original)
            #expect(source == ([0xFF] as [UInt8]).map(Byte.init(bitPattern:)))
        }

        @Test
        func `Binary.Parseable rejects insufficient input`() {
            var source: [Byte] = ([0, 0, 0, 0] as [UInt8]).map(Byte.init(bitPattern:))
            #expect(throws: (any Swift.Error).self) {
                _ = try RFC_4291.IPv6.Address.parse(from: &source)
            }
        }

        @Test
        func `ASCII.Parseable parses the compressed text form to segments`() throws {
            let addr = try RFC_4291.IPv6.Address(ascii: "2001:db8::1".utf8.map(Byte.init(bitPattern:)))
            #expect(addr == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
        }

        @Test
        func `ASCII.Parseable parses the fully-expanded text form to segments`() throws {
            let addr = try RFC_4291.IPv6.Address(
                ascii: "2001:0db8:0000:0000:0000:0000:0000:0001".utf8.map(Byte.init(bitPattern:))
            )
            #expect(addr == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
        }

        @Test
        func `ASCII.Parseable parses :: at start, middle, and end`() throws {
            #expect(
                try RFC_4291.IPv6.Address(ascii: "::8a2e:7334".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334)
            )
            #expect(
                try RFC_4291.IPv6.Address(ascii: "2001:db8::8a2e:7334".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0x8a2e, 0x7334)
            )
            #expect(
                try RFC_4291.IPv6.Address(ascii: "2001:db8:8a2e:7334::".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x8a2e, 0x7334, 0, 0, 0, 0)
            )
        }

        @Test
        func `ASCII.Parseable rejects malformed text`() {
            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "not-an-address".utf8.map(Byte.init(bitPattern:)))
            }
            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "2001::db8::1".utf8.map(Byte.init(bitPattern:)))
            }
        }
    }
}

extension RFC_4291.IPv6.Address.Test {
    @Suite
    struct `IPv4 Mixed Grammar Parse` {

        @Test
        func `ASCII.Parseable parses uncompressed IPv4-mixed form and round-trips via .ipv4Mixed`()
            throws
        {
            let addr = try RFC_4291.IPv6.Address(
                ascii: "0:0:0:0:0:ffff:192.168.1.1".utf8.map(Byte.init(bitPattern:))
            )
            #expect(addr == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101))

            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(addr, into: &mixed, serializer: .ipv4Mixed)
            let text = String(decoding: mixed.map(\.byte), as: UTF8.self)
            #expect(text == "0:0:0:0:0:ffff:192.168.1.1")
            let reparsed = try RFC_4291.IPv6.Address(ascii: text.utf8.map(Byte.init(bitPattern:)))
            #expect(reparsed == addr)
        }

        @Test
        func `ASCII.Parseable parses the compressed IPv4-mixed forms`() throws {
            #expect(
                try RFC_4291.IPv6.Address(ascii: "::ffff:192.168.1.1".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
            )
            #expect(
                try RFC_4291.IPv6.Address(ascii: "::13.1.68.3".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x0d01, 0x4403)
            )
            #expect(
                try RFC_4291.IPv6.Address(ascii: "64:ff9b::192.0.2.33".utf8.map(Byte.init(bitPattern:)))
                    == RFC_4291.IPv6.Address(0x64, 0xff9b, 0, 0, 0, 0, 0xc000, 0x0221)
            )
        }

        @Test
        func `ASCII.Parseable rejects malformed IPv4-mixed tails`() {

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "::ffff:256.0.0.1".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "::ffff:1.2.3".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "::ffff:1.2.3.4.5".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "::ffff:1.2.3.a".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "192.168.1.1".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "::ffff:1..2.3".utf8.map(Byte.init(bitPattern:)))
            }

            #expect(throws: RFC_4291.IPv6.Address.Error.self) {
                _ = try RFC_4291.IPv6.Address(ascii: "1:2:3:4:5:6:7:1.2.3.4".utf8.map(Byte.init(bitPattern:)))
            }
        }
    }
}

extension RFC_4291.IPv6.Address.Test {
    @Suite
    struct `Text Variant Witness` {

        @Test
        func `the .full witness value emits the fully-expanded form (RFC 4291 §2.2.1)`() {
            let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
            var full: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(addr, into: &full, serializer: .full)
            #expect(
                String(decoding: full.map(\.byte), as: UTF8.self)
                    == "2001:0db8:0000:0000:0000:0000:0000:0001"
            )
        }

        @Test
        func `the .ipv4Mixed witness value emits the dotted-decimal tail (RFC 4291 §2.2.3)`() {

            let addr = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(addr, into: &mixed, serializer: .ipv4Mixed)
            #expect(
                String(decoding: mixed.map(\.byte), as: UTF8.self)
                    == "0:0:0:0:0:ffff:192.168.1.1"
            )
        }

        @Test
        func `the full and ipv4Mixed witness values are distinct`() {
            let addr = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
            var full: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(addr, into: &full, serializer: .full)
            var mixed: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(addr, into: &mixed, serializer: .ipv4Mixed)
            #expect(full != mixed)
        }
    }
}
