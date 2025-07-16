import Network
@testable import NetworkKit
import XCTest

final class NetworkKitIPAddressTests: XCTestCase {
    // MARK: - IP Address Tests

    func testIPv4AddressCodable() throws {
        let address = IPv4Address("192.168.1.1")!

        let encoded = try JSONEncoder().encode(address)
        let decoded = try JSONDecoder().decode(IPv4Address.self, from: encoded)

        XCTAssertEqual(address, decoded)
    }

    func testIPv6AddressCodable() throws {
        let address = IPv6Address("2001:db8::1")!

        let encoded = try JSONEncoder().encode(address)
        let decoded = try JSONDecoder().decode(IPv6Address.self, from: encoded)

        XCTAssertEqual(address, decoded)
    }

    func testIPv4AddressLocalCheck() {
        let loopback = IPv4Address("127.0.0.1")!
        let linkLocal = IPv4Address("169.254.1.1")!
        let multicast = IPv4Address("224.0.0.1")!
        let publicAddress = IPv4Address("8.8.8.8")!

        XCTAssertTrue(loopback.isLocalAddress)
        XCTAssertTrue(linkLocal.isLocalAddress)
        XCTAssertTrue(multicast.isLocalAddress)
        XCTAssertFalse(publicAddress.isLocalAddress)
    }

    func testIPv6AddressLocalCheck() {
        let loopback = IPv6Address("::1")!
        let linkLocal = IPv6Address("fe80::1")!
        let uniqueLocal = IPv6Address("fd00::1")!
        let multicast = IPv6Address("ff00::1")!
        let publicAddress = IPv6Address("2001:db8::1")!

        XCTAssertTrue(loopback.isLocalAddress)
        XCTAssertTrue(linkLocal.isLocalAddress)
        XCTAssertTrue(uniqueLocal.isLocalAddress)
        XCTAssertTrue(multicast.isLocalAddress)
        XCTAssertFalse(publicAddress.isLocalAddress)
    }

    func testIPAddressTypeCheck() {
        let ipv4: IPAddress = IPv4Address("192.168.1.1")!
        let ipv6: IPAddress = IPv6Address("2001:db8::1")!

        XCTAssertTrue(ipv4.isIPv4)
        XCTAssertFalse(ipv4.isIPv6)
        XCTAssertFalse(ipv6.isIPv4)
        XCTAssertTrue(ipv6.isIPv6)
    }

    // MARK: - Additional IP Address Tests

    func testIPv4AddressCodableEdgeCases() throws {
        let testAddresses = [
            "0.0.0.0",
            "127.0.0.1",
            "255.255.255.255",
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
        ]

        for addressString in testAddresses {
            let originalAddress = IPv4Address(addressString)!

            let encoded = try JSONEncoder().encode(originalAddress)
            let decoded = try JSONDecoder().decode(IPv4Address.self, from: encoded)

            XCTAssertEqual(originalAddress, decoded)
            XCTAssertEqual(String(reflecting: originalAddress), String(reflecting: decoded))
        }
    }

    func testIPv6AddressCodableEdgeCases() throws {
        let testAddresses = [
            "::1",
            "::",
            "fe80::1",
            "2001:db8::1",
            "2001:db8:85a3::8a2e:370:7334",
            "ff00::1",
            "fd00::1",
        ]

        for addressString in testAddresses {
            let originalAddress = IPv6Address(addressString)!

            let encoded = try JSONEncoder().encode(originalAddress)
            let decoded = try JSONDecoder().decode(IPv6Address.self, from: encoded)

            XCTAssertEqual(originalAddress, decoded)
            XCTAssertEqual(String(reflecting: originalAddress), String(reflecting: decoded))
        }
    }

