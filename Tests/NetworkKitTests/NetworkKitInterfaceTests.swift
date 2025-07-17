import Network
@testable import NetworkKit
import XCTest

final class NetworkKitInterfaceTests: XCTestCase {
    func testAllInterfaces() {
        let interfaces = Interface.allInterfaces()
        XCTAssertFalse(interfaces.isEmpty, "Should find at least one network interface")
        for interface in interfaces {
            XCTAssertFalse(interface.name.isEmpty)
            XCTAssertGreaterThan(interface.index, 0)
            XCTAssertNotNil(interface.type)
            // Check type safety and basic properties, not all interfaces must have addresses
            XCTAssertNotNil(interface.isUp)
            XCTAssertNotNil(interface.isRunning)
            XCTAssertNotNil(interface.supportsMulticast)
            // debugDescription should not crash
            XCTAssertFalse(interface.debugDescription.isEmpty)
        }
    }

    func testListAllHardwareInterfaces() {
        let scInterfaces = Interface.listAllHardwareInterfaces()
        // Allow empty, but type and properties should be accessible
        for sc in scInterfaces {
            XCTAssertFalse(sc.bsdName.isEmpty)
            XCTAssertFalse(sc.localizedDisplayName.isEmpty)
            XCTAssertFalse(sc.hardwareAddress.isEmpty)
            XCTAssertNotNil(sc.type)
            XCTAssertFalse(sc.description.isEmpty)
        }
    }

    func testIfaddrsList() {
        let ifaddrsList = Ifaddrs.ifaddrsList()
        XCTAssertFalse(ifaddrsList.isEmpty, "Should find at least one ifaddrs entry")
        for ifaddr in ifaddrsList {
            XCTAssertFalse(ifaddr.name.isEmpty)
            XCTAssertGreaterThan(ifaddr.index, 0)
            XCTAssertNotNil(ifaddr.family)
            // Allow address/netmask/broadcast/gateway/hardwareAddress to be nil
            XCTAssertNotNil(ifaddr.isUp)
            XCTAssertNotNil(ifaddr.isRunning)
            XCTAssertNotNil(ifaddr.supportsMulticast)
            // debugDescription should not crash
            XCTAssertFalse(ifaddr.debugDescription.isEmpty)
        }
    }

    func testIfaddrsCondition() {
        let ifaddrsList = Ifaddrs.ifaddrsList { name, isUp, isRunning, isLoopback in
            name == "en0" && isUp && isRunning && !isLoopback
        }
        XCTAssertFalse(ifaddrsList.isEmpty, "Should find at least one ifaddrs entry")
        for ifaddr in ifaddrsList {
            XCTAssertEqual(ifaddr.name, "en0")
            XCTAssertTrue(ifaddr.isUp)
            XCTAssertTrue(ifaddr.isRunning)
            XCTAssertFalse(ifaddr.isLoopback)
        }
    }

    func testAllInterfacesPerformance() {
        measure {
            _ = Interface.allInterfaces()
        }
    }

    func testAllInterfacesConditionPerformance() {
        measure {
            _ = Interface.allInterfaces { name, _, _, _ in
                name == "en0"
            }
        }
    }

    func testListAllHardwareInterfacesPerformance() {
        measure {
            _ = Interface.listAllHardwareInterfaces()
        }
    }

    func testIfaddrsListPerformance() {
        measure {
            _ = Ifaddrs.ifaddrsList()
        }
    }
}
