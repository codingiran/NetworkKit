import Network
@testable import NetworkKit
import XCTest

final class NetworkKitEndpointTests: XCTestCase {
    // MARK: - Endpoint Tests

    func testEndpointInitialization() {
        let endpoint = Endpoint(host: .name("example.com", nil), port: 80)
        XCTAssertEqual(endpoint.host, .name("example.com", nil))
        XCTAssertEqual(endpoint.port, 80)
    }

    func testEndpointStringRepresentation() {
        let endpoint1 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint2 = Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080)
        let endpoint3 = Endpoint(host: .ipv6(IPv6Address("::1")!), port: 443)

        XCTAssertEqual(endpoint1.stringRepresentation, "example.com:80")
        XCTAssertEqual(endpoint2.stringRepresentation, "192.168.1.1:8080")
        XCTAssertEqual(endpoint3.stringRepresentation, "[::1]:443")
    }

    func testEndpointFromString() {
        let endpoint1 = Endpoint(from: "example.com:80")
        let endpoint2 = Endpoint(from: "192.168.1.1:8080")
        let endpoint3 = Endpoint(from: "[::1]:443")
        let invalidEndpoint = Endpoint(from: "invalid")

        XCTAssertNotNil(endpoint1)
        XCTAssertNotNil(endpoint2)
        XCTAssertNotNil(endpoint3)
        XCTAssertNil(invalidEndpoint)

        XCTAssertEqual(endpoint1?.stringRepresentation, "example.com:80")
        XCTAssertEqual(endpoint2?.stringRepresentation, "192.168.1.1:8080")
        XCTAssertEqual(endpoint3?.stringRepresentation, "[::1]:443")
    }

    func testEndpointHasHostAsIPAddress() {
        let endpoint1 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint2 = Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080)
        let endpoint3 = Endpoint(host: .ipv6(IPv6Address("::1")!), port: 443)

        XCTAssertFalse(endpoint1.hasHostAsIPAddress())
        XCTAssertTrue(endpoint2.hasHostAsIPAddress())
        XCTAssertTrue(endpoint3.hasHostAsIPAddress())
    }

    func testEndpointHostname() {
        let endpoint1 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint2 = Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080)

        XCTAssertEqual(endpoint1.hostname(), "example.com")
        XCTAssertNil(endpoint2.hostname())
    }

    func testEndpointEquality() {
        let endpoint1 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint2 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint3 = Endpoint(host: .name("example.com", nil), port: 443)

        XCTAssertEqual(endpoint1, endpoint2)
        XCTAssertNotEqual(endpoint1, endpoint3)
    }

    func testEndpointCodable() throws {
        let endpoint = Endpoint(host: .name("example.com", nil), port: 80)

        let encoded = try JSONEncoder().encode(endpoint)
        let decoded = try JSONDecoder().decode(Endpoint.self, from: encoded)

        XCTAssertEqual(endpoint, decoded)
    }

    // MARK: - Additional Endpoint Tests

    func testEndpointFromStringEdgeCases() {
        let validCases = [
            ("localhost:3000", "localhost:3000"),
            ("127.0.0.1:8080", "127.0.0.1:8080"),
            ("[::1]:443", "[::1]:443"),
            ("[2001:db8::1]:8080", "[2001:db8::1]:8080"),
            ("example-site.com:80", "example-site.com:80"),
            ("sub.domain.example.com:22", "sub.domain.example.com:22"),
        ]

        for (input, expected) in validCases {
            let endpoint = Endpoint(from: input)
            XCTAssertNotNil(endpoint, "Should parse valid endpoint: \(input)")
            XCTAssertEqual(endpoint?.stringRepresentation, expected)
        }

        let invalidCases = [
            "",
            "no-port",
            ":80",
            "example.com:",
            "example.com:99999",
            "[::1:443", // Missing closing bracket
            "::1]:443", // Missing opening bracket
            "[]:443",
            "example.com:abc",
            "256.256.256.256:80",
        ]

        for invalidCase in invalidCases {
            let endpoint = Endpoint(from: invalidCase)
            XCTAssertNil(endpoint, "Should not parse invalid endpoint: \(invalidCase)")
        }
    }

    func testEndpointHashability() {
        let endpoint1 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint2 = Endpoint(host: .name("example.com", nil), port: 80)
        let endpoint3 = Endpoint(host: .name("example.com", nil), port: 443)

        let endpointSet: Set<Endpoint> = [endpoint1, endpoint2, endpoint3]

        // Should only contain 2 unique endpoints
        XCTAssertEqual(endpointSet.count, 2)
        XCTAssertTrue(endpointSet.contains(endpoint1))
        XCTAssertTrue(endpointSet.contains(endpoint2))
        XCTAssertTrue(endpointSet.contains(endpoint3))
    }

    func testEndpointRoundTripConversion() {
        let testEndpoints = [
            Endpoint(host: .name("example.com", nil), port: 80),
            Endpoint(host: .name("sub.domain.example.com", nil), port: 443),
            Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080),
            Endpoint(host: .ipv4(IPv4Address("10.0.0.1")!), port: 22),
            Endpoint(host: .ipv6(IPv6Address("::1")!), port: 443),
            Endpoint(host: .ipv6(IPv6Address("2001:db8::1")!), port: 8080),
        ]

        for originalEndpoint in testEndpoints {
            let stringRepresentation = originalEndpoint.stringRepresentation
            let reconstructedEndpoint = Endpoint(from: stringRepresentation)

            XCTAssertNotNil(reconstructedEndpoint)
            XCTAssertEqual(originalEndpoint, reconstructedEndpoint!)
            XCTAssertEqual(originalEndpoint.stringRepresentation, reconstructedEndpoint!.stringRepresentation)
        }
    }

    func testEndpointCodableWithVariousTypes() throws {
        let endpoints = [
            Endpoint(host: .name("api.example.com", nil), port: 443),
            Endpoint(host: .ipv4(IPv4Address("203.0.113.1")!), port: 80),
            Endpoint(host: .ipv6(IPv6Address("2001:db8:85a3::8a2e:370:7334")!), port: 8080),
        ]

        for endpoint in endpoints {
            let encoded = try JSONEncoder().encode(endpoint)
            let decoded = try JSONDecoder().decode(Endpoint.self, from: encoded)

            XCTAssertEqual(endpoint, decoded)
            XCTAssertEqual(endpoint.stringRepresentation, decoded.stringRepresentation)
            XCTAssertEqual(endpoint.hasHostAsIPAddress(), decoded.hasHostAsIPAddress())
            XCTAssertEqual(endpoint.hostname(), decoded.hostname())
        }
    }

    func testEndpointWithDifferentPorts() {
        let commonPorts = [21, 22, 23, 25, 53, 80, 110, 143, 443, 993, 995, 8080, 8443, 9000]

        for port in commonPorts {
            let endpoint = Endpoint(host: .name("example.com", nil), port: NWEndpoint.Port(rawValue: UInt16(port))!)
            XCTAssertEqual(endpoint.port.rawValue, UInt16(port))
            XCTAssertEqual(endpoint.stringRepresentation, "example.com:\(port)")
        }
    }

    func testEndpointHostnameExtractionVariants() {
        let hostnameTestCases = [
            (Endpoint(host: .name("example.com", nil), port: 80), "example.com"),
            (Endpoint(host: .name("sub.domain.example.com", nil), port: 443), "sub.domain.example.com"),
            (Endpoint(host: .name("localhost", nil), port: 3000), "localhost"),
            (Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080), nil),
            (Endpoint(host: .ipv6(IPv6Address("::1")!), port: 443), nil),
        ]

        for (endpoint, expectedHostname) in hostnameTestCases {
            XCTAssertEqual(endpoint.hostname(), expectedHostname)
        }
    }
}
