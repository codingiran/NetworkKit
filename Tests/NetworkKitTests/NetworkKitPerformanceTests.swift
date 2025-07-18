import Network
@testable import NetworkKit
import XCTest

final class NetworkKitPerformanceTests: XCTestCase {
    // MARK: - Array Extension Performance Tests

    func testAsyncMapPerformance() {
        let largeArray = Array(1 ... 1000)

        measure {
            let expectation = XCTestExpectation(description: "AsyncMap Performance")

            Task {
                let result = await largeArray.asyncMap { value in
                    value * 2
                }
                XCTAssertEqual(result.count, 1000)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    func testConcurrentMapPerformance() {
        let largeArray = Array(1 ... 1000)

        measure {
            let expectation = XCTestExpectation(description: "ConcurrentMap Performance")

            Task {
                do {
                    let result = try await largeArray.concurrentMap { value in
                        value * 2
                    }
                    XCTAssertEqual(result.count, 1000)
                    expectation.fulfill()
                } catch {
                    XCTFail("ConcurrentMap failed: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - DNS Resolution Performance Tests

    func testDNSResolutionPerformance() {
        let endpoints = [
            Endpoint(host: .name("www.apple.com", nil), port: 80),
            Endpoint(host: .name("www.google.com", nil), port: 443),
            Endpoint(host: .name("www.github.com", nil), port: 443),
            Endpoint(host: .name("www.stackoverflow.com", nil), port: 443),
            Endpoint(host: .name("www.microsoft.com", nil), port: 443),
        ]

        measure {
            let expectation = XCTestExpectation(description: "DNS Resolution Performance")

            Task {
                do {
                    let results = try await DNSResolver.resolveAsync(endpoints: endpoints)
                    XCTAssertEqual(results.count, 5)
                    expectation.fulfill()
                } catch {
                    XCTFail("DNS resolution failed: \(error)")
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 30.0)
        }
    }

    // MARK: - Interface Discovery Performance Tests

    func testInterfaceDiscoveryPerformance() {
        measure {
            let _ = Ifaddrs.ifaddrsList()
        }
    }

    // MARK: - IP Address Range Performance Tests

    func testIPAddressRangeContainsPerformance() {
        let range = IPAddressRange(from: "192.168.1.0/24")!
        let testIPs = (1 ... 254).map { "192.168.1.\($0)" }

        measure {
            for ip in testIPs {
                let _ = range.contains(ip)
            }
        }
    }

    func testIPAddressRangeSubnetMaskPerformance() {
        let ranges = [
            IPAddressRange(from: "192.168.1.0/24")!,
            IPAddressRange(from: "10.0.0.0/8")!,
            IPAddressRange(from: "172.16.0.0/12")!,
            IPAddressRange(from: "2001:db8::/32")!,
        ]

        measure {
            for range in ranges {
                let _ = range.subnetMask()
                let _ = range.maskedAddress()
            }
        }
    }

    // MARK: - Endpoint Parsing Performance Tests

    func testEndpointParsingPerformance() {
        let endpointStrings = [
            "example.com:80",
            "192.168.1.1:8080",
            "[::1]:443",
            "github.com:22",
            "8.8.8.8:53",
            "[2001:4860:4860::8888]:53",
        ]

        measure {
            for endpointString in endpointStrings {
                let _ = Endpoint(from: endpointString)
            }
        }
    }

    // MARK: - IP Address Creation Performance Tests

    func testIPAddressCreationPerformance() {
        let ipv4Addresses = [
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "8.8.8.8",
            "1.1.1.1",
        ]

        let ipv6Addresses = [
            "::1",
            "fe80::1",
            "2001:db8::1",
            "2001:4860:4860::8888",
            "fd00::1",
        ]

        measure {
            for address in ipv4Addresses {
                let _ = IPv4Address(address)
            }

            for address in ipv6Addresses {
                let _ = IPv6Address(address)
            }
        }
    }

    // MARK: - Codable Performance Tests

    func testEndpointCodablePerformance() {
        let endpoints = [
            Endpoint(host: .name("example.com", nil), port: 80),
            Endpoint(host: .ipv4(IPv4Address("192.168.1.1")!), port: 8080),
            Endpoint(host: .ipv6(IPv6Address("::1")!), port: 443),
        ]

        measure {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            for endpoint in endpoints {
                do {
                    let data = try encoder.encode(endpoint)
                    let _ = try decoder.decode(Endpoint.self, from: data)
                } catch {
                    XCTFail("Codable test failed: \(error)")
                }
            }
        }
    }

    func testIPAddressRangeCodablePerformance() {
        let ranges = [
            IPAddressRange(from: "192.168.1.0/24")!,
            IPAddressRange(from: "10.0.0.0/8")!,
            IPAddressRange(from: "2001:db8::/32")!,
        ]

        measure {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            for range in ranges {
                do {
                    let data = try encoder.encode(range)
                    let _ = try decoder.decode(IPAddressRange.self, from: data)
                } catch {
                    XCTFail("Codable test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Large Dataset Tests

    func testLargeIPAddressRangePerformance() {
        let largeRange = IPAddressRange(from: "0.0.0.0/0")! // Entire IPv4 space
        let testIPs = [
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "8.8.8.8",
            "1.1.1.1",
            "127.0.0.1",
            "169.254.1.1",
            "224.0.0.1",
        ]

        measure {
            for ip in testIPs {
                let _ = largeRange.contains(ip)
            }
        }
    }

    func testMultipleInterfaceQueriesPerformance() {
        measure {
            for _ in 0 ..< 100 {
                let _ = Ifaddrs.ifaddrsList()
            }
        }
    }
}
