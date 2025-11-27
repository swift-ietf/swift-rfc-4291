import Testing
@testable import RFC_4291

@Suite("IPv6 Address Serialization")
struct SerializationTests {

    // MARK: - Special Addresses

    @Test(":: (unspecified) should serialize correctly")
    func testUnspecifiedSerialization() {
        let addr = RFC_4291.IPv6.Address.unspecified
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "::")
    }

    @Test("::1 (loopback) should serialize correctly")
    func testLoopbackSerialization() {
        let addr = RFC_4291.IPv6.Address.loopback
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "::1")
    }

    // MARK: - Link-Local Addresses

    @Test("fe80::1 should serialize correctly")
    func testLinkLocalSerialization() {
        let addr = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "fe80::1")
    }

    // MARK: - Documentation Addresses (RFC 3849)

    @Test("2001:db8::1 should serialize correctly")
    func testDocSerialization() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8::1")
    }

    @Test("2001:db8:85a3::8a2e:370:7334 should serialize correctly")
    func testDocAddressWithMiddleCompression() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x85a3, 0, 0, 0x8a2e, 0x0370, 0x7334)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8:85a3::8a2e:370:7334")
    }

    // MARK: - No Compression (all non-zero)

    @Test("Full address with no zeros should not compress")
    func testNoCompression() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x1234, 0x5678, 0x9abc, 0xdef0, 0x1111, 0x2222)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8:1234:5678:9abc:def0:1111:2222")
    }

    // MARK: - Single Zero (no compression per RFC 5952)

    @Test("Single zero segment should not compress")
    func testSingleZeroNoCompression() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0x5678, 0x9abc, 0xdef0, 0x1111, 0x2222)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8:0:5678:9abc:def0:1111:2222")
    }

    // MARK: - Compression at Different Positions

    @Test("Compression at start (::...)")
    func testCompressionAtStart() {
        let addr = RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "::8a2e:7334")
    }

    @Test("Compression in middle (...::...)")
    func testCompressionInMiddle() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0x8a2e, 0x7334)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8::8a2e:7334")
    }

    @Test("Compression at end (...::)")
    func testCompressionAtEnd() {
        let addr = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x8a2e, 0x7334, 0, 0, 0, 0)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001:db8:8a2e:7334::")
    }

    // MARK: - RFC 5952 Section 4.2.3: First Longest Run

    @Test("Multiple equal runs should compress first one")
    func testFirstLongestRunCompression() {
        // Two runs of 2 zeros each - should compress the first one
        let addr = RFC_4291.IPv6.Address(0x2001, 0, 0, 0x5678, 0x9abc, 0, 0, 0x2222)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "2001::5678:9abc:0:0:2222")
    }

    // MARK: - Lowercase Hex (RFC 5952 Section 4.3)

    @Test("Hex digits should be lowercase")
    func testLowercaseHex() {
        let addr = RFC_4291.IPv6.Address(0xABCD, 0xEF01, 0x2345, 0x6789, 0xABCD, 0xEF01, 0x2345, 0x6789)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "abcd:ef01:2345:6789:abcd:ef01:2345:6789")
    }

    // MARK: - Leading Zero Suppression (RFC 5952 Section 4.1)

    @Test("Leading zeros should be suppressed")
    func testLeadingZeroSuppression() {
        let addr = RFC_4291.IPv6.Address(0x0001, 0x0020, 0x0300, 0x4000, 0x0001, 0x0020, 0x0300, 0x4000)
        let bytes = [UInt8](addr)
        let result = String(decoding: bytes, as: UTF8.self)
        #expect(result == "1:20:300:4000:1:20:300:4000")
    }
}
