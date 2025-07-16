import Network
@testable import NetworkKit
import XCTest

final class NetworkKitIPAddressRangeTests: XCTestCase {
    // MARK: - Initialization Tests

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

    func testIPAddressRangeInitializationWithVariousPrefixes() {
        let testCases = [
            ("192.168.1.0/8", 8),
            ("192.168.1.0/16", 16),
            ("192.168.1.0/24", 24),
            ("192.168.1.0/32", 32),
            ("2001:db8::/16", 16),
            ("2001:db8::/32", 32),
            ("2001:db8::/64", 64),
            ("2001:db8::/128", 128),
        ]

        for (cidr, expectedPrefix) in testCases {
            let range = IPAddressRange(from: cidr)
            XCTAssertNotNil(range, "Failed to create range for \(cidr)")
            XCTAssertEqual(range?.networkPrefixLength, UInt8(expectedPrefix))
        }
    }

    // MARK: - String Representation Tests

    func testIPAddressRangeStringRepresentation() {
        let range = IPAddressRange(from: "192.168.1.0/24")!
        XCTAssertEqual(range.stringRepresentation, "192.168.1.0/24")

        let range6 = IPAddressRange(from: "2001:db8::/32")!
        XCTAssertEqual(range6.stringRepresentation, "2001:db8::/32")
    }

    // MARK: - Contains Tests

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

    func testIPAddressRangeContainsEdgeCases() {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        // 测试网络地址和广播地址
        XCTAssertTrue(range.contains("192.168.1.0")) // 网络地址
        XCTAssertTrue(range.contains("192.168.1.255")) // 广播地址
        XCTAssertTrue(range.contains("192.168.1.1")) // 第一个可用IP
        XCTAssertTrue(range.contains("192.168.1.254")) // 最后一个可用IP

        // 测试边界外的地址
        XCTAssertFalse(range.contains("192.168.0.255"))
        XCTAssertFalse(range.contains("192.168.2.0"))
    }

    // MARK: - Subnet Mask Tests

    func testIPAddressRangeSubnetMask() {
        let range4 = IPAddressRange(from: "192.168.1.0/24")!
        let range6 = IPAddressRange(from: "2001:db8::/32")!

        let mask4 = range4.subnetMask()
        let mask6 = range6.subnetMask()

        XCTAssertTrue(mask4 is IPv4Address)
        XCTAssertTrue(mask6 is IPv6Address)

        XCTAssertEqual(mask4.rawValue, IPv4Address("255.255.255.0")!.rawValue)
    }

    func testIPAddressRangeSubnetMaskVariousPrefixes() {
        let testCases: [(String, String)] = [
            ("192.168.1.0/8", "255.0.0.0"),
            ("192.168.1.0/16", "255.255.0.0"),
            ("192.168.1.0/24", "255.255.255.0"),
            ("192.168.1.0/25", "255.255.255.128"),
            ("192.168.1.0/30", "255.255.255.252"),
        ]

        for (cidr, expectedMask) in testCases {
            let range = IPAddressRange(from: cidr)!
            let mask = range.subnetMask()
            let expectedMaskIP = IPv4Address(expectedMask)!

            XCTAssertEqual(mask.rawValue, expectedMaskIP.rawValue,
                           "Subnet mask for \(cidr) should be \(expectedMask)")
        }
    }

    func testIPAddressRangeMaskedAddress() {
        let range = IPAddressRange(from: "192.168.1.100/24")!
        let maskedAddress = range.maskedAddress()

        XCTAssertEqual(maskedAddress.rawValue, IPv4Address("192.168.1.0")!.rawValue)
    }

    // MARK: - Usable IP Count Tests

