import Network
@testable import NetworkKit
import XCTest

final class NetworkKitDNSResolverTests: XCTestCase {
    // MARK: - DNS Resolver Tests

    func testDNSResolveWithIPAddress() async throws {
        let endpoints = [
            Endpoint(host: .ipv4(IPv4Address("8.8.8.8")!), port: 53),
            Endpoint(host: .ipv6(IPv6Address("2001:4860:4860::8888")!), port: 53),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 2)
        for result in results {
            switch result {
            case let .success(endpoint):
                XCTAssertTrue(endpoint.hasHostAsIPAddress())
            case .failure:
                XCTFail("Should not fail for IP addresses")
            case .none:
                XCTFail("Should not be nil")
            }
        }
    }

    func testDNSResolveWithHostnames() async throws {
        let endpoints = [
            Endpoint(host: .name("www.apple.com", nil), port: 80),
            Endpoint(host: .name("www.google.com", nil), port: 443),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 2)
        for result in results {
            switch result {
            case let .success(endpoint):
                XCTAssertTrue(endpoint.hasHostAsIPAddress())
            case let .failure(error):
                XCTFail("DNS resolution failed: \(error.localizedDescription)")
            case .none:
                XCTFail("Should not be nil")
            }
        }
    }

    func testDNSResolveWithNilEndpoints() async throws {
        let endpoints: [Endpoint?] = [nil, nil]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 2)
        for result in results {
            XCTAssertNil(result)
        }
    }

    func testDNSResolveWithMixedEndpoints() async throws {
        let endpoints: [Endpoint?] = [
            Endpoint(host: .ipv4(IPv4Address("8.8.8.8")!), port: 53),
            nil,
            Endpoint(host: .name("www.apple.com", nil), port: 80),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[0])
        XCTAssertNil(results[1])
        XCTAssertNotNil(results[2])
    }

    // MARK: - DNS Resolution Error Tests

    func testDNSResolveWithInvalidHostname() async throws {
        let endpoints = [
            Endpoint(host: .name("this-domain-definitely-does-not-exist-12345.invalid", nil), port: 80),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 1)
        if let result = results[0] {
            switch result {
            case .success:
                XCTFail("Should not succeed for invalid hostname")
            case let .failure(error):
                XCTAssertNotNil(error.errorDescription)
                XCTAssertFalse(error.address.isEmpty)
            }
        }
    }

    func testDNSResolveWithEmptyArray() async throws {
        let endpoints: [Endpoint?] = []

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 0)
    }

    func testDNSResolvePreservesOrder() async throws {
        let endpoints = [
            Endpoint(host: .ipv4(IPv4Address("8.8.8.8")!), port: 53),
            Endpoint(host: .name("www.apple.com", nil), port: 80),
            Endpoint(host: .ipv6(IPv6Address("2001:4860:4860::8888")!), port: 53),
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        XCTAssertEqual(results.count, 3)

        // Verify first result is IPv4
        if let firstResult = results[0], case let .success(endpoint) = firstResult {
            switch endpoint.host {
            case .ipv4:
                break // Expected
            default:
                XCTFail("First result should be IPv4")
            }
        }

        // Verify third result is IPv6
        if let thirdResult = results[2], case let .success(endpoint) = thirdResult {
            switch endpoint.host {
            case .ipv6:
                break // Expected
            default:
                XCTFail("Third result should be IPv6")
            }
        }
    }

    func testDNSResolutionError() {
        let error = DNSResolutionError(errorCode: -2, address: "test.invalid")

        XCTAssertEqual(error.errorCode, -2)
        XCTAssertEqual(error.address, "test.invalid")
        XCTAssertNotNil(error.errorDescription)
    }
}
