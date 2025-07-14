import Network
@testable import NetworkKit
import XCTest

final class NetworkKitTests: XCTestCase, @unchecked Sendable {
    // MARK: - Array Extension Tests

    func testAsyncMap() async {
        let array = [1, 2, 3, 4, 5]
        let result = await array.asyncMap { value in
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value * 2
        }
        XCTAssertEqual(result, [2, 4, 6, 8, 10])
    }

    func testAsyncMapWithThrowing() async {
        let array = [1, 2, 3, 4, 5]
        do {
            _ = try await array.asyncMap { value in
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

    func testConcurrentMap() async throws {
        let array = [1, 2, 3, 4, 5]
        let result = try await array.concurrentMap { value in
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value * 2
        }
        XCTAssertEqual(result.sorted(), [2, 4, 6, 8, 10])
    }

    func testConcurrentMapWithThrowing() async {
        let array = [1, 2, 3, 4, 5]
        do {
            _ = try await array.concurrentMap { value in
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
    }

    func testDNSServerFromString() {
        let server4 = DNSServer(from: "8.8.8.8")
        let server6 = DNSServer(from: "2001:4860:4860::8888")
        let invalidServer = DNSServer(from: "invalid")

        XCTAssertNotNil(server4)
        XCTAssertNotNil(server6)
        XCTAssertNil(invalidServer)
    }

    func testDNSServerEquality() {
        let server1 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server2 = DNSServer(address: IPv4Address("8.8.8.8")!)
        let server3 = DNSServer(address: IPv4Address("8.8.4.4")!)

        XCTAssertEqual(server1, server2)
        XCTAssertNotEqual(server1, server3)
    }

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

    // MARK: - Interface Tests

    func testInterfaceAllInterfaces() {
        let allInterfaces = Interface.allInterfaces()
        XCTAssertFalse(allInterfaces.isEmpty)

        for interface in allInterfaces {
            XCTAssertFalse(interface.name.isEmpty)
            XCTAssertTrue(interface.family == .ipv4 || interface.family == .ipv6)
        }
    }

    func testInterfaceFiltering() {
        let loopbackInterfaces = Interface.interfaces { name, _ in
            name == "lo0"
        }

        for interface in loopbackInterfaces {
            XCTAssertEqual(interface.name, "lo0")
            XCTAssertTrue(interface.isLoopback)
        }
    }

    func testInterfaceNameList() {
        let interfaceNames = Interface.interfaceNameList()
        XCTAssertFalse(interfaceNames.isEmpty)

        for name in interfaceNames {
            XCTAssertFalse(name.isEmpty)
        }
    }

    func testInterfaceProperties() {
        let allInterfaces = Interface.allInterfaces()
        guard let interface = allInterfaces.first else {
            XCTFail("No interfaces found")
            return
        }

        // Test that basic properties are accessible
        _ = interface.isRunning
        _ = interface.isUp
        _ = interface.isLoopback
        _ = interface.supportsMulticast
        _ = interface.name
        _ = interface.family
        _ = interface.hardwareAddress
        _ = interface.address
        _ = interface.netmask
        _ = interface.broadcastAddress
    }

    func testInterfaceAddressBytes() {
        let allInterfaces = Interface.allInterfaces()

        for interface in allInterfaces {
            if let addressBytes = interface.addressBytes {
                switch interface.family {
                case .ipv4:
                    XCTAssertEqual(addressBytes.count, 4)
                case .ipv6:
                    XCTAssertEqual(addressBytes.count, 16)
                default:
                    break
                }
            }
        }
    }

    func testInterfaceEquality() {
        let interface1 = Interface(name: "en0", family: .ipv4, hardwareAddress: "00:11:22:33:44:55", address: "192.168.1.1", netmask: "255.255.255.0", running: true, up: true, loopback: false, multicastSupported: true, broadcastAddress: "192.168.1.255")
        let interface2 = Interface(name: "en0", family: .ipv4, hardwareAddress: "00:11:22:33:44:55", address: "192.168.1.1", netmask: "255.255.255.0", running: true, up: true, loopback: false, multicastSupported: true, broadcastAddress: "192.168.1.255")
        let interface3 = Interface(name: "en1", family: .ipv4, hardwareAddress: "00:11:22:33:44:55", address: "192.168.1.1", netmask: "255.255.255.0", running: true, up: true, loopback: false, multicastSupported: true, broadcastAddress: "192.168.1.255")

        XCTAssertEqual(interface1, interface2)
        XCTAssertNotEqual(interface1, interface3)
    }

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

    // MARK: - IP Address Range Tests

    func testIPAddressRangeInitialization() {
        let range4 = IPAddressRange(from: "192.168.1.0/24")
        let range6 = IPAddressRange(from: "2001:db8::/32")
        let invalidRange = IPAddressRange(from: "invalid")

        XCTAssertNotNil(range4)
        XCTAssertNotNil(range6)
        XCTAssertNil(invalidRange)

        XCTAssertEqual(range4?.networkPrefixLength, 24)
        XCTAssertEqual(range6?.networkPrefixLength, 32)
    }

    func testIPAddressRangeStringRepresentation() {
        let range = IPAddressRange(from: "192.168.1.0/24")!
        XCTAssertEqual(range.stringRepresentation, "192.168.1.0/24")
    }

    func testIPAddressRangeContains() {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        let ip1 = IPv4Address("192.168.1.100")!
        let ip2 = IPv4Address("192.168.2.100")!
        let ip3 = IPv6Address("2001:db8::1")!

        XCTAssertTrue(range.contains(ip1))
        XCTAssertFalse(range.contains(ip2))
        XCTAssertFalse(range.contains(ip3))
    }

    func testIPAddressRangeContainsString() {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        XCTAssertTrue(range.contains("192.168.1.100"))
        XCTAssertFalse(range.contains("192.168.2.100"))
        XCTAssertFalse(range.contains("invalid"))
    }

    func testIPAddressRangeSubnetMask() {
        let range4 = IPAddressRange(from: "192.168.1.0/24")!
        let range6 = IPAddressRange(from: "2001:db8::/32")!

        let mask4 = range4.subnetMask()
        let mask6 = range6.subnetMask()

        XCTAssertTrue(mask4 is IPv4Address)
        XCTAssertTrue(mask6 is IPv6Address)

        XCTAssertEqual(mask4.rawValue, IPv4Address("255.255.255.0")!.rawValue)
    }

    func testIPAddressRangeMaskedAddress() {
        let range = IPAddressRange(from: "192.168.1.100/24")!
        let maskedAddress = range.maskedAddress()

        XCTAssertEqual(maskedAddress.rawValue, IPv4Address("192.168.1.0")!.rawValue)
    }

    func testIPAddressRangeEquality() {
        let range1 = IPAddressRange(from: "192.168.1.0/24")!
        let range2 = IPAddressRange(from: "192.168.1.0/24")!
        let range3 = IPAddressRange(from: "192.168.1.0/16")!

        XCTAssertEqual(range1, range2)
        XCTAssertNotEqual(range1, range3)
    }

    func testIPAddressRangeCodable() throws {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        let encoded = try JSONEncoder().encode(range)
        let decoded = try JSONDecoder().decode(IPAddressRange.self, from: encoded)

        XCTAssertEqual(range, decoded)
    }

    // MARK: - WiFi SSID Tests

    @available(macOS 10.15, iOS 13.0, *)
    func testWiFiSSIDCurrentInterfaceName() {
        let interfaceName = WiFiSSID.currentInterfaceName()
        // This might be nil in testing environment
        if let name = interfaceName {
            XCTAssertFalse(name.isEmpty)
        }
    }

    @available(macOS 10.15, iOS 13.0, *)
    func testWiFiSSIDCurrentSSID() {
        let ssid = WiFiSSID.currentWiFiSSID()
        // This might be nil in testing environment
        if let ssid = ssid {
            XCTAssertFalse(ssid.isEmpty)
        }
    }

    @available(macOS 10.15, *)
    func testWiFiSSIDCurrentSSIDLegacy() {
        let ssid = WiFiSSID.currentSSIDLegacy()
        // This might be nil in testing environment
        if let ssid = ssid {
            XCTAssertFalse(ssid.isEmpty)
        }
    }

    // MARK: - Helper Types

    enum TestError: Error {
        case mockError
    }
}
