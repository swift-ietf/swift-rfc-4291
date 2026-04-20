import Testing

@testable import RFC_4291

@Suite("IPv6 Address ASCII Serialization")
struct ASCIISerializationTests {

    // MARK: - Special Addresses

    @Test
    func `:: (unspecified) should serialize correctly`() {
        let addr = RFC_4291.IPv6.Address.unspecified
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "::")
    }

    @Test
    func `::1 (loopback) should serialize correctly`() {
        let addr = RFC_4291.IPv6.Address.loopback
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "::1")
    }

    // MARK: - Link-Local Addresses

    @Test
    func `fe80::1 should serialize correctly`() {
        let addr = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "fe80::1")
    }

    // MARK: - Documentation Addresses (RFC 3849)

    @Test
    func `2001:db8::1 should serialize correctly`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8::1")
    }

    @Test
    func `2001:db8:85a3::8a2e:370:7334 should serialize correctly`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0, 0, 0x8a2e, 0x0370, 0x7334)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8:85a3::8a2e:370:7334")
    }

    // MARK: - No Compression (all non-zero)

    @Test
    func `Full address with no zeros should not compress`() {
        let addr = RFC_4291.IPv6.Address(
            0x2001,
            0x0db8,
            0x1234,
            0x5678,
            0x9abc,
            0xdef0,
            0x1111,
            0x2222
        )
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8:1234:5678:9abc:def0:1111:2222")
    }

    // MARK: - Single Zero (no compression per RFC 5952)

    @Test
    func `Single zero segment should not compress`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0x5678, 0x9abc, 0xdef0, 0x1111, 0x2222)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8:0:5678:9abc:def0:1111:2222")
    }

    // MARK: - Compression at Different Positions

    @Test
    func `Compression at start (::...)`() {
        let addr = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "::8a2e:7334")
    }

    @Test
    func `Compression in middle (...::...)`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0x8a2e, 0x7334)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8::8a2e:7334")
    }

    @Test
    func `Compression at end (...::)`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x8a2e, 0x7334, 0, 0, 0, 0)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001:db8:8a2e:7334::")
    }

    // MARK: - RFC 5952 Section 4.2.3: First Longest Run

    @Test
    func `Multiple equal runs should compress first one`() {
        // Two runs of 2 zeros each - should compress the first one
        let addr = RFC_4291.IPv6.Address(0x2001, 0, 0, 0x5678, 0x9abc, 0, 0, 0x2222)
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "2001::5678:9abc:0:0:2222")
    }

    // MARK: - Lowercase Hex (RFC 5952 Section 4.3)

    @Test
    func `Hex digits should be lowercase`() {
        let addr = RFC_4291.IPv6.Address(
            0xABCD,
            0xEF01,
            0x2345,
            0x6789,
            0xABCD,
            0xEF01,
            0x2345,
            0x6789
        )
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "abcd:ef01:2345:6789:abcd:ef01:2345:6789")
    }

    // MARK: - Leading Zero Suppression (RFC 5952 Section 4.1)

    @Test
    func `Leading zeros should be suppressed`() {
        let addr = RFC_4291.IPv6.Address(
            0x0001,
            0x0020,
            0x0300,
            0x4000,
            0x0001,
            0x0020,
            0x0300,
            0x4000
        )
        let result = addr.ascii.bytes
        #expect(String(decoding: result, as: UTF8.self) == "1:20:300:4000:1:20:300:4000")
    }
}

// MARK: - RawValue Tests

@Suite("IPv6 Address RawValue")
struct RawValueTests {

