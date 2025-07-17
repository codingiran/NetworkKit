//
//  Interface.swift
//  NetworkKit
//
//  Created by CodingIran on 2025/7/17.
//

import Foundation
import Network

public struct Interface: Sendable, Equatable, Codable {
    /// The name of the interface.
    public let name: String

    /// The type of the interface, such as Wi-Fi or loopback.
    public let type: InterfaceType

    /// The system interface index associated with the interface.
    public let index: UInt32

    /// The address family of the interface
    public let ethernetAddress: String?

    /// The hardware (MAC) address of the interface
    public let hardwareAddress: String?

    /// The IPv4 addresses of the interface
    public let ipv4Addresses: [Network.IPv4Address]

    /// The primary IPv4 address of the interface
    public var primaryIPv4Address: Network.IPv4Address? { ipv4Addresses.first }

    /// The IPv6 addresses of the interface
    public let ipv6Addresses: [Network.IPv6Address]

    /// The primary IPv6 address of the interface
    public var primaryIPv6Address: Network.IPv6Address? { ipv6Addresses.first }

    /// The IPv4 gateway address of the interface
    public let ipv4Gateway: Network.IPv4Address?

    /// The IPv6 gateway address of the interface
    public let ipv6Gateway: Network.IPv6Address?

    /// The IPv4 netmask of the interface
    public let ipv4Netmask: Network.IPv4Address?

    /// The IPv6 netmask of the interface
    public let ipv6Netmask: Network.IPv6Address?

    /// The IPv4 broadcast address of the interface
    public let ipv4Broadcast: Network.IPv4Address?

    /// The IPv6 broadcast address of the interface
    public let ipv6Broadcast: Network.IPv6Address?

    /// True if the interface is up
    public let isUp: Bool

    /// True if the interface is running
    public let isRunning: Bool

    /// True if the interface supports multicast
    public let supportsMulticast: Bool
}

public extension Interface {
    /// Returns all interfaces on the system.
    ///
    /// - Returns: An array of `Interface` objects representing all interfaces on the system.
    ///            Returns an empty array if no interfaces are found.
    static func allInterfaces(_ condition: @escaping Ifaddrs.Condition = { _, _, _, _ in true }) -> [Interface] {
        let ifaddrsList = Ifaddrs.ifaddrsList(condition)

        guard !ifaddrsList.isEmpty else { return [] }

        // Group interfaces by name
        let groupedByName = Dictionary(grouping: ifaddrsList, by: { $0.name })

        // Get SystemConfiguration interface info for precise type determination
        #if os(macOS) && canImport(SystemConfiguration)
            let scInterfaces = listAllHardwareInterfaces()
            let scTypeMapping = Dictionary(uniqueKeysWithValues: scInterfaces.map { ($0.bsdName, $0.type) })
            let scHardwareMapping = Dictionary(uniqueKeysWithValues: scInterfaces.map { ($0.bsdName, $0.hardwareAddress) })
        #endif

        // Convert each group to a single Interface
        return groupedByName.compactMap { name, ifaddrs in
            // Basic info (from any entry, as this info should be same for same interface)
            guard let firstIfaddr = ifaddrs.first else { return nil }
            let index = firstIfaddr.index
            let isUp = firstIfaddr.isUp
            let isRunning = firstIfaddr.isRunning
            let supportsMulticast = firstIfaddr.supportsMulticast

            // Determine interface type
            #if os(macOS) && canImport(SystemConfiguration)
                let type = determineInterfaceType(name: name, ifaddrs: ifaddrs, scTypeMapping: scTypeMapping)
            #else
                let type = determineInterfaceType(name: name, ifaddrs: ifaddrs)
            #endif

            // Extract address family related info
            let linkLayerIfaddrs = ifaddrs.filter { $0.family == .link }
            let ipv4Ifaddrs = ifaddrs.filter { $0.family == .inet }
            let ipv6Ifaddrs = ifaddrs.filter { $0.family == .inet6 }

            // Get ethernet address (network-used address) from AF_LINK
            let ethernetAddress = linkLayerIfaddrs.first?.address

            // Get hardware address (real physical address)
            let hardwareAddress: String? = {
                #if os(macOS) && canImport(SystemConfiguration)
                    // Prefer real hardware address from SystemConfiguration
                    if let scHardware = scHardwareMapping[name] {
                        return scHardware
                    }
                #endif
                // Fallback to hardware address from IOKit
                return linkLayerIfaddrs.first?.hardwareAddress
            }()

            // Extract IPv4 address info
            let ipv4Addresses: [Network.IPv4Address] = ipv4Ifaddrs.compactMap { ifaddr in
                guard let addrString = ifaddr.address else { return nil }
                return Network.IPv4Address(addrString)
            }

            let ipv4Gateway: Network.IPv4Address? = ipv4Ifaddrs.first { $0.gatewayAddress != nil }?.gatewayAddress
                .flatMap { Network.IPv4Address($0) }

            let ipv4Netmask: Network.IPv4Address? = ipv4Ifaddrs.first { $0.netmask != nil }?.netmask
                .flatMap { Network.IPv4Address($0) }

            let ipv4Broadcast: Network.IPv4Address? = ipv4Ifaddrs.first { $0.broadcastAddress != nil }?.broadcastAddress
                .flatMap { Network.IPv4Address($0) }

            // Extract IPv6 address info
            let ipv6Addresses: [Network.IPv6Address] = ipv6Ifaddrs.compactMap { ifaddr in
                guard let addrString = ifaddr.address else { return nil }
                return Network.IPv6Address(addrString)
            }

            let ipv6Gateway: Network.IPv6Address? = ipv6Ifaddrs.first { $0.gatewayAddress != nil }?.gatewayAddress
                .flatMap { Network.IPv6Address($0) }

            let ipv6Netmask: Network.IPv6Address? = ipv6Ifaddrs.first { $0.netmask != nil }?.netmask
                .flatMap { Network.IPv6Address($0) }

            let ipv6Broadcast: Network.IPv6Address? = ipv6Ifaddrs.first { $0.broadcastAddress != nil }?.broadcastAddress
                .flatMap { Network.IPv6Address($0) }

            return Interface(
                name: name,
                type: type,
                index: index,
                ethernetAddress: ethernetAddress,
                hardwareAddress: hardwareAddress,
                ipv4Addresses: ipv4Addresses,
                ipv6Addresses: ipv6Addresses,
                ipv4Gateway: ipv4Gateway,
                ipv6Gateway: ipv6Gateway,
                ipv4Netmask: ipv4Netmask,
                ipv6Netmask: ipv6Netmask,
                ipv4Broadcast: ipv4Broadcast,
                ipv6Broadcast: ipv6Broadcast,
                isUp: isUp,
                isRunning: isRunning,
                supportsMulticast: supportsMulticast
            )
        }
        .sorted { $0.index < $1.index } // Sort by interface index
    }