    func testUsableIPAddressCount() {
        let testCases: [(String, UInt64)] = [
            ("192.168.1.0/30", 2), // 4 total - 2 (network + broadcast) = 2 usable
            ("192.168.1.0/29", 6), // 8 total - 2 = 6 usable
            ("192.168.1.0/28", 14), // 16 total - 2 = 14 usable
            ("192.168.1.0/24", 254), // 256 total - 2 = 254 usable
            ("192.168.1.0/32", 1), // Single host
            ("2001:db8::/126", 2), // IPv6 with 4 total - 2 = 2 usable
            ("2001:db8::/128", 1), // IPv6 single host
        ]

        for (cidr, expectedCount) in testCases {
            let range = IPAddressRange(from: cidr)!
            XCTAssertEqual(range.usableIPAddressCount, expectedCount,
                           "Usable IP count for \(cidr) should be \(expectedCount)")
        }
    }

    // MARK: - Convenience Properties Tests

    func testFirstAndLastUsableIPProperties() {
        let range = IPAddressRange(from: "192.168.1.0/28")! // 14 usable IPs

        // 测试便利属性
        XCTAssertNotNil(range.firstUsableIP)
        XCTAssertNotNil(range.lastUsableIP)

        if let firstIP = range.firstUsableIP {
            XCTAssertEqual(firstIP.rawValue, IPv4Address("192.168.1.1")!.rawValue)
        }

        if let lastIP = range.lastUsableIP {
            XCTAssertEqual(lastIP.rawValue, IPv4Address("192.168.1.14")!.rawValue)
        }
    }

    func testSingleHostConvenienceProperties() {
        let singleHost = IPAddressRange(from: "192.168.1.100/32")!

        XCTAssertNotNil(singleHost.firstUsableIP)
        XCTAssertNotNil(singleHost.lastUsableIP)

        // 单主机情况下，第一个和最后一个应该是同一个
        XCTAssertEqual(singleHost.firstUsableIP?.rawValue,
                       singleHost.lastUsableIP?.rawValue)
        XCTAssertEqual(singleHost.firstUsableIP?.rawValue,
                       IPv4Address("192.168.1.100")!.rawValue)
    }

    // MARK: - Basic Subscript Tests