    @Test
    func `rawValue returns canonical RFC 5952 text representation`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        #expect(addr.rawValue == "2001:db8::1")
    }

    @Test
    func `rawValue for loopback is ::1`() {
        let addr = RFC_4291.IPv6.Address.loopback
        #expect(addr.rawValue == "::1")
    }

    @Test
    func `rawValue for unspecified is ::`() {
        let addr = RFC_4291.IPv6.Address.unspecified
        #expect(addr.rawValue == "::")
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - loopback`() {
        let original = RFC_4291.IPv6.Address.loopback
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - unspecified`() {
        let original = RFC_4291.IPv6.Address.unspecified
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - full address`() {
        let original = RFC_4291.IPv6.Address(
            0x2001, 0x0db8, 0x1234, 0x5678,
            0x9abc, 0xdef0, 0x1111, 0x2222
        )
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - compression at start`() {
        let original = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334)
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - compression in middle`() {
        let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0, 0, 0x8a2e, 0x0370, 0x7334)
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - compression at end`() {
        let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 0)
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue round-trip via init(rawValue:) - link-local`() {
        let original = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        let rawValue = original.rawValue
        let parsed = RFC_4291.IPv6.Address(rawValue: rawValue)
        #expect(parsed == original)
    }

    @Test
    func `rawValue for link-local address`() {
        let addr = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        #expect(addr.rawValue == "fe80::1")
    }

    @Test
    func `rawValue for full address without compression`() {
        let addr = RFC_4291.IPv6.Address(
            0x2001, 0x0db8, 0x1234, 0x5678,
            0x9abc, 0xdef0, 0x1111, 0x2222
        )
        #expect(addr.rawValue == "2001:db8:1234:5678:9abc:def0:1111:2222")
    }

    @Test
    func `rawValue uses lowercase hex`() {
        let addr = RFC_4291.IPv6.Address(0xABCD, 0xEF01, 0, 0, 0, 0, 0, 1)
        #expect(addr.rawValue == "abcd:ef01::1")
    }

    @Test
    func `rawValue suppresses leading zeros in segments`() {
        let addr = RFC_4291.IPv6.Address(0x0001, 0x0020, 0x0300, 0x4000, 0, 0, 0, 1)
        #expect(addr.rawValue == "1:20:300:4000::1")
    }

    @Test
    func `init(rawValue:) returns nil for invalid input`() {
        let invalid = RFC_4291.IPv6.Address(rawValue: "not-an-address")
        #expect(invalid == nil)
    }

    @Test
    func `init(rawValue:) returns nil for empty string`() {
        let empty = RFC_4291.IPv6.Address(rawValue: "")
        #expect(empty == nil)
    }
}

// MARK: - Binary Serialization Tests

@Suite("IPv6 Address Binary Serialization")
struct BinarySerializationTests {

    @Test
    func `Loopback (::1) serializes to 16 bytes with last byte = 1`() {
        let addr = RFC_4291.IPv6.Address.loopback
        let bytes = [UInt8](addr)
        #expect(bytes.count == 16)
        #expect(bytes == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
    }

    @Test
    func `Unspecified (::) serializes to 16 zero bytes`() {
        let addr = RFC_4291.IPv6.Address.unspecified
        let bytes = [UInt8](addr)
        #expect(bytes.count == 16)
        #expect(bytes.allSatisfy { $0 == 0 })
    }

    @Test
    func `2001:db8::1 serializes correctly in network byte order`() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        let bytes = [UInt8](addr)
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
        let original = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0x1234, 0x5678, 0x9abc, 0xdef0, 0x1111)
        let bytes = [UInt8](original)
        let parsed = try RFC_4291.IPv6.Address(binary: bytes)
        #expect(parsed == original)
    }

    @Test
    func `Link-local address binary round-trip`() throws {
        let original = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        let bytes = [UInt8](original)
        let parsed = try RFC_4291.IPv6.Address(binary: bytes)
        #expect(parsed == original)
    }

    @Test
    func `Binary parsing rejects wrong byte count`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(binary: [0, 0, 0, 0])  // Only 4 bytes
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            _ = try RFC_4291.IPv6.Address(binary: [UInt8](repeating: 0, count: 20))  // 20 bytes
        }
    }

    @Test
    func `All segments serialize in network byte order`() {
        let addr = RFC_4291.IPv6.Address(
            0xAABB, 0xCCDD, 0xEEFF, 0x1122,
            0x3344, 0x5566, 0x7788, 0x99AA
        )
        let bytes = [UInt8](addr)
        #expect(bytes == [
            0xAA, 0xBB,  // segment 0
            0xCC, 0xDD,  // segment 1
            0xEE, 0xFF,  // segment 2
            0x11, 0x22,  // segment 3
            0x33, 0x44,  // segment 4
            0x55, 0x66,  // segment 5
            0x77, 0x88,  // segment 6
            0x99, 0xAA,  // segment 7
        ])
    }
}
