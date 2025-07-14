# NetworkKit 测试用例说明

## 概述

本目录包含了 NetworkKit 库的完整测试套件，涵盖了所有主要功能模块的单元测试、性能测试和使用示例。

## 测试文件结构

### 📁 Tests/NetworkKitTests/

```
NetworkKitTests/
├── NetworkKitTests.swift           # 主要的单元测试
├── NetworkKitPerformanceTests.swift # 性能测试
├── NetworkKitUsageExamples.swift   # 使用示例
└── README.md                       # 本文档
```

## 测试模块详解

### 1. 主要单元测试 (NetworkKitTests.swift)

#### 🔄 数组扩展测试
- **testAsyncMap()** - 测试异步映射功能
- **testAsyncMapWithThrowing()** - 测试异步映射错误处理
- **testConcurrentMap()** - 测试并发映射功能
- **testConcurrentMapWithThrowing()** - 测试并发映射错误处理

#### 🌐 DNS 解析测试
- **testDNSResolveWithIPAddress()** - 测试已解析IP地址的处理
- **testDNSResolveWithHostnames()** - 测试域名解析
- **testDNSResolveWithNilEndpoints()** - 测试空端点处理
- **testDNSResolveWithMixedEndpoints()** - 测试混合端点解析

#### 📡 DNS 服务器测试
- **testDNSServerInitialization()** - 测试DNS服务器初始化
- **testDNSServerStringRepresentation()** - 测试字符串表示
- **testDNSServerFromString()** - 测试从字符串创建DNS服务器
- **testDNSServerEquality()** - 测试相等性比较

#### 🔗 端点 (Endpoint) 测试
- **testEndpointInitialization()** - 测试端点初始化
- **testEndpointStringRepresentation()** - 测试字符串表示
- **testEndpointFromString()** - 测试从字符串解析端点
- **testEndpointHasHostAsIPAddress()** - 测试IP地址判断
- **testEndpointHostname()** - 测试主机名提取
- **testEndpointEquality()** - 测试相等性比较
- **testEndpointCodable()** - 测试JSON序列化

#### 🔌 网络接口测试
- **testInterfaceAllInterfaces()** - 测试获取所有网络接口
- **testInterfaceFiltering()** - 测试接口过滤
- **testInterfaceNameList()** - 测试接口名称列表
- **testInterfaceProperties()** - 测试接口属性访问
- **testInterfaceAddressBytes()** - 测试地址字节转换
- **testInterfaceEquality()** - 测试相等性比较

#### 🌍 IP地址测试
- **testIPv4AddressCodable()** - 测试IPv4地址JSON序列化
- **testIPv6AddressCodable()** - 测试IPv6地址JSON序列化
- **testIPv4AddressLocalCheck()** - 测试IPv4本地地址检查
- **testIPv6AddressLocalCheck()** - 测试IPv6本地地址检查
- **testIPAddressTypeCheck()** - 测试IP地址类型检查

#### 🔢 IP地址范围测试
- **testIPAddressRangeInitialization()** - 测试IP范围初始化
- **testIPAddressRangeStringRepresentation()** - 测试字符串表示
- **testIPAddressRangeContains()** - 测试IP地址包含检查
- **testIPAddressRangeContainsString()** - 测试字符串IP包含检查
- **testIPAddressRangeSubnetMask()** - 测试子网掩码计算
- **testIPAddressRangeMaskedAddress()** - 测试网络地址计算
- **testIPAddressRangeEquality()** - 测试相等性比较
- **testIPAddressRangeCodable()** - 测试JSON序列化

#### 📶 WiFi测试
- **testWiFiSSIDCurrentInterfaceName()** - 测试WiFi接口名称获取
- **testWiFiSSIDCurrentSSID()** - 测试当前WiFi SSID获取
- **testWiFiSSIDCurrentSSIDLegacy()** - 测试Legacy方法获取SSID（仅macOS）

### 2. 性能测试 (NetworkKitPerformanceTests.swift)

#### ⚡ 数组操作性能
- **testAsyncMapPerformance()** - 异步映射性能测试
- **testConcurrentMapPerformance()** - 并发映射性能测试

#### 🌐 DNS解析性能
- **testDNSResolutionPerformance()** - DNS解析性能测试

#### 🔌 接口发现性能
- **testInterfaceDiscoveryPerformance()** - 接口发现性能测试
- **testInterfaceFilteringPerformance()** - 接口过滤性能测试