    /// Determine interface type
    #if os(macOS) && canImport(SystemConfiguration)
        private static func determineInterfaceType(name: String,
                                                   ifaddrs: [Ifaddrs],
                                                   scTypeMapping: [String: InterfaceType])
            -> InterfaceType
        {
            // 1. Prefer precise type from SystemConfiguration (macOS)
            if let scType = scTypeMapping[name] {
                return scType
            }

            // 2. Fallback to heuristic determination
            return determineInterfaceTypeHeuristic(name: name, ifaddrs: ifaddrs)
        }
    #else
        private static func determineInterfaceType(name: String,
                                                   ifaddrs: [Ifaddrs])
            -> InterfaceType
        {
            return determineInterfaceTypeHeuristic(name: name, ifaddrs: ifaddrs)
        }
    #endif

    /// Heuristic-based interface type determination
    private static func determineInterfaceTypeHeuristic(name: String,
                                                        ifaddrs: [Ifaddrs])
        -> InterfaceType
    {
        // 1. Check if it's a loopback interface
        if ifaddrs.contains(where: { $0.isLoopback }) {
            return .loopback
        }

        // 2. Heuristic determination based on interface name
        let lowercaseName = name.lowercased()
        switch true {
        case lowercaseName.hasPrefix("lo"):
            return .loopback

        case lowercaseName.hasPrefix("en"):
            // en0 is usually the primary network interface, typically Wi-Fi on iPhone and MacBook
            // en1, en2 etc. might be Ethernet or other interfaces
            return name == "en0" ? .wifi : .wiredEthernet

        case lowercaseName.hasPrefix("bridge"):
            return .bridge

        case lowercaseName.hasPrefix("utun"),
             lowercaseName.hasPrefix("tun"),
             lowercaseName.hasPrefix("tap"),
             lowercaseName.hasPrefix("ipsec"):
            return .other // Tunnel interfaces

        case lowercaseName.hasPrefix("awdl"):
            return .other // Apple Wireless Direct Link (AirDrop)

        case lowercaseName.hasPrefix("bluetooth"),
             lowercaseName.hasPrefix("bt"):
            return .bluetooth

        case lowercaseName.contains("cellular"),
             lowercaseName.hasPrefix("pdp_ip"):
            return .cellular

        default:
            return .other
        }
    }
}

public extension Interface {
    enum InterfaceType: Sendable, Codable, Equatable, CustomStringConvertible {
        /// A Wi-Fi link
        case wifi

        /// A Cellular link
        case cellular

        /// A Wired Ethernet link
        case wiredEthernet

        /// A Bluetooth link
        case bluetooth

        /// A Bridge link
        case bridge

        /// The Loopback Interface
        case loopback

        /// A virtual or otherwise unknown interface type
        case other

        private static var _kSCNetworkInterfaceTypeBridge: CFString { "Bridge" as CFString }

        init(scInterfaceType: CFString) {
            switch scInterfaceType {
            case kSCNetworkInterfaceTypeEthernet:
                self = .wiredEthernet
            case kSCNetworkInterfaceTypeIEEE80211, kSCNetworkInterfaceTypeWWAN:
                self = .wifi
            case kSCNetworkInterfaceTypeBluetooth:
                self = .bluetooth
            case InterfaceType._kSCNetworkInterfaceTypeBridge:
                self = .bridge
            default:
                self = .other
            }
        }

        public var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Wired Ethernet"
            case .bluetooth: return "Bluetooth"
            case .bridge: return "Bridge"
            case .loopback: return "Loopback"
            case .other: return "Other"
            }
        }
    }
}

#if os(macOS) && canImport(SystemConfiguration)

    import SystemConfiguration

    public extension Interface {
        struct SCInterface: Sendable, Codable, Equatable, CustomStringConvertible {
            public let bsdName: String
            public let localizedDisplayName: String
            public let hardwareAddress: String
            public let type: InterfaceType

            public var description: String {
                "Interface(bsdName: \(bsdName), localizedDisplayName: \(localizedDisplayName), hardwareAddress: \(hardwareAddress), type: \(type.description))"
            }
        }
    }

    public extension Interface {
        static func listAllHardwareInterfaces() -> [SCInterface] {
            guard let allInterfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
            let interfaceList: [SCInterface] = allInterfaces.compactMap { interface in
                guard let bsdName = SCNetworkInterfaceGetBSDName(interface),
                      let localizedDisplayName = SCNetworkInterfaceGetLocalizedDisplayName(interface),
                      let hardwareAddress = SCNetworkInterfaceGetHardwareAddressString(interface),
                      let type = SCNetworkInterfaceGetInterfaceType(interface)
                else {
                    return nil
                }
                return SCInterface(bsdName: bsdName as String,
                                   localizedDisplayName:
                                   localizedDisplayName as String,
                                   hardwareAddress: hardwareAddress as String,
                                   type: .init(scInterfaceType: type))
            }
            return interfaceList
        }
    }

#endif

extension Interface: CustomDebugStringConvertible {
    public var debugDescription: String {
        var components: [String] = []

        // Always include basic info
        components.append("name: \(name)")
        components.append("type: \(type)")
        components.append("index: \(index)")

        // Include optional addresses only if they exist
        if let ethernetAddress = ethernetAddress {
            components.append("ethernetAddress: \(ethernetAddress)")
        }
        if let hardwareAddress = hardwareAddress {
            components.append("hardwareAddress: \(hardwareAddress)")
        }
        // Include IP addresses only if they exist
        if !ipv4Addresses.isEmpty {
            components.append("ipv4Addresses: \(ipv4Addresses)")
        }
        if !ipv6Addresses.isEmpty {
            components.append("ipv6Addresses: \(ipv6Addresses)")
        }
        // Include gateway addresses only if they exist
        if let ipv4Gateway = ipv4Gateway {
            components.append("ipv4Gateway: \(ipv4Gateway)")
        }
        if let ipv6Gateway = ipv6Gateway {
            components.append("ipv6Gateway: \(ipv6Gateway)")
        }
        // Include netmasks only if they exist
        if let ipv4Netmask = ipv4Netmask {
            components.append("ipv4Netmask: \(ipv4Netmask)")
        }
        if let ipv6Netmask = ipv6Netmask {
            components.append("ipv6Netmask: \(ipv6Netmask)")
        }
        // Include broadcast addresses only if they exist
        if let ipv4Broadcast = ipv4Broadcast {
            components.append("ipv4Broadcast: \(ipv4Broadcast)")
        }
        if let ipv6Broadcast = ipv6Broadcast {
            components.append("ipv6Broadcast: \(ipv6Broadcast)")
        }
        // Always include status flags
        components.append("isUp: \(isUp)")
        components.append("isRunning: \(isRunning)")
        components.append("supportsMulticast: \(supportsMulticast)")
        return "Interface(\(components.joined(separator: ", ")))"
    }
}
