import Byte
import Byte_Standard_Library_Integration
import RFC_4291
import Testing

@Suite
struct `RFC 4291 Tests` {
    @Suite struct `Address Tests` {}
    @Suite struct `Classification Tests` {}
    @Suite struct `Text Grammar Tests` {}
    @Suite struct `IPv4 Mixed Grammar Tests` {}
    @Suite struct `Octet Tests` {}
}

extension `RFC 4291 Tests`.`Address Tests` {

    @Test
    func `eight segments construct an address`() {
        let address = RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        #expect(address.segments.0 == 0x2001)
        #expect(address.segments.1 == 0x0db8)
        #expect(address.segments.7 == 1)
    }

    @Test
    func `the unspecified address is all zeros`() {
        #expect(RFC_4291.IPv6.Address.unspecified == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0, 0))
    }

    @Test
    func `the loopback address is ::1`() {
        #expect(RFC_4291.IPv6.Address.loopback == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0, 1))
    }

    @Test
    func `addresses are equatable and hashable by segments`() {
        let a = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        let b = RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(Set([a, b]).count == 1)
    }

    @Test
    func `addresses compare segment by segment from the left`() {
        #expect(RFC_4291.IPv6.Address.unspecified < RFC_4291.IPv6.Address.loopback)
        #expect(RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1) < RFC_4291.IPv6.Address(0x2001, 0x0db9, 0, 0, 0, 0, 0, 0))
        #expect(RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1) > RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
    }
}

extension `RFC 4291 Tests`.`Classification Tests` {

    @Test
    func `the unspecified and loopback addresses classify themselves`() {
        #expect(RFC_4291.IPv6.Address.unspecified.is.unspecified)
        #expect(RFC_4291.IPv6.Address.loopback.is.loopback)
        #expect(!RFC_4291.IPv6.Address.loopback.is.globalUnicast)
    }

    @Test
    func `ff00::/8 is multicast`() {
        #expect(RFC_4291.IPv6.Address(0xff02, 0, 0, 0, 0, 0, 0, 1).is.multicast)
        #expect(!RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1).is.multicast)
    }

    @Test
    func `fe80::/10 is link-local`() {
        #expect(RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1).is.linkLocal)
        #expect(RFC_4291.IPv6.Address(0xfebf, 0, 0, 0, 0, 0, 0, 1).is.linkLocal)
        #expect(!RFC_4291.IPv6.Address(0xfec0, 0, 0, 0, 0, 0, 0, 1).is.linkLocal)
    }

    @Test
    func `fc00::/7 is unique local`() {
        #expect(RFC_4291.IPv6.Address(0xfc00, 0, 0, 0, 0, 0, 0, 1).is.uniqueLocal)
        #expect(RFC_4291.IPv6.Address(0xfd12, 0x3456, 0, 0, 0, 0, 0, 1).is.uniqueLocal)
        #expect(!RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1).is.uniqueLocal)
    }

    @Test
    func `everything else is global unicast`() {
        #expect(RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1).is.globalUnicast)
        #expect(!RFC_4291.IPv6.Address(0xfe80, 0, 0, 0, 0, 0, 0, 1).is.globalUnicast)
    }
}

extension `RFC 4291 Tests`.`Text Grammar Tests` {

    @Test
    func `the compressed form validates to segments`() throws {
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001:db8::1")) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
    }

    @Test
    func `the fully expanded form validates to segments`() throws {
        #expect(
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001:0db8:0000:0000:0000:0000:0000:0001"))
                == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1)
        )
    }

    @Test
    func `:: is accepted at the start, in the middle and at the end`() throws {
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::8a2e:7334")) == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x8a2e, 0x7334))
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001:db8::8a2e:7334")) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0x8a2e, 0x7334))
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001:db8:8a2e:7334::")) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0x8a2e, 0x7334, 0, 0, 0, 0))
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::")) == .unspecified)
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::1")) == .loopback)
    }

    @Test
    func `empty text is refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.empty) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: ""))
        }
    }

    @Test
    func `a second :: is refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.multipleCompressions("2001::db8::1")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "2001::db8::1"))
        }
    }

    @Test
    func `too few and too many segments are refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.tooFewSegments("1:2:3")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "1:2:3"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.tooManySegments("1:2:3:4:5:6:7:8:9")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "1:2:3:4:5:6:7:8:9"))
        }
    }

    @Test
    func `a lone leading or trailing colon is refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.invalidFormat(":1:2:3:4:5:6:7:8")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: ":1:2:3:4:5:6:7:8"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.invalidFormat("1:2:3:4:5:6:7:8:")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "1:2:3:4:5:6:7:8:"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.invalidFormat(":1::2")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: ":1::2"))
        }
    }

    @Test
    func `:: must stand for at least one group of zeros`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.tooManySegments("1::2:3:4:5:6:7:8")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "1::2:3:4:5:6:7:8"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.tooManySegments("1:2:3:4:5:6:7:8::")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "1:2:3:4:5:6:7:8::"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.tooManySegments("::1:2:3:4:5:6:7:8")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::1:2:3:4:5:6:7:8"))
        }
    }

    @Test
    func `non-hexadecimal characters and oversized segments are refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "not-an-address"))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.invalidSegment("12345")) {
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "12345::1"))
        }
    }
}

extension `RFC 4291 Tests`.`IPv4 Mixed Grammar Tests` {

    @Test
    func `the uncompressed IPv4-mixed form validates to segments`() throws {
        #expect(
            try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "0:0:0:0:0:ffff:192.168.1.1"))
                == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101)
        )
    }

    @Test
    func `the compressed IPv4-mixed forms validate to segments`() throws {
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::ffff:192.168.1.1")) == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0xffff, 0xc0a8, 0x0101))
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "::13.1.68.3")) == RFC_4291.IPv6.Address(0, 0, 0, 0, 0, 0, 0x0d01, 0x4403))
        #expect(try RFC_4291.IPv6.Address(ascii: [Byte](utf8: "64:ff9b::192.0.2.33")) == RFC_4291.IPv6.Address(0x64, 0xff9b, 0, 0, 0, 0, 0xc000, 0x0221))
    }

    @Test
    func `malformed IPv4 tails are refused`() {
        for text in ["::ffff:256.0.0.1", "::ffff:1.2.3", "::ffff:1.2.3.4.5", "::ffff:1.2.3.a", "192.168.1.1", ":1.2.3.4", "::ffff:1..2.3", "1:2:3:4:5:6:7:1.2.3.4", "1:2:3:4:5:6::1.2.3.4"] {
            #expect(throws: RFC_4291.IPv6.Address.Error.self, "\(text)") {
                try RFC_4291.IPv6.Address(ascii: [Byte](utf8: text))
            }
        }
    }
}

extension `RFC 4291 Tests`.`Octet Tests` {

    @Test
    func `sixteen network-order octets validate to segments`() throws {
        let octets: [Byte] = ([0x20, 0x01, 0x0d, 0xb8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] as [UInt8]).map(Byte.init(bitPattern:))
        #expect(try RFC_4291.IPv6.Address(binary: octets) == RFC_4291.IPv6.Address(0x2001, 0x0db8, 0, 0, 0, 0, 0, 1))
    }

    @Test
    func `any other octet count is refused`() {
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            try RFC_4291.IPv6.Address(binary: [Byte](repeating: Byte(bitPattern: 0), count: 4))
        }
        #expect(throws: RFC_4291.IPv6.Address.Error.self) {
            try RFC_4291.IPv6.Address(binary: [Byte](repeating: Byte(bitPattern: 0), count: 20))
        }
    }
}
