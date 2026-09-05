public import Byte
import ASCII

extension RFC_4291.IPv6 {

    public struct Address: Sendable {

        public let segments: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)

        public init(
            _ s0: UInt16,
            _ s1: UInt16,
            _ s2: UInt16,
            _ s3: UInt16,
            _ s4: UInt16,
            _ s5: UInt16,
            _ s6: UInt16,
            _ s7: UInt16
        ) {
            self.segments = (s0, s1, s2, s3, s4, s5, s6, s7)
        }

        init(
            __unchecked: Void,
            _ s0: UInt16,
            _ s1: UInt16,
            _ s2: UInt16,
            _ s3: UInt16,
            _ s4: UInt16,
            _ s5: UInt16,
            _ s6: UInt16,
            _ s7: UInt16
        ) {
            self.segments = (s0, s1, s2, s3, s4, s5, s6, s7)
        }
    }
}

extension RFC_4291.IPv6.Address {

    public init<Bytes: Swift.Collection>(binary bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard bytes.count == 16 else {
            throw .invalidFormat("Expected 16 bytes, got \(bytes.count)")
        }
        var iterator = bytes.makeIterator()

        func next16() -> UInt16 {
            let hi = UInt16(iterator.next()!.bitPattern)
            let lo = UInt16(iterator.next()!.bitPattern)
            return (hi << 8) | lo
        }
        self.init(
            next16(),
            next16(),
            next16(),
            next16(),
            next16(),
            next16(),
            next16(),
            next16()
        )
    }
}

extension RFC_4291.IPv6.Address {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.empty }

        let input = String(decoding: bytes.lazy.map(\.bitPattern), as: UTF8.self)

        var arr: [ASCII.Code] = []
        do throws(ASCII.Code.Error) {
            for byte in bytes {
                try arr.append(ASCII.Code(byte))
            }
        } catch {
            throw Error.invalidFormat(input)
        }

        var doubleColonPosition: Int? = nil
        var prevColonIndex: Int? = nil

        for index in arr.indices {
            if arr[index] == ASCII.Code.colon {
                if let prevIdx = prevColonIndex {

                    if doubleColonPosition != nil {
                        throw Error.multipleCompressions(input)
                    }

                    doubleColonPosition = prevIdx
                }
                prevColonIndex = index
            } else {
                prevColonIndex = nil
            }
        }

        func parseSegment(_ part: Swift.ArraySlice<ASCII.Code>) throws(Error) -> UInt16 {
            guard !part.isEmpty else {
                throw Error.invalidFormat(input)
            }
            if part.count > 4 {
                throw Error.invalidSegment(String(decoding: part.lazy.map(\.underlying), as: UTF8.self))
            }

            var value: UInt16 = 0
            for code in part {
                guard let nibble = code.hexValue else {
                    throw Error.invalidCharacter(input, code: code)
                }
                value = value * 16 + UInt16(nibble)
            }
            return value
        }

        func parseSegments(_ slice: Swift.ArraySlice<ASCII.Code>) throws(Error) -> [UInt16] {
            var segments: [UInt16] = []
            var start = slice.startIndex

            for index in slice.indices where slice[index] == ASCII.Code.colon {
                try segments.append(parseSegment(slice[start..<index]))
                start = slice.index(after: index)
            }
            try segments.append(parseSegment(slice[start...]))

            return segments
        }

        func parseIPv4Tail(_ slice: Swift.ArraySlice<ASCII.Code>) throws(Error) -> [UInt16] {
            func parseOctet(_ part: Swift.ArraySlice<ASCII.Code>) throws(Error) -> UInt16 {
                guard !part.isEmpty, part.count <= 3 else {
                    throw Error.invalidFormat(input)
                }
                var value: UInt16 = 0
                for code in part {
                    guard let digit = code.hexValue, digit <= 9 else {
                        throw Error.invalidCharacter(input, code: code)
                    }
                    value = value * 10 + UInt16(digit)
                }
                guard value <= 255 else {
                    throw Error.invalidSegment(String(decoding: part.lazy.map(\.underlying), as: UTF8.self))
                }
                return value
            }

            var octets: [UInt16] = []
            var start = slice.startIndex
            for index in slice.indices where slice[index] == ASCII.Code.period {
                try octets.append(parseOctet(slice[start..<index]))
                start = slice.index(after: index)
            }
            try octets.append(parseOctet(slice[start...]))

            guard octets.count == 4 else {
                throw Error.invalidFormat(input)
            }
            return [(octets[0] << 8) | octets[1], (octets[2] << 8) | octets[3]]
        }

        var ipv4Tail: [UInt16] = []
        var hexEnd = arr.endIndex
        if arr.contains(ASCII.Code.period) {
            guard let lastColon = arr.lastIndex(of: ASCII.Code.colon) else {
                throw Error.invalidFormat(input)
            }
            let tailStart = arr.index(after: lastColon)
            ipv4Tail = try parseIPv4Tail(arr[tailStart...])
            hexEnd = lastColon
        }
        let hexPart = arr[arr.startIndex..<hexEnd]

        var segments: [UInt16]

        if let dcPos = doubleColonPosition {

            let beforeDC = hexPart[hexPart.startIndex..<dcPos]
            let afterDCStart = Swift.min(hexPart.index(dcPos, offsetBy: 2), hexPart.endIndex)
            let afterDC = hexPart[afterDCStart..<hexPart.endIndex]

            let beforeSegments = beforeDC.isEmpty ? [] : try parseSegments(beforeDC)
            let afterSegments = afterDC.isEmpty ? [] : try parseSegments(afterDC)

            let totalSegments = beforeSegments.count + afterSegments.count + ipv4Tail.count
            let zerosNeeded = 8 - totalSegments

            guard zerosNeeded > 0 else {
                throw Error.tooManySegments(input)
            }

            segments =
                beforeSegments + Swift.Array(repeating: 0, count: zerosNeeded) + afterSegments
                + ipv4Tail
        } else {

            segments = try parseSegments(hexPart) + ipv4Tail
        }

        guard segments.count == 8 else {
            if segments.count < 8 {
                throw Error.tooFewSegments(input)
            } else {
                throw Error.tooManySegments(input)
            }
        }

        self.init(
            __unchecked: (),
            segments[0],
            segments[1],
            segments[2],
            segments[3],
            segments[4],
            segments[5],
            segments[6],
            segments[7]
        )
    }
}

