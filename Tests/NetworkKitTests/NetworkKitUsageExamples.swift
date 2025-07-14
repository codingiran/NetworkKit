import Network
@testable import NetworkKit
import XCTest

/**
 * NetworkKit 使用示例
 *
 * 这个文件展示了 NetworkKit 库的各种功能的实际使用方法
 */
final class NetworkKitUsageExamples: XCTestCase {
    // MARK: - 数组并发处理示例

    /// 示例1：使用异步映射处理网络请求
    func exampleAsyncMapNetworkRequests() async {
        let urls = [
            "https://httpbin.org/delay/1",
            "https://httpbin.org/delay/2",
            "https://httpbin.org/delay/3",
        ]

        // 异步顺序处理每个URL
        let results = await urls.asyncMap { url in
            // 模拟网络请求
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return "Response from \(url)"
        }

        print("异步映射结果：\(results)")
    }

    /// 示例2：使用并发映射同时处理多个任务
    func exampleConcurrentMapTasks() async throws {
        let data = Array(1 ... 10)

        // 并发处理所有任务
        let results = try await data.concurrentMap { number in
            // 模拟计算密集型任务
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return number * number
        }

        print("并发映射结果：\(results)")
    }

    // MARK: - DNS 解析示例

    /// 示例3：批量DNS解析
    func exampleBatchDNSResolution() async throws {
        let endpoints = [
            Endpoint(host: .name("www.apple.com", nil), port: 80),
            Endpoint(host: .name("www.google.com", nil), port: 443),
            Endpoint(host: .ipv4(IPv4Address("8.8.8.8")!), port: 53), // 已解析的IP
            nil, // 空端点
        ]

        let results = try await DNSResolver.resolveAsync(endpoints: endpoints)

        for (index, result) in results.enumerated() {
            switch result {
            case let .success(endpoint):
                print("端点 \(index) 解析成功: \(endpoint.stringRepresentation)")
            case let .failure(error):
                print("端点 \(index) 解析失败: \(error.localizedDescription)")
            case .none:
                print("端点 \(index) 为空")
            }
        }
    }

    // MARK: - 网络接口查询示例

    /// 示例4：查询网络接口信息
    func exampleNetworkInterfaceQuery() {
        // 获取所有网络接口
        let allInterfaces = Interface.allInterfaces()
        print("系统中的所有网络接口：")
        for interface in allInterfaces {
            print("- \(interface.name): \(interface.address ?? "无IP地址") (\(interface.family.toString()))")
        }

        // 查询特定类型的接口
        let wifiInterfaces = Interface.interfaces { name, family in
            name.hasPrefix("en") && family == .ipv4
        }
        print("\nWiFi接口：")
        for interface in wifiInterfaces {
            print("- \(interface.name): \(interface.address ?? "无IP地址")")
            print("  状态: \(interface.isUp ? "启用" : "禁用"), \(interface.isRunning ? "运行中" : "未运行")")
        }

        // 获取网络接口名称列表
        let interfaceNames = Interface.interfaceNameList()
        print("\n接口名称列表: \(interfaceNames)")
    }

    // MARK: - IP地址范围检查示例

    /// 示例5：IP地址范围检查
    func exampleIPAddressRangeChecking() {
        // 创建IP地址范围
        guard let privateRange = IPAddressRange(from: "192.168.1.0/24") else {
            print("无效的IP地址范围")
            return
        }

        let testIPs = [
            "192.168.1.100", // 在范围内
            "192.168.1.1", // 在范围内
            "192.168.2.100", // 不在范围内
            "10.0.0.1", // 不在范围内
            "invalid_ip", // 无效IP
        ]

        print("检查IP地址是否在 \(privateRange.stringRepresentation) 范围内：")
        for ip in testIPs {
            let isInRange = privateRange.contains(ip)
            print("- \(ip): \(isInRange ? "✓" : "✗")")
        }

        // 获取子网掩码和网络地址
        let subnetMask = privateRange.subnetMask()
        let networkAddress = privateRange.maskedAddress()
        print("\n网络信息：")
        print("- 子网掩码: \(subnetMask)")
        print("- 网络地址: \(networkAddress)")
    }

