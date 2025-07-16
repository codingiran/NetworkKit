import Network
@testable import NetworkKit
import XCTest

final class NetworkKitWiFiSSIDTests: XCTestCase {
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

    #if os(macOS)

        @available(macOS 10.15, *)
        func testWiFiSSIDCurrentSSIDLegacy() {
            let ssid = WiFiSSID.currentSSIDLegacy()
            // This might be nil in testing environment
            if let ssid = ssid {
                XCTAssertFalse(ssid.isEmpty)
            }
        }

        // MARK: - Additional WiFi SSID Tests

        @available(macOS 10.15, iOS 13.0, *)
        func testWiFiSSIDCurrentSSIDWithTryLegacy() {
            // Test with tryLegacy = true
            let ssidWithLegacy = WiFiSSID.currentWiFiSSID(tryLegacy: true)

            // Test with tryLegacy = false (default)
            let ssidWithoutLegacy = WiFiSSID.currentWiFiSSID(tryLegacy: false)

            // Both might be nil in testing environment, but should not crash
            if let ssid = ssidWithLegacy {
                XCTAssertFalse(ssid.isEmpty)
            }

            if let ssid = ssidWithoutLegacy {
                XCTAssertFalse(ssid.isEmpty)
            }
        }

    #endif

    func testWiFiSSIDCurrentSSIDOfInterface() {
        // Test with a known interface name (might not exist in test environment)
        let ssid = WiFiSSID.currentSSID(of: "en0")

        // This might be nil if en0 is not WiFi or doesn't exist
        if let ssid = ssid {
            XCTAssertFalse(ssid.isEmpty)
        }

        // Test with empty interface name
        let emptySSID = WiFiSSID.currentSSID(of: "")
        XCTAssertNil(emptySSID)

        // Test with invalid interface name
        let invalidSSID = WiFiSSID.currentSSID(of: "invalid_interface_name_12345")
        XCTAssertNil(invalidSSID)
    }

    #if os(macOS)

        @available(macOS 10.15, *)
        func testWiFiSSIDLegacyMethods() {
            // Test legacy SSID retrieval
            let legacySSID = WiFiSSID.currentSSIDLegacy()

            // Test slow legacy method
            let slowLegacySSID = WiFiSSID.currentWiFiSSIDLegacySlow()

            // These might be nil in testing environment
            if let ssid = legacySSID {
                XCTAssertFalse(ssid.isEmpty)
            }

            if let ssid = slowLegacySSID {
                XCTAssertFalse(ssid.isEmpty)
            }
        }

    #endif

    func testWiFiSSIDInterfaceNameRetrieval() {
        let interfaceName = WiFiSSID.currentInterfaceName()

        // This might be nil in testing environment without WiFi
        if let name = interfaceName {
            XCTAssertFalse(name.isEmpty)
            // Common WiFi interface names include en0, en1, wlan0, wifi0
            // Don't assert it's one of these as it can vary by system
        }

        // The method should not crash even if no WiFi is available
        XCTAssertNoThrow(WiFiSSID.currentInterfaceName())
    }

    @available(macOS 10.15, iOS 13.0, *)
    func testWiFiSSIDConsistencyBetweenMethods() {
        // Get SSID using different methods and compare if both return values
        let modernSSID = WiFiSSID.currentWiFiSSID(tryLegacy: false)
        let modernSSIDWithLegacy = WiFiSSID.currentWiFiSSID(tryLegacy: true)

        #if os(macOS)
            let legacySSID = WiFiSSID.currentSSIDLegacy()

            // If both modern and legacy methods return a value, they should be the same
            if let modern = modernSSID, let legacy = legacySSID {
                XCTAssertEqual(modern, legacy, "Modern and legacy methods should return the same SSID")
            }
        #endif

        // Method with tryLegacy should return at least as much info as without
        if let withoutLegacy = modernSSID, let withLegacy = modernSSIDWithLegacy {
            XCTAssertEqual(withoutLegacy, withLegacy, "SSID should be consistent regardless of tryLegacy flag when modern method works")
        }
    }

    @available(macOS 10.15, iOS 13.0, *)
    func testWiFiSSIDMethodsDoNotCrash() {
        // Ensure all methods can be called without crashing
        XCTAssertNoThrow(WiFiSSID.currentWiFiSSID())
        XCTAssertNoThrow(WiFiSSID.currentWiFiSSID(tryLegacy: true))
        XCTAssertNoThrow(WiFiSSID.currentWiFiSSID(tryLegacy: false))
        XCTAssertNoThrow(WiFiSSID.currentInterfaceName())

        #if os(macOS)
            XCTAssertNoThrow(WiFiSSID.currentSSIDLegacy())
            XCTAssertNoThrow(WiFiSSID.currentWiFiSSIDLegacySlow())
        #endif
    }

    func testWiFiSSIDCurrentSSIDOfInterfaceWithVariousInputs() {
        let testInterfaceNames = [
            "en0",
            "en1",
            "wlan0",
            "wifi0",
            "lo0", // Loopback (should not have WiFi)
            "invalid123",
            "",
        ]

        for interfaceName in testInterfaceNames {
            // Should not crash for any input
            XCTAssertNoThrow(WiFiSSID.currentSSID(of: interfaceName))

            let ssid = WiFiSSID.currentSSID(of: interfaceName)

            // If an SSID is returned, it should not be empty
            if let ssid = ssid {
                XCTAssertFalse(ssid.isEmpty, "SSID should not be empty for interface: \(interfaceName)")
            }
        }
    }

    @available(macOS 10.15, *)
    func testWiFiSSIDCurrentInterfaceNamePerformance() {
        // Test that WiFi interface name retrieval completes in reasonable time
        measure {
            _ = WiFiSSID.currentInterfaceName()
        }
    }

    @available(macOS 10.15, *)
    func testWiFiSSIDCurrentSSIDPerformance() {
        // Test that WiFi SSID retrieval completes in reasonable time
        measure {
            _ = WiFiSSID.currentWiFiSSID()
        }
    }

    #if os(macOS)

        @available(macOS 10.15, *)
        func testWiFiSSIDLegacyMethodPerformance() {
            // Legacy methods might be slower
            measure {
                _ = WiFiSSID.currentSSIDLegacy()
            }
        }

    #endif

    func testWiFiSSIDSendableConformance() {
        // WiFiSSID is an enum that should be Sendable
        // This test ensures the enum can be used in concurrent contexts
        let expectation = XCTestExpectation(description: "WiFiSSID methods work in concurrent context")

        Task {
            // These calls should work in an async context
            let interfaceName = WiFiSSID.currentInterfaceName()
            let ssid = WiFiSSID.currentSSID(of: interfaceName ?? "en0")

            // Should not crash or have concurrency issues
            XCTAssertNoThrow(interfaceName)
            XCTAssertNoThrow(ssid)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