    func testIPAddressRangeBasicSubscript() {
        let range = IPAddressRange(from: "192.168.1.0/28")! // 14 usable IPs: .1 to .14

        // 测试基础下标 (0-based)
        XCTAssertEqual(range[0]?.rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(range[1]?.rawValue, IPv4Address("192.168.1.2")!.rawValue)
        XCTAssertEqual(range[9]?.rawValue, IPv4Address("192.168.1.10")!.rawValue)
        XCTAssertEqual(range[13]?.rawValue, IPv4Address("192.168.1.14")!.rawValue)

        // 测试边界情况
        XCTAssertNil(range[-1]) // 负数索引
        XCTAssertNil(range[14]) // 超出范围（只有14个可用IP：索引0-13）
        XCTAssertNil(range[100]) // 远超出范围
    }

    func testIPAddressRangeSafeSubscript() {
        let range = IPAddressRange(from: "192.168.1.0/28")!

        // 测试安全下标
        XCTAssertEqual(range[safe: 0]?.rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(range[safe: 9]?.rawValue, IPv4Address("192.168.1.10")!.rawValue)

        // 测试安全下标的边界保护
        XCTAssertNil(range[safe: -1]) // 负数索引
        XCTAssertNil(range[safe: 14]) // 超出范围
        XCTAssertNil(range[safe: 1000]) // 远超出范围

        // 验证安全下标和基础下标返回相同结果（在有效范围内）
        for i in 0 ..< Int(range.usableIPAddressCount) {
            XCTAssertEqual(range[i]?.rawValue, range[safe: i]?.rawValue)
        }
    }

    func testIPAddressRangeSubscriptWithSingleHost() {
        let singleHost = IPAddressRange(from: "192.168.1.100/32")!

        // 单主机应该只有一个可用IP（索引0）
        XCTAssertEqual(singleHost[0]?.rawValue, IPv4Address("192.168.1.100")!.rawValue)
        XCTAssertNil(singleHost[1]) // 超出范围
        XCTAssertNil(singleHost[-1]) // 负数索引

        // 测试安全下标
        XCTAssertEqual(singleHost[safe: 0]?.rawValue, IPv4Address("192.168.1.100")!.rawValue)
        XCTAssertNil(singleHost[safe: 1])
        XCTAssertNil(singleHost[safe: -1])
    }

    func testIPAddressRangeSubscriptWithIPv6() {
        let ipv6Range = IPAddressRange(from: "2001:db8::/126")! // 2 usable IPs

        // 测试IPv6下标
        XCTAssertNotNil(ipv6Range[0])
        XCTAssertNotNil(ipv6Range[1])
        XCTAssertNil(ipv6Range[2]) // 超出范围
        XCTAssertNil(ipv6Range[-1]) // 负数索引

        // 验证是IPv6地址
        XCTAssertTrue(ipv6Range[0] is IPv6Address)
        XCTAssertTrue(ipv6Range[1] is IPv6Address)

        // 测试单个IPv6主机
        let singleIPv6 = IPAddressRange(from: "2001:db8::1/128")!
        XCTAssertNotNil(singleIPv6[0])
        XCTAssertNil(singleIPv6[1])
        XCTAssertTrue(singleIPv6[0] is IPv6Address)
    }

    // MARK: - Range Subscript Tests

    func testIPAddressRangeRangeSubscript() {
        let range = IPAddressRange(from: "192.168.1.0/28")! // 14 usable IPs: .1 to .14

        // 测试范围下标 (Range<Int>)
        let firstThree = range[0 ..< 3]
        XCTAssertEqual(firstThree.count, 3)
        XCTAssertEqual(firstThree[0].rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(firstThree[1].rawValue, IPv4Address("192.168.1.2")!.rawValue)
        XCTAssertEqual(firstThree[2].rawValue, IPv4Address("192.168.1.3")!.rawValue)

        // 测试空范围
        let emptyRange = range[5 ..< 5]
        XCTAssertEqual(emptyRange.count, 0)

        // 测试部分超出范围的情况
        let partialRange = range[10 ..< 20] // 只有10-13是有效的
        XCTAssertEqual(partialRange.count, 4)
        XCTAssertEqual(partialRange[0].rawValue, IPv4Address("192.168.1.11")!.rawValue)
        XCTAssertEqual(partialRange[3].rawValue, IPv4Address("192.168.1.14")!.rawValue)
    }

    func testIPAddressRangeClosedRangeSubscript() {
        let range = IPAddressRange(from: "192.168.1.0/28")!

        // 测试闭区间下标 (ClosedRange<Int>)
        let firstToThird = range[0 ... 2]
        XCTAssertEqual(firstToThird.count, 3)
        XCTAssertEqual(firstToThird[0].rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(firstToThird[2].rawValue, IPv4Address("192.168.1.3")!.rawValue)

        // 测试单个元素的闭区间
        let singleElement = range[5 ... 5]
        XCTAssertEqual(singleElement.count, 1)
        XCTAssertEqual(singleElement[0].rawValue, IPv4Address("192.168.1.6")!.rawValue)
    }

    func testIPAddressRangePartialRangeSubscripts() {
        let range = IPAddressRange(from: "192.168.1.0/29")! // 6 usable IPs: .1 to .6

        // 测试部分范围：从指定位置开始 (PartialRangeFrom)
        let fromThird = range[2...]
        XCTAssertEqual(fromThird.count, 4) // 索引2,3,4,5 = .3,.4,.5,.6
        XCTAssertEqual(fromThird[0].rawValue, IPv4Address("192.168.1.3")!.rawValue)
        XCTAssertEqual(fromThird[3].rawValue, IPv4Address("192.168.1.6")!.rawValue)

        // 测试部分范围：到指定位置 (PartialRangeUpTo)
        let upToThird = range[..<3]
        XCTAssertEqual(upToThird.count, 3) // 索引0,1,2 = .1,.2,.3
        XCTAssertEqual(upToThird[0].rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(upToThird[2].rawValue, IPv4Address("192.168.1.3")!.rawValue)

        // 测试部分范围：到指定位置（包含）(PartialRangeThrough)
        let throughSecond = range[...1]
        XCTAssertEqual(throughSecond.count, 2) // 索引0,1 = .1,.2
        XCTAssertEqual(throughSecond[0].rawValue, IPv4Address("192.168.1.1")!.rawValue)
        XCTAssertEqual(throughSecond[1].rawValue, IPv4Address("192.168.1.2")!.rawValue)
    }

    func testIPAddressRangePartialRangeFromLimiting() {
        // 测试大范围的限制机制（防止内存问题）
        let largeRange = IPAddressRange(from: "10.0.0.0/16")! // 65534 usable IPs

        let fromMiddle = largeRange[30000...]
        // 应该被限制为最多1000个元素
        XCTAssertLessThanOrEqual(fromMiddle.count, 1000)

        if !fromMiddle.isEmpty {
            // 验证第一个元素是正确的
            let expectedFirstIP = largeRange[30000]
            XCTAssertEqual(fromMiddle[0].rawValue, expectedFirstIP?.rawValue)
        }
    }

    // MARK: - Equality and Codable Tests

    func testIPAddressRangeEquality() {
        let range1 = IPAddressRange(from: "192.168.1.0/24")!
        let range2 = IPAddressRange(from: "192.168.1.0/24")!
        let range3 = IPAddressRange(from: "192.168.1.0/16")!
        let range4 = IPAddressRange(from: "192.168.2.0/24")!

        XCTAssertEqual(range1, range2)
        XCTAssertNotEqual(range1, range3)
        XCTAssertNotEqual(range1, range4)
    }

    func testIPAddressRangeCodable() throws {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        let encoded = try JSONEncoder().encode(range)
        let decoded = try JSONDecoder().decode(IPAddressRange.self, from: encoded)

        XCTAssertEqual(range, decoded)

        // 验证下标功能在解码后仍然工作
        XCTAssertEqual(decoded[0]?.rawValue, range[0]?.rawValue)
        XCTAssertEqual(decoded.usableIPAddressCount, range.usableIPAddressCount)
    }

    // MARK: - Performance Tests

    func testSubscriptPerformance() {
        let range = IPAddressRange(from: "192.168.1.0/24")! // 254 usable IPs

        measure {
            // 测试单个下标访问的性能
            for i in 0 ..< 1000 {
                _ = range[i % Int(range.usableIPAddressCount)]
            }
        }
    }

    func testRangeSubscriptPerformance() {
        let range = IPAddressRange(from: "192.168.1.0/24")!

        measure {
            // 测试范围下标访问的性能
            _ = range[0 ..< 500]
        }
    }

    // MARK: - Edge Cases and Error Handling

    func testSubscriptWithVerySmallRanges() {
        // 测试最小可能的范围
        let tinyRange = IPAddressRange(from: "192.168.1.0/30")! // 只有2个可用IP

        XCTAssertEqual(tinyRange.usableIPAddressCount, 2)
        XCTAssertNotNil(tinyRange[0])
        XCTAssertNotNil(tinyRange[1])
        XCTAssertNil(tinyRange[2])

        let bothIPs = tinyRange[0 ..< 2]
        XCTAssertEqual(bothIPs.count, 2)
    }

    func testSubscriptConsistencyWithUsableCount() {
        let testRanges = [
            "192.168.1.0/30", // 2 usable
            "192.168.1.0/28", // 14 usable
            "192.168.1.0/24", // 254 usable
            "192.168.1.0/32", // 1 usable (single host)
            "2001:db8::/126", // 2 usable (IPv6)
            "2001:db8::/128", // 1 usable (IPv6 single host)
        ]

        for cidr in testRanges {
            let range = IPAddressRange(from: cidr)!
            let count = range.usableIPAddressCount

            // 验证最后一个有效索引可以访问
            if count > 0 {
                XCTAssertNotNil(range[Int(count - 1)],
                                "Should be able to access last IP in \(cidr)")
                XCTAssertNil(range[Int(count)],
                             "Should not be able to access beyond last IP in \(cidr)")
            }

            // 验证范围访问的一致性
            if count > 0 {
                let allIPs = range[0 ..< Int(count)]
                XCTAssertEqual(allIPs.count, Int(count),
                               "Range access should return all IPs for \(cidr)")
            }
        }
    }
}
