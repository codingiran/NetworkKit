import Network
@testable import NetworkKit
import XCTest

final class NetworkKitInterfaceTests: XCTestCase {
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

    // MARK: - Additional Interface Tests

    func testInterfaceInitialization() {
        let interface = Interface(
            name: "test0",
            family: .ipv4,
            hardwareAddress: "aa:bb:cc:dd:ee:ff",
            address: "10.0.0.1",
            netmask: "255.255.255.0",
            running: true,
            up: true,
            loopback: false,
            multicastSupported: true,
            broadcastAddress: "10.0.0.255"
        )

        XCTAssertEqual(interface.name, "test0")
        XCTAssertEqual(interface.family, .ipv4)
        XCTAssertEqual(interface.hardwareAddress, "aa:bb:cc:dd:ee:ff")
        XCTAssertEqual(interface.address, "10.0.0.1")
        XCTAssertEqual(interface.netmask, "255.255.255.0")
        XCTAssertEqual(interface.broadcastAddress, "10.0.0.255")
        XCTAssertTrue(interface.isRunning)
        XCTAssertTrue(interface.isUp)
        XCTAssertFalse(interface.isLoopback)
        XCTAssertTrue(interface.supportsMulticast)
    }

    func testInterfaceFamilyToString() {
        XCTAssertEqual(Interface.Family.ipv4.toString(), "IPv4")
        XCTAssertEqual(Interface.Family.ipv6.toString(), "IPv6")
        XCTAssertEqual(Interface.Family.ethernet.toString(), "Ethernet")
        XCTAssertEqual(Interface.Family.other.toString(), "other")
    }

    func testInterfaceDescription() {
        let interface = Interface(
            name: "en0",
            family: .ipv4,
            hardwareAddress: "00:11:22:33:44:55",
            address: "192.168.1.100",
            netmask: "255.255.255.0",
            running: true,
            up: true,
            loopback: false,
            multicastSupported: true,
            broadcastAddress: "192.168.1.255"
        )

        // Test description (should return name)
        XCTAssertEqual(interface.description, "en0")

        // Test debug description (should contain interface info)
        let debugDesc = interface.debugDescription
        XCTAssertTrue(debugDesc.contains("en0"))
        XCTAssertTrue(debugDesc.contains("IPv4"))
        XCTAssertTrue(debugDesc.contains("192.168.1.100"))
        XCTAssertTrue(debugDesc.contains("(up)"))
        XCTAssertTrue(debugDesc.contains("(running)"))
    }

    func testInterfaceDebugDescriptionWithDownInterface() {
        let interface = Interface(
            name: "en1",
            family: .ipv6,
            hardwareAddress: nil,
            address: "fe80::1",
            netmask: nil,
            running: false,
            up: false,
            loopback: false,
            multicastSupported: false,
            broadcastAddress: nil
        )

        let debugDesc = interface.debugDescription
        XCTAssertTrue(debugDesc.contains("en1"))
        XCTAssertTrue(debugDesc.contains("IPv6"))
        XCTAssertTrue(debugDesc.contains("fe80::1"))
        XCTAssertTrue(debugDesc.contains("(down)"))
        XCTAssertTrue(debugDesc.contains("(not running)"))
    }

    func testInterfaceFilteringByFamily() {
        let ipv4Interfaces = Interface.interfaces { _, family in
            family == .ipv4
        }

        let ipv6Interfaces = Interface.interfaces { _, family in
            family == .ipv6
        }

        for interface in ipv4Interfaces {
            XCTAssertEqual(interface.family, .ipv4)
        }

        for interface in ipv6Interfaces {
            XCTAssertEqual(interface.family, .ipv6)
        }
    }

    func testInterfaceFilteringByName() {
        let allInterfaces = Interface.allInterfaces()
        guard let firstInterface = allInterfaces.first else {
            _ = XCTSkip("No interfaces available for testing")
            return
        }

        let filteredInterfaces = Interface.interfaces { name, _ in
            name == firstInterface.name
        }

        for interface in filteredInterfaces {
            XCTAssertEqual(interface.name, firstInterface.name)
        }
    }

    func testInterfaceNameListUniqueness() {
        let nameList = Interface.interfaceNameList()
        let uniqueNames = Set(nameList)

        // The name list should not contain duplicates
        XCTAssertEqual(nameList.count, uniqueNames.count)
    }

    func testInterfaceAddressBytesConversion() {
        // Test IPv4 address bytes conversion
        let ipv4Interface = Interface(
            name: "test0",
            family: .ipv4,
            hardwareAddress: nil,
            address: "192.168.1.100",
            netmask: "255.255.255.0",
            running: true,
            up: true,
            loopback: false,
            multicastSupported: true,
            broadcastAddress: nil
        )

        if let addressBytes = ipv4Interface.addressBytes {
            XCTAssertEqual(addressBytes.count, 4)
            XCTAssertEqual(addressBytes, [192, 168, 1, 100])
        }

        // Test IPv6 address bytes conversion
        let ipv6Interface = Interface(
            name: "test1",
            family: .ipv6,
            hardwareAddress: nil,
            address: "::1",
            netmask: nil,
            running: true,
            up: true,
            loopback: true,
            multicastSupported: false,
            broadcastAddress: nil
        )

        if let addressBytes = ipv6Interface.addressBytes {
            XCTAssertEqual(addressBytes.count, 16)
            // ::1 should be all zeros except the last byte which is 1
            let expectedBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
            XCTAssertEqual(addressBytes, expectedBytes)
        }

        // Test interface without address
        let noAddressInterface = Interface(
            name: "test2",
            family: .ethernet,
            hardwareAddress: "00:11:22:33:44:55",
            address: nil,
            netmask: nil,
            running: true,
            up: true,
            loopback: false,
            multicastSupported: false,
            broadcastAddress: nil
        )

        XCTAssertNil(noAddressInterface.addressBytes)
    }

    func testInterfaceCodable() throws {
        let interface = Interface(
            name: "en0",
            family: .ipv4,
            hardwareAddress: "00:11:22:33:44:55",
            address: "192.168.1.100",
            netmask: "255.255.255.0",
            running: true,
            up: true,
            loopback: false,
            multicastSupported: true,
            broadcastAddress: "192.168.1.255"
        )

        let encoded = try JSONEncoder().encode(interface)
        let decoded = try JSONDecoder().decode(Interface.self, from: encoded)

        XCTAssertEqual(interface, decoded)
        XCTAssertEqual(interface.name, decoded.name)
        XCTAssertEqual(interface.family, decoded.family)
        XCTAssertEqual(interface.hardwareAddress, decoded.hardwareAddress)
        XCTAssertEqual(interface.address, decoded.address)
        XCTAssertEqual(interface.netmask, decoded.netmask)
        XCTAssertEqual(interface.isRunning, decoded.isRunning)
        XCTAssertEqual(interface.isUp, decoded.isUp)
        XCTAssertEqual(interface.isLoopback, decoded.isLoopback)
        XCTAssertEqual(interface.supportsMulticast, decoded.supportsMulticast)
    }
}