#### 🔢 IP地址范围性能
- **testIPAddressRangeContainsPerformance()** - IP范围包含检查性能
- **testIPAddressRangeSubnetMaskPerformance()** - 子网掩码计算性能

#### 🔗 端点解析性能
- **testEndpointParsingPerformance()** - 端点解析性能测试

#### 📊 序列化性能
- **testEndpointCodablePerformance()** - 端点序列化性能
- **testIPAddressRangeCodablePerformance()** - IP范围序列化性能

#### 📈 大数据集测试
- **testLargeIPAddressRangePerformance()** - 大IP范围性能测试
- **testMultipleInterfaceQueriesPerformance()** - 多次接口查询性能

### 3. 使用示例 (NetworkKitUsageExamples.swift)

#### 实际使用场景演示
1. **异步映射网络请求** - 展示如何使用异步映射处理网络请求
2. **并发任务处理** - 展示并发映射的使用场景
3. **批量DNS解析** - 展示如何批量解析多个域名
4. **网络接口查询** - 展示如何查询和过滤网络接口
5. **IP地址范围检查** - 展示IP地址范围的实际应用
6. **端点解析** - 展示端点字符串的解析和处理
7. **WiFi信息获取** - 展示如何获取WiFi相关信息
8. **IP地址类型检查** - 展示IP地址属性的检查方法
9. **数据序列化** - 展示对象的JSON序列化和反序列化
10. **网络诊断工具** - 综合使用示例，实现一个完整的网络诊断工具

## 运行测试

### 使用 Swift Package Manager

```bash
# 运行所有测试
swift test

# 运行特定测试文件
swift test --filter NetworkKitTests

# 运行性能测试
swift test --filter NetworkKitPerformanceTests

# 运行使用示例
swift test --filter NetworkKitUsageExamples
```

### 使用 Xcode

1. 打开 `Package.swift` 文件
2. 在 Xcode 中选择 `Product` → `Test` 或按 `Cmd+U`
3. 在测试导航器中选择特定的测试用例运行

### 测试覆盖率

运行测试时可以启用代码覆盖率：

```bash
swift test --enable-code-coverage
```

## 测试环境要求

### 系统要求
- **macOS**: 10.15+ (某些WiFi功能需要)
- **iOS**: 13.0+ (某些WiFi功能需要)
- **Swift**: 5.10+

### 权限要求
- 某些WiFi SSID获取功能可能需要特定权限
- 网络接口查询在某些环境下可能受限

### 网络依赖
- DNS解析测试需要网络连接
- 性能测试中的DNS解析需要访问外部域名

## 测试策略

### 单元测试策略
- **边界值测试** - 测试各种边界情况和异常输入
- **类型安全测试** - 确保类型转换和序列化的正确性
- **错误处理测试** - 验证异常情况的处理逻辑

### 性能测试策略
- **基准测试** - 建立性能基准线
- **压力测试** - 测试大数据集下的性能表现
- **并发测试** - 验证并发操作的效率

### 集成测试策略
- **真实环境测试** - 在真实网络环境中测试功能
- **跨平台测试** - 确保在不同Apple平台上的兼容性

## 注意事项

### 测试环境限制
- 某些测试依赖于网络状态，在离线环境下可能失败
- WiFi相关测试在没有WiFi连接的设备上可能返回nil
- 某些系统级功能在模拟器中可能表现不同

### 性能测试注意事项
- 性能测试结果可能受到系统负载影响
- 建议在相对稳定的环境中运行性能测试
- 不同设备的性能表现可能有差异

### 平台差异
- macOS和iOS在某些网络功能上有差异
- 某些测试使用了平台特定的API，会有相应的可用性检查

## 贡献指南

### 添加新测试
1. 为新功能添加相应的单元测试
2. 考虑添加性能测试以确保性能不会回退
3. 更新使用示例以展示新功能的使用方法

### 测试命名规范
- 单元测试：`test[ModuleName][FunctionName]()`
- 性能测试：`test[ModuleName]Performance()`
- 使用示例：`example[FeatureName]()`

### 测试编写原则
- 测试应该独立且可重复
- 使用清晰的断言和错误消息
- 适当使用mock和stub减少外部依赖
- 考虑异步操作的测试策略

---

通过运行这些测试，您可以确保 NetworkKit 库在各种场景下都能正常工作，并了解如何在实际项目中使用这些功能。 