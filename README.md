# NetworkKit

NetworkKit is a library for managing network interfaces and connections.

## Requirements

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- visionOS 1.0+
- Swift 5.10+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/codingiran/NetworkKit.git", from: "0.0.5")
]
```

## Features

### Network Interface Information

// Get all network interfaces
```swift
let interfaces = Interface.allInterfaces()
for interface in interfaces {
    print("Interface: \(interface.name)")
    print("IP Address: \(interface.address ?? "N/A")")
    print("Hardware Address: \(interface.hardwareAddress ?? "N/A")")
}
```

### WiFi SSID Access
Access current WiFi network information (iOS/macOS):
```swift
// use tryLegacy to fallback to legacy method, it can ignore location permission on macOS
if let ssid = WiFiSSID.currentWiFiSSID(tryLegacy: true) {
    print("Current WiFi Network: \(ssid)")
}
```

### IP Address Range
Work with IP address ranges and subnets:
```swift
// Create an IP address range from CIDR notation
if let range = IPAddressRange(from: "192.168.1.0/24") {
    // Get subnet mask
    let subnetMask = range.subnetMask()
    print("Subnet Mask: \(subnetMask)")
    
    // Get network address (masked address)
    let networkAddress = range.maskedAddress()
    print("Network Address: \(networkAddress)")
    
    // Get string representation
    print("CIDR Notation: \(range.stringRepresentation)")
}
```

### IP Address Utilities
Extended functionality for IPv4 and IPv6 addresses:
```swift
// Check if an IP address is local
let ipv4 = IPv4Address("127.0.0.1")!
print("Is local address: \(ipv4.isLocalAddress)") // true for loopback, link-local, or multicast

let ipv6 = IPv6Address("fe80::1")!
print("Is local address: \(ipv6.isLocalAddress)") // true for loopback, link-local, unique-local, or multicast

// Create IP addresses from network address info
if let address = IPv4Address(addrInfo: someAddrInfo) {
    print("IPv4 Address: \(address)")
}
```

### DNS Resolution
Resolve hostnames to IP addresses and manage DNS servers:
```swift
// Resolve multiple endpoints concurrently
let endpoints = [
    Endpoint(host: "www.google.com", port: 80),
    Endpoint(host: "www.github.com", port: 443)
]
let results = DNSResolver.resolveSync(endpoints: endpoints)
for result in results {
    switch result {
    case .success(let endpoint):
        print("Resolved: \(endpoint)")
    case .failure(let error):
        print("Resolution failed: \(error.localizedDescription)")
    case .none:
        print("No resolution attempted")
    }
}

// Work with DNS servers
if let dnsServer = DNSServer(from: "8.8.8.8") {
    print("DNS Server: \(dnsServer.stringRepresentation)")
}
```

## License

NetworkKit is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## Contact

For any questions or feedback, please contact me at [codingiran@gmail.com](mailto:codingiran@gmail.com).
