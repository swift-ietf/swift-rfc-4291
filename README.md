# swift-rfc-4291

Use this package when you need to read, store, compare or classify an IPv6 address, from its text or its 16 octets. Start from `RFC_4291.IPv6.Address`. For the short canonical text form, with the longest run of zero groups compressed, use swift-rfc-5952. For one namespace that also covers scoped addresses, use swift-ipv6-standard.

## Laws

- Text is up to eight groups of one to four hex digits separated by colons. `::` stands for at least one group of zeros and may appear once, at the start, in the middle or at the end. A single colon at either end is refused.
- The last 32 bits may be written as four dotted decimal numbers from 0 to 255, after a colon, as in `::ffff:192.168.1.1`. The groups, `::` and the dotted part must add up to exactly eight groups.
- Octets are in network byte order, two per group. `RFC_4291.IPv6.Address.init(binary:)` needs exactly 16 bytes. `RFC_4291.IPv6.Address.parse(from:)` takes the first 16 and leaves the rest.
- The default text output is fully expanded: eight groups of four lowercase hex digits, 39 characters, with no `::`. The IPv4-mixed output writes the first six groups without leading zeros and without `::`, then the last 32 bits as dotted decimal.
- Reading from a cursor takes the longest run of hex digits, colons and dots, so it stops before a `]` or a space. If that run isn't a valid address, the cursor goes back to where it started.
- Addresses order group by group from the left, as numbers.
- `RFC_4291.IPv6.Address.is` classifies by prefix: multicast is `ff00::/8`, link-local is `fe80::/10` and unique local is `fc00::/7`. Global unicast is every address that is none of these and is neither unspecified nor loopback, so documentation and IPv4-mapped addresses count as global unicast.