extension RFC_4291.IPv6.Address: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.segments.0 == rhs.segments.0 && lhs.segments.1 == rhs.segments.1
            && lhs.segments.2 == rhs.segments.2 && lhs.segments.3 == rhs.segments.3
            && lhs.segments.4 == rhs.segments.4 && lhs.segments.5 == rhs.segments.5
            && lhs.segments.6 == rhs.segments.6 && lhs.segments.7 == rhs.segments.7
    }
}

extension RFC_4291.IPv6.Address: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(segments.0)
        hasher.combine(segments.1)
        hasher.combine(segments.2)
        hasher.combine(segments.3)
        hasher.combine(segments.4)
        hasher.combine(segments.5)
        hasher.combine(segments.6)
        hasher.combine(segments.7)
    }
}

extension RFC_4291.IPv6.Address: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {

        if lhs.segments.0 != rhs.segments.0 { return lhs.segments.0 < rhs.segments.0 }
        if lhs.segments.1 != rhs.segments.1 { return lhs.segments.1 < rhs.segments.1 }
        if lhs.segments.2 != rhs.segments.2 { return lhs.segments.2 < rhs.segments.2 }
        if lhs.segments.3 != rhs.segments.3 { return lhs.segments.3 < rhs.segments.3 }
        if lhs.segments.4 != rhs.segments.4 { return lhs.segments.4 < rhs.segments.4 }
        if lhs.segments.5 != rhs.segments.5 { return lhs.segments.5 < rhs.segments.5 }
        if lhs.segments.6 != rhs.segments.6 { return lhs.segments.6 < rhs.segments.6 }
        return lhs.segments.7 < rhs.segments.7
    }
}

extension RFC_4291.IPv6.Address {

    public static let unspecified = Self(__unchecked: (), 0, 0, 0, 0, 0, 0, 0, 0)

    public static let loopback = Self(__unchecked: (), 0, 0, 0, 0, 0, 0, 0, 1)
}
