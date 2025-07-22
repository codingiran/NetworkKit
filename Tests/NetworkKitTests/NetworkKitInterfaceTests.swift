import Network
@testable import NetworkKit
import XCTest

final class NetworkKitInterfaceTests: XCTestCase {
    func testAllInterfaces() {
        let interfaces = Interface.allInterfaces()
        XCTAssertFalse(interfaces.isEmpty, "Should find at least one network interface")
        for interface in interfaces {
            debugPrint(interface.debugDescription)
            XCTAssertFalse(interface.name.isEmpty)
            XCTAssertGreaterThan(interface.index, 0)
            XCTAssertNotNil(interface.type)
            // Check type safety and basic properties, not all interfaces must have addresses
            XCTAssertNotNil(interface.isUp)
            XCTAssertNotNil(interface.isRunning)
            XCTAssertNotNil(interface.supportsMulticast)
        }
    }

    #if os(macOS) && canImport(SystemConfiguration)

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

    #endif

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

    func testAllInterfacesPerformance() {
        measure {
            _ = Interface.allInterfaces()
        }
    }

    func testInterfaceTypePerformance() {
        guard let interface = Interface.allInterfaces().first(where: { $0.name == "en0" }) else { return }
        measure {
            _ = interface.type
        }
    }

    #if os(macOS) && canImport(SystemConfiguration)

    func testListAllHardwareInterfacesPerformance() {
        measure {
            _ = Interface.listAllHardwareInterfaces()
        }
    }

    #endif

    func testIfaddrsListPerformance() {
        measure {
            _ = Ifaddrs.ifaddrsList()
        }
    }
}
