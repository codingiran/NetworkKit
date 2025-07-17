import Network
@testable import NetworkKit
import XCTest

final class NetworkKitTests: XCTestCase, @unchecked Sendable {
    // MARK: - Basic NetworkKit Tests

    func testNetworkKitVersion() {
        // Test that the version constant is accessible and not empty
        XCTAssertFalse(NetworkKit.version.isEmpty)
        XCTAssertEqual(NetworkKit.version, "0.2.1")
    }

    func testNetworkKitImports() {
        // Test that all the core types are accessible
        XCTAssertNotNil([Int].self)
        XCTAssertNotNil(DNSResolver.self)
        XCTAssertNotNil(DNSServer.self)
        XCTAssertNotNil(Endpoint.self)
        XCTAssertNotNil(Ifaddrs.self)
        XCTAssertNotNil(IPAddressRange.self)
        XCTAssertNotNil(WiFiSSID.self)
    }

    func testNetworkKitProtocolConformance() {
        // Test that key types conform to expected protocols
        let endpoint = Endpoint(host: .name("example.com", nil), port: 80)
        let dnsServer = DNSServer(address: IPv4Address("8.8.8.8")!)
        let ipRange = IPAddressRange(from: "192.168.1.0/24")!

        // Test Sendable conformance (these should compile without issues)
        Task {
            _ = endpoint
            _ = dnsServer
            _ = ipRange
        }

        // Test basic functionality is working
        XCTAssertEqual(endpoint.stringRepresentation, "example.com:80")
        XCTAssertEqual(dnsServer.stringRepresentation, "8.8.8.8")
        XCTAssertEqual(ipRange.stringRepresentation, "192.168.1.0/24")
    }

    func testNetworkKitCodableSupport() throws {
        // Test that key types support JSON encoding/decoding
        let endpoint = Endpoint(host: .name("example.com", nil), port: 80)
        let ipRange = IPAddressRange(from: "192.168.1.0/24")!
        let ipv4Address = IPv4Address("192.168.1.1")!
        let ipv6Address = IPv6Address("2001:db8::1")!

        // Test encoding/decoding
        let endpointData = try JSONEncoder().encode(endpoint)
        let decodedEndpoint = try JSONDecoder().decode(Endpoint.self, from: endpointData)
        XCTAssertEqual(endpoint, decodedEndpoint)

        let rangeData = try JSONEncoder().encode(ipRange)
        let decodedRange = try JSONDecoder().decode(IPAddressRange.self, from: rangeData)
        XCTAssertEqual(ipRange, decodedRange)

        let ipv4Data = try JSONEncoder().encode(ipv4Address)
        let decodedIPv4 = try JSONDecoder().decode(IPv4Address.self, from: ipv4Data)
        XCTAssertEqual(ipv4Address, decodedIPv4)

        let ipv6Data = try JSONEncoder().encode(ipv6Address)
        let decodedIPv6 = try JSONDecoder().decode(IPv6Address.self, from: ipv6Data)
        XCTAssertEqual(ipv6Address, decodedIPv6)
    }

    func testNetworkKitAsyncSupport() async throws {
        // Test that async/await functionality works
        let endpoints = [
            Endpoint(host: .ipv4(IPv4Address("8.8.8.8")!), port: 53),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)
        XCTAssertEqual(results.count, 1)

        // Test array async extensions
        let numbers = [1, 2, 3, 4, 5]
        let doubled = await numbers.asyncMap { $0 * 2 }
        XCTAssertEqual(doubled, [2, 4, 6, 8, 10])

        let concurrent = try await numbers.concurrentMap { $0 * 3 }
        XCTAssertEqual(concurrent.sorted(), [3, 6, 9, 12, 15])
    }

    func testNetworkKitErrorHandling() async {
        // Test that error handling works properly
        let numbers = [1, 2, 3, 4, 5]

        do {
            _ = try await numbers.asyncMap { value in
                if value == 3 {
                    throw TestError.mockError
                }
                return value * 2
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }

        do {
            _ = try await numbers.concurrentMap { value in
                if value == 3 {
                    throw TestError.mockError
                }
                return value * 2
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Helper Types

    enum TestError: Error {
        case mockError
    }
}
