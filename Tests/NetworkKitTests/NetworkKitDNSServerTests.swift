import Network
@testable import NetworkKit
import XCTest

final class NetworkKitDNSServerTests: XCTestCase {
    // MARK: - DNS Server Tests

    func testDNSServerInitialization() {
        let ipv4Address = IPv4Address("8.8.8.8")!
        let ipv6Address = IPv6Address("2001:4860:4860::8888")!

        let server4 = DNSServer(address: ipv4Address)
        let server6 = DNSServer(address: ipv6Address)

        XCTAssertEqual(server4.address.rawValue, ipv4Address.rawValue)
        XCTAssertEqual(server6.address.rawValue, ipv6Address.rawValue)
    }

    func testDNSServerStringRepresentation() {
        let server = DNSServer(address: IPv4Address("8.8.8.8")!)
        XCTAssertEqual(server.stringRepresentation, "8.8.8.8")

        let server6 = DNSServer(address: IPv6Address("2001:4860:4860::8888")!)
        XCTAssertEqual(server6.stringRepresentation, "2001:4860:4860::8888")
    }

    func testDNSServerFromString() {
        let server4 = DNSServer(from: "8.8.8.8")
        let server6 = DNSServer(from: "2001:4860:4860::8888")
        let invalidServer = DNSServer(from: "invalid")

        XCTAssertNotNil(server4)
        XCTAssertNotNil(server6)
        XCTAssertNil(invalidServer)

        XCTAssertEqual(server4?.stringRepresentation, "8.8.8.8")
        XCTAssertEqual(server6?.stringRepresentation, "2001:4860:4860::8888")
    }

    func testDNSServerEquality() {
        let server1 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server2 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server3 = DNSServer(address: IPv4Address("8.8.4.4")!)

        XCTAssertEqual(server1, server2)
        XCTAssertNotEqual(server1, server3)
    }

    // MARK: - Additional DNS Server Tests

    func testDNSServerFromStringEdgeCases() {
        // Test various invalid formats
        let invalidCases = [
            "",
            "256.256.256.256",
            "192.168.1.1.1",
            "not-an-ip",
            "::gggg",
            "192.168.1.1:53", // Port included (not supported)
            "300.1.1.1", // Invalid IPv4 octet
            "192.168.1.", // Trailing dot
            "192.168..1", // Double dot
            "gggg::", // Invalid IPv6 hex
        ]

        for invalidCase in invalidCases {
            let server = DNSServer(from: invalidCase)
            XCTAssertNil(server, "Should be nil for invalid input: \(invalidCase)")
        }
    }

    func testDNSServerWithCommonDNSServers() {
        let commonDNSServers = [
            ("8.8.8.8", "Google DNS"),
            ("8.8.4.4", "Google DNS"),
            ("1.1.1.1", "Cloudflare DNS"),
            ("1.0.0.1", "Cloudflare DNS"),
            ("208.67.222.222", "OpenDNS"),
            ("208.67.220.220", "OpenDNS"),
            ("2001:4860:4860::8888", "Google DNS IPv6"),
            ("2001:4860:4860::8844", "Google DNS IPv6"),
            ("2606:4700:4700::1111", "Cloudflare DNS IPv6"),
            ("2606:4700:4700::1001", "Cloudflare DNS IPv6"),
        ]

        for (ip, description) in commonDNSServers {
            let server = DNSServer(from: ip)
            XCTAssertNotNil(server, "Should create server for \(description): \(ip)")
            XCTAssertEqual(server?.stringRepresentation, ip)
        }
    }

    func testDNSServerEquatableProperties() {
        let server1 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server2 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server3 = DNSServer(address: IPv4Address("8.8.4.4")!)

        // Test reflexivity
        XCTAssertEqual(server1, server1)

        // Test symmetry
        XCTAssertEqual(server1, server2)
        XCTAssertEqual(server2, server1)

        // Test inequality
        XCTAssertNotEqual(server1, server3)
        XCTAssertNotEqual(server3, server1)
    }

    func testDNSServerRoundTripConversion() {
        let originalServers = [
            DNSServer(address: IPv4Address("8.8.8.8")!),
            DNSServer(address: IPv6Address("2001:4860:4860::8888")!),
            DNSServer(address: IPv4Address("1.1.1.1")!),
            DNSServer(address: IPv6Address("::1")!),
        ]

        for originalServer in originalServers {
            let stringRepresentation = originalServer.stringRepresentation
            let reconstructedServer = DNSServer(from: stringRepresentation)

            XCTAssertNotNil(reconstructedServer)
            XCTAssertEqual(originalServer, reconstructedServer!)
            XCTAssertEqual(originalServer.stringRepresentation, reconstructedServer!.stringRepresentation)
        }
    }
}