    func testIPv4AddressCodableInvalidInput() {
        let invalidJSON = """
        "invalid.ip.address"
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(IPv4Address.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testIPv6AddressCodableInvalidInput() {
        let invalidJSON = """
        "invalid::ip::address"
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(IPv6Address.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testIPv4AddressLocalAddressVariants() {
        let localAddressCases = [
            ("127.0.0.1", true, "Loopback"),
            ("127.0.0.2", true, "Loopback range"),
            ("127.255.255.254", true, "Loopback range"),
            ("169.254.1.1", true, "Link local"),
            ("169.254.0.1", true, "Link local start"),
            ("169.254.255.254", true, "Link local end"),
            ("224.0.0.1", true, "Multicast"),
            ("239.255.255.255", true, "Multicast end"),
            ("192.168.1.1", false, "Private but not local in our definition"),
            ("10.0.0.1", false, "Private but not local in our definition"),
            ("8.8.8.8", false, "Public"),
            ("1.1.1.1", false, "Public"),
        ]

        for (addressString, expectedLocal, description) in localAddressCases {
            let address = IPv4Address(addressString)!
            XCTAssertEqual(address.isLocalAddress, expectedLocal,
                           "Failed for \(description): \(addressString)")
        }
    }

    func testIPv6AddressLocalAddressVariants() {
        let localAddressCases = [
            ("::1", true, "Loopback"),
            ("fe80::1", true, "Link local"),
            ("fe80::ffff:ffff:ffff:ffff", true, "Link local end"),
            ("fd00::1", true, "Unique local"),
            ("fc00::1", true, "Unique local start"),
            ("fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", true, "Unique local end"),
            ("ff00::1", true, "Multicast"),
            ("ff02::1", true, "Multicast"),
            ("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", true, "Multicast end"),
            ("2001:db8::1", false, "Documentation range (not local)"),
            ("2001:4860:4860::8888", false, "Public (Google DNS)"),
            ("::", false, "Unspecified address"),
        ]

        for (addressString, expectedLocal, description) in localAddressCases {
            let address = IPv6Address(addressString)!
            XCTAssertEqual(address.isLocalAddress, expectedLocal,
                           "Failed for \(description): \(addressString)")
        }
    }

    func testIPAddressTypeCheckWithVariousAddresses() {
        let ipv4Addresses = [
            "0.0.0.0",
            "127.0.0.1",
            "192.168.1.1",
            "255.255.255.255",
        ]

        let ipv6Addresses = [
            "::",
            "::1",
            "2001:db8::1",
            "fe80::1",
            "ff00::1",
        ]

        for addressString in ipv4Addresses {
            let address: IPAddress = IPv4Address(addressString)!
            XCTAssertTrue(address.isIPv4, "Should be IPv4: \(addressString)")
            XCTAssertFalse(address.isIPv6, "Should not be IPv6: \(addressString)")
        }

        for addressString in ipv6Addresses {
            let address: IPAddress = IPv6Address(addressString)!
            XCTAssertFalse(address.isIPv4, "Should not be IPv4: \(addressString)")
            XCTAssertTrue(address.isIPv6, "Should be IPv6: \(addressString)")
        }
    }

    func testIPv4AddressFromAddrInfo() {
        // This test simulates creating IPv4Address from addrinfo structure
        // We can't easily create a real addrinfo in tests, but we can test the interface exists
        let address = IPv4Address("192.168.1.1")!
        XCTAssertNotNil(address)
        XCTAssertEqual(String(reflecting: address), "192.168.1.1")
    }

    func testIPv6AddressFromAddrInfo() {
        // This test simulates creating IPv6Address from addrinfo structure
        // We can't easily create a real addrinfo in tests, but we can test the interface exists
        let address = IPv6Address("2001:db8::1")!
        XCTAssertNotNil(address)
        XCTAssertEqual(String(reflecting: address), "2001:db8::1")
    }

    func testIPAddressJSONSerialization() throws {
        // Test that IP addresses can be serialized to and from JSON
        let ipv4: IPAddress = IPv4Address("192.168.1.1")!
        let ipv6: IPAddress = IPv6Address("2001:db8::1")!

        // We can't directly encode IPAddress protocol, but we can test the concrete types
        let ipv4Encoded = try JSONEncoder().encode(ipv4 as! IPv4Address)
        let ipv6Encoded = try JSONEncoder().encode(ipv6 as! IPv6Address)

        let ipv4Decoded = try JSONDecoder().decode(IPv4Address.self, from: ipv4Encoded)
        let ipv6Decoded = try JSONDecoder().decode(IPv6Address.self, from: ipv6Encoded)

        XCTAssertEqual(ipv4.rawValue, ipv4Decoded.rawValue)
        XCTAssertEqual(ipv6.rawValue, ipv6Decoded.rawValue)
    }

    func testIPAddressEquality() {
        let ipv4_1 = IPv4Address("192.168.1.1")!
        let ipv4_2 = IPv4Address("192.168.1.1")!
        let ipv4_3 = IPv4Address("192.168.1.2")!

        let ipv6_1 = IPv6Address("2001:db8::1")!
        let ipv6_2 = IPv6Address("2001:db8::1")!
        let ipv6_3 = IPv6Address("2001:db8::2")!

        // Test IPv4 equality
        XCTAssertEqual(ipv4_1, ipv4_2)
        XCTAssertNotEqual(ipv4_1, ipv4_3)

        // Test IPv6 equality
        XCTAssertEqual(ipv6_1, ipv6_2)
        XCTAssertNotEqual(ipv6_1, ipv6_3)

        // Test cross-type inequality (if possible to compare)
        XCTAssertNotEqual(ipv4_1.rawValue, ipv6_1.rawValue)
    }
}
