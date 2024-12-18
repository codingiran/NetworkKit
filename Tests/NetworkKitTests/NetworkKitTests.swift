import Network
@testable import NetworkKit
import XCTest

final class NetworkKitTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }

    func testInterfaceAll() throws {
        let allInterfaces = NetworkKit.Interface.allInterfaces()
        let interfaces = NetworkKit.Interface.interfaces { name, _ in
            name == "en0"
//            family == .ethernet && name.hasPrefix("en")
        }
        debugPrint("--\(interfaces)")
    }

    func testIPv6Address() throws {
//        if let iPv6Address = IPv6Address("fe80::c07:3182:9e56:aef8") {
//            let isLinkLocal = iPv6Address.isLinkLocal
//            let isUniqueLocal = iPv6Address.isUniqueLocal
//            let is6to4 = iPv6Address.is6to4
//            let isAny = iPv6Address.isAny
//            let isMulticast = iPv6Address.isMulticast
//            let isLoopback = iPv6Address.isLoopback
//            let isIPv4Mapped = iPv6Address.isIPv4Mapped
//            let isIPv4Compatabile = iPv6Address.isIPv4Compatabile
//            debugPrint("--\(iPv6Address)")
//        }

//        if let iPv6Address = IPv6Address("fd95:62dd:df12:0:10ca:5707:ed29:f4f5") {
//            let isLinkLocal = iPv6Address.isLinkLocal
//            let isUniqueLocal = iPv6Address.isUniqueLocal
//            let is6to4 = iPv6Address.is6to4
//            let isAny = iPv6Address.isAny
//            let isMulticast = iPv6Address.isMulticast
//            let isLoopback = iPv6Address.isLoopback
//            let isIPv4Mapped = iPv6Address.isIPv4Mapped
//            let isIPv4Compatabile = iPv6Address.isIPv4Compatabile
//            debugPrint("--\(iPv6Address)")
//        }

        // "fd95:62dd:df12:0:10ca:5707:ed29:f4f5"
        // fd16:3a55:1a62::2
        // 240a:42a6:b400:266a:5ceb:7d8:7693:eaa

        if let iPv6Address = IPv6Address("240a:42a6:b400:266a:5ceb:7d8:7693:eaa") {
            let isLinkLocal = iPv6Address.isLinkLocal
            let isUniqueLocal = iPv6Address.isUniqueLocal
            let is6to4 = iPv6Address.is6to4
            let isAny = iPv6Address.isAny
            let isMulticast = iPv6Address.isMulticast
            let isLoopback = iPv6Address.isLoopback
            let isIPv4Mapped = iPv6Address.isIPv4Mapped
            let isIPv4Compatabile = iPv6Address.isIPv4Compatabile
            debugPrint("--\(iPv6Address)")
        }
    }

    func testCurrentWiFiSSID() {
        var date = Date()
        let ssid = WiFiSSID.currentWiFiSSID(tryLegacy: true)
        var interval = Date().timeIntervalSince(date)
        debugPrint("--\(ssid)")
        debugPrint("--\(interval)")
//        date = Date()
//        let ssid1 = WiFiUtils.currentSSIDLegacy()
//        interval = Date().timeIntervalSince(date)
//        debugPrint("--\(ssid1)")
//        debugPrint("--\(interval)")
//        date = Date()
//        let ssid2 = WiFiUtils.currentWiFiSSIDLegacySlow()
//        interval = Date().timeIntervalSince(date)
//        debugPrint("--\(ssid2)")
//        debugPrint("--\(interval)")
    }
}