    // MARK: - 端点解析示例

    /// 示例6：端点字符串解析
    func exampleEndpointParsing() {
        let endpointStrings = [
            "example.com:80",
            "192.168.1.1:8080",
            "[::1]:443",
            "github.com:22",
            "invalid_endpoint",
        ]

        print("端点解析示例：")
        for endpointString in endpointStrings {
            if let endpoint = Endpoint(from: endpointString) {
                print("- \(endpointString) -> \(endpoint.stringRepresentation)")
                print("  主机类型: \(endpoint.hasHostAsIPAddress() ? "IP地址" : "域名")")
                if let hostname = endpoint.hostname() {
                    print("  主机名: \(hostname)")
                }
            } else {
                print("- \(endpointString) -> 解析失败")
            }
        }
    }

    // MARK: - WiFi信息获取示例

    /// 示例7：获取WiFi信息
    @available(macOS 10.15, iOS 13.0, *)
    func exampleWiFiInformation() {
        print("WiFi信息：")

        // 获取当前WiFi SSID
        if let ssid = WiFiSSID.currentWiFiSSID() {
            print("- 当前WiFi SSID: \(ssid)")
        } else {
            print("- 无法获取WiFi SSID（可能未连接WiFi或权限不足）")
        }

        // 获取WiFi接口名称
        if let interfaceName = WiFiSSID.currentInterfaceName() {
            print("- WiFi接口名称: \(interfaceName)")
        } else {
            print("- 无法获取WiFi接口名称")
        }

        #if os(macOS)
            // macOS特有的方法
            if let legacySSID = WiFiSSID.currentSSIDLegacy() {
                print("- Legacy方法获取的SSID: \(legacySSID)")
            }
        #endif
    }

    // MARK: - IP地址类型检查示例

    /// 示例8：IP地址类型和属性检查
    func exampleIPAddressTypeChecking() {
        let addresses = [
            "192.168.1.1", // IPv4私有地址
            "127.0.0.1", // IPv4环回地址
            "169.254.1.1", // IPv4链路本地地址
            "::1", // IPv6环回地址
            "fe80::1", // IPv6链路本地地址
            "2001:db8::1", // IPv6全球单播地址
            "8.8.8.8", // IPv4公共地址
        ]

        print("IP地址类型检查：")
        for addressString in addresses {
            if let ipv4 = IPv4Address(addressString) {
                print("- \(addressString) (IPv4):")
                print("  本地地址: \(ipv4.isLocalAddress)")
                print("  环回地址: \(ipv4.isLoopback)")
                print("  链路本地: \(ipv4.isLinkLocal)")
                print("  组播地址: \(ipv4.isMulticast)")
            } else if let ipv6 = IPv6Address(addressString) {
                print("- \(addressString) (IPv6):")
                print("  本地地址: \(ipv6.isLocalAddress)")
                print("  环回地址: \(ipv6.isLoopback)")
                print("  链路本地: \(ipv6.isLinkLocal)")
                print("  唯一本地: \(ipv6.isUniqueLocal)")
                print("  组播地址: \(ipv6.isMulticast)")
            } else {
                print("- \(addressString): 无效的IP地址")
            }
        }
    }

    // MARK: - 数据序列化示例

