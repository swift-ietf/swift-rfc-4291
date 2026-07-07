import Testing

@testable import RFC_4291

// MARK: - Binary Serialization Tests

@Suite("IPv6 Address Binary Serialization")
struct BinarySerializationTests {

    @Test
    func `Loopback (::1) serializes to 16 bytes with last byte = 1`() {
        let addr = RFC_4291.IPv6.Address.loopback
        let bytes = [Byte](addr)
        #expect(bytes.count == 16)
        #expect(bytes == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
    }

    @Test
    func `Unspecified (::) serializes to 16 zero bytes`() {
        let addr = RFC_4291.IPv6.Address.unspecified
        let bytes = [Byte](addr)
        #expect(bytes.count == 16)
        #expect(bytes.allSatisfy { $0 == 0 })
    }

    @Test
    func `2001:db8::1 serializes correctly in network byte order`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        let bytes = [Byte](addr)
        #expect(bytes.count == 16)
        // 0x2001 = 0x20, 0x01 (big-endian)
        // 0x0db8 = 0x0d, 0xb8 (big-endian)
        #expect(bytes[0] == 0x20)
        #expect(bytes[1] == 0x01)
        #expect(bytes[2] == 0x0d)
        #expect(bytes[3] == 0xb8)
        // Middle zeros
        #expect(bytes[4...13].allSatisfy { $0 == 0 })
        // Last segment: 0x0001
        #expect(bytes[14] == 0x00)
        #expect(bytes[15] == 0x01)
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
            _ = try RFC_4291.IPv6.Address(binary: [0, 0, 0, 0])  // Only 4 bytes
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(binary: [Byte](repeating: 0, count: 20))  // 20 bytes
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
            bytes == [
                0xAA, 0xBB,  // segment 0
                0xCC, 0xDD,  // segment 1
                0xEE, 0xFF,  // segment 2
                0x11, 0x22,  // segment 3
                0x33, 0x44,  // segment 4
                0x55, 0x66,  // segment 5
                0x77, 0x88,  // segment 6
                0x99, 0xAA,  // segment 7
            ]
        )
    }
}

// MARK: - [FAM-012] wire + RFC 4291 §2.2 grammar-parse (this package's siblings)

@Suite("IPv6 Address wire and grammar parse")
struct WireAndGrammarParseTests {

    @Test
    func `Binary.Serializable wire form is sixteen network-order octets`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        #expect(addr.bytes.count == 16)
        #expect(addr.bytes[0] == 0x20 && addr.bytes[1] == 0x01)
        #expect(addr.bytes[15] == 0x01)
    }

    @Test
    func `Binary.Parseable round-trips the wire form with cursor semantics`() throws {
        let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0, 0, 0x8a2e, 0x0370, 0x7334)
        var source: [Byte] = original.bytes + [0xFF]  // 16 octets + a trailing byte
        let parsed = try RFC_4291.IPv6.Address.parse(from: &source)
        #expect(parsed == original)
        #expect(source == [0xFF])  // cursor advanced past 16 bytes
    }

    @Test
    func `Binary.Parseable rejects insufficient input`() {
        var source: [Byte] = [0, 0, 0, 0]  // only 4 bytes
        #expect(throws: (any Error).self) {
            _ = try RFC_4291.IPv6.Address.parse(from: &source)
        }
    }

    /// RFC 4291 §2.2 grammar parse: the `::`-compressed (canonical) text form
    /// parses to the expected segments. (Serialization back to canonical text is
    /// RFC 5952's job and lives in `swift-rfc-5952`.)
    @Test
    func `ASCII.Parseable parses the compressed text form to segments`() throws {
        let addr = try RFC_4291.IPv6.Address(ascii: Array("2001:db8::1".utf8))
        #expect(addr == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
    }

    /// RFC 4291 §2.2 grammar parse: the fully-expanded (preferred) text form
    /// parses to the same segments as its compressed equivalent.
    @Test
    func `ASCII.Parseable parses the fully-expanded text form to segments`() throws {
        let addr = try RFC_4291.IPv6.Address(
            ascii: Array("2001:0db8:0000:0000:0000:0000:0000:0001".utf8)
        )
        #expect(addr == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
    }

    @Test
    func `ASCII.Parseable parses :: at start, middle, and end`() throws {
        #expect(
            try RFC_4291.IPv6.Address(ascii: Array("::8a2e:7334".utf8))
                == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334)
        )
        #expect(
            try RFC_4291.IPv6.Address(ascii: Array("2001:db8::8a2e:7334".utf8))
                == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0x8a2e, 0x7334)
        )
        #expect(
            try RFC_4291.IPv6.Address(ascii: Array("2001:db8:8a2e:7334::".utf8))
                == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x8a2e, 0x7334, 0, 0, 0, 0)
        )
    }

    @Test
    func `ASCII.Parseable rejects malformed text`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(ascii: Array("not-an-address".utf8))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(ascii: Array("".utf8))
        }
        // Two `::` compressions are illegal.
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(ascii: Array("2001::db8::1".utf8))
        }
    }
}

// MARK: - [FAM-012] text-variant witness values (RFC 4291 §2.2.1 / §2.2.3)

@Suite("IPv6 Address text-variant witness values")
struct TextVariantWitnessTests {

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
        // ::ffff:192.168.1.1 stored as segments (0,0,0,0,0,0xffff,0xc0a8,0x0101)
        let addr = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
        var mixed: [ASCII.Code] = []
        RFC_4291.IPv6.Address.serialize(addr, into: &mixed, serializer: .ipv4Mixed)
        #expect(
            String(decoding: mixed.map(\.byte), as: UTF8.self)
                == "0:0:0:0:0:ffff:192.168.1.1"
        )
    }

    /// The two variant witness VALUES produce distinct text forms for the same
    /// address — the compile-time-typed, non-enum variant axis ([FAM-005]).
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
