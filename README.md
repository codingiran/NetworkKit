# NetworkKit

A comprehensive Swift networking utility library for Apple platforms, providing essential network operations with modern async/await support.

## Features

- **🚀 Async Array Operations** - Concurrent and sequential async mapping with full error handling
- **🌐 DNS Resolution** - Batch DNS resolution with intelligent IPv4/IPv6 handling
- **📡 Network Interface Discovery** - System network interface enumeration and filtering
- **🔍 IP Address Utilities** - Type checking, validation, and local address detection
- **📊 CIDR Support** - IP address range parsing and subnet calculations
- **📶 WiFi Integration** - SSID retrieval with platform-specific implementations
- **⚡ High Performance** - Optimized for speed with comprehensive benchmarking
- **🛡️ Type Safe** - Full Swift 6.0 concurrency support with Sendable conformance

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ / visionOS 1.0+
- Swift 5.10+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add NetworkKit to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/codingiran/NetworkKit.git", from: "0.1.0")
]
```

## Quick Start

### DNS Resolution

```swift
import NetworkKit

// Resolve multiple endpoints concurrently
let endpoints = [
    Endpoint(host: .name("www.apple.com", nil), port: 80),
    Endpoint(host: .name("www.google.com", nil), port: 443)
]

let results = try await DNSResolver.resolveAsync(endpoints: endpoints)
for result in results {
    switch result {
    case .success(let endpoint):
        print("Resolved: \(endpoint.stringRepresentation)")
    case .failure(let error):
        print("Failed: \(error.localizedDescription)")
    case .none:
        break
    }
}
```

### Network Interface Discovery

```swift
// Get all network interfaces
let interfaces = Interface.allInterfaces()
for interface in interfaces {
    print("\(interface.name): \(interface.address ?? "N/A")")
}

// Filter specific interfaces
let wifiInterfaces = Interface.interfaces { name, family in
    name.starts(with: "en") && family == .ipv4
}
```

### IP Address Range Operations

```swift
// Parse CIDR notation
let range = IPAddressRange(from: "192.168.1.0/24")!
print("Network: \(range.stringRepresentation)")

// Check if IP is in range
let isInRange = range.contains("192.168.1.100") // true
let subnet = range.subnetMask() // 255.255.255.0
```

### WiFi SSID Retrieval

```swift
// Get current WiFi SSID (macOS/iOS)
if let ssid = WiFiSSID.currentWiFiSSID() {
    print("Connected to: \(ssid)")
}
```

## API Overview

### Core Modules

- **`DNSResolver`** - Batch DNS resolution with error handling
- **`DNSServer`** - DNS server representation and parsing
- **`Endpoint`** - Network endpoint parsing and validation
- **`Interface`** - System network interface discovery
- **`IPAddress+`** - IP address utilities and validation
- **`IPAddressRange`** - CIDR parsing and subnet operations
- **`WiFiSSID`** - WiFi network information retrieval

### JSON Serialization

All network objects support JSON encoding/decoding:

```swift
let endpoint = Endpoint(host: .name("example.com", nil), port: 80)
let data = try JSONEncoder().encode(endpoint)
let decoded = try JSONDecoder().decode(Endpoint.self, from: data)
```

## Testing

NetworkKit includes comprehensive test coverage:

```bash
# Run all tests
swift test

# Run specific test categories
./test_runner.sh --unit-tests
./test_runner.sh --performance-tests
./test_runner.sh --usage-examples
```

- **64 total tests** across unit, performance, and integration testing
- **100% API coverage** with real-world usage examples
- **Performance benchmarks** for all major operations
- **Cross-platform validation** for iOS, macOS, tvOS, watchOS, and visionOS


## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