    /// 示例9：对象序列化和反序列化
    func exampleSerialization() throws {
        // 端点序列化
        let endpoint = Endpoint(host: .name("example.com", nil), port: 80)
        let endpointData = try JSONEncoder().encode(endpoint)
        let decodedEndpoint = try JSONDecoder().decode(Endpoint.self, from: endpointData)
        print("端点序列化: \(endpoint.stringRepresentation) -> \(decodedEndpoint.stringRepresentation)")

        // IP地址范围序列化
        let ipRange = IPAddressRange(from: "192.168.1.0/24")!
        let rangeData = try JSONEncoder().encode(ipRange)
        let decodedRange = try JSONDecoder().decode(IPAddressRange.self, from: rangeData)
        print("IP范围序列化: \(ipRange.stringRepresentation) -> \(decodedRange.stringRepresentation)")

        // IP地址序列化
        let ipv4Address = IPv4Address("192.168.1.1")!
        let ipv4Data = try JSONEncoder().encode(ipv4Address)
        let decodedIPv4 = try JSONDecoder().decode(IPv4Address.self, from: ipv4Data)
        print("IPv4序列化: \(ipv4Address) -> \(decodedIPv4)")
    }

    // MARK: - 综合使用示例

    /// 示例10：综合使用场景 - 网络诊断工具
    func exampleNetworkDiagnostics() async throws {
        print("=== 网络诊断工具 ===")

        // 1. 检查网络接口状态
        print("\n1. 网络接口状态:")
        let activeInterfaces = Interface.interfaces { _, _ in true }
            .filter { $0.isUp && $0.isRunning }

        for interface in activeInterfaces {
            print("- \(interface.name): \(interface.address ?? "无IP") (\(interface.family.toString()))")
        }

        // 2. 检查DNS解析
        print("\n2. DNS解析测试:")
        let testDomains = [
            "www.apple.com",
            "www.google.com",
            "nonexistent.domain.test",
        ]

        let testEndpoints = testDomains.map { domain in
            Endpoint(host: .name(domain, nil), port: 80)
        }

        let dnsResults = try await DNSResolver.resolveAsync(endpoints: testEndpoints)

        for (index, result) in dnsResults.enumerated() {
            let domain = testDomains[index]
            switch result {
            case let .success(endpoint):
                print("- \(domain): ✓ 解析到 \(endpoint.stringRepresentation)")
            case let .failure(error):
                print("- \(domain): ✗ 解析失败 - \(error.localizedDescription)")
            case .none:
                print("- \(domain): ✗ 无结果")
            }
        }

        // 3. 检查本地网络范围
        print("\n3. 本地网络范围检查:")
        let commonRanges = [
            "192.168.0.0/16",
            "10.0.0.0/8",
            "172.16.0.0/12",
        ]

        let currentIP = activeInterfaces.first?.address ?? "127.0.0.1"

        for rangeString in commonRanges {
            if let range = IPAddressRange(from: rangeString) {
                let isInRange = range.contains(currentIP)
                print("- 当前IP \(currentIP) 在 \(rangeString) 范围内: \(isInRange ? "✓" : "✗")")
            }
        }

        // 4. WiFi信息
        print("\n4. WiFi信息:")
        if #available(macOS 10.15, iOS 13.0, *) {
            if let ssid = WiFiSSID.currentWiFiSSID() {
                print("- 当前WiFi SSID: \(ssid)")
            } else {
                print("- 未连接WiFi或无权限获取SSID")
            }
        }

        print("\n=== 诊断完成 ===")
    }

    // MARK: - 测试方法（实际运行示例）

    func testAsyncMapExample() async {
        await exampleAsyncMapNetworkRequests()
    }

    func testConcurrentMapExample() async throws {
        try await exampleConcurrentMapTasks()
    }

    func testDNSResolutionExample() async throws {
        try await exampleBatchDNSResolution()
    }

    func testInterfaceQueryExample() {
        exampleNetworkInterfaceQuery()
    }

    func testIPRangeExample() {
        exampleIPAddressRangeChecking()
    }

    func testEndpointParsingExample() {
        exampleEndpointParsing()
    }

    @available(macOS 10.15, iOS 13.0, *)
    func testWiFiExample() {
        exampleWiFiInformation()
    }

    func testIPAddressTypeExample() {
        exampleIPAddressTypeChecking()
    }

    func testSerializationExample() throws {
        try exampleSerialization()
    }

    func testNetworkDiagnosticsExample() async throws {
        try await exampleNetworkDiagnostics()
    }
}
