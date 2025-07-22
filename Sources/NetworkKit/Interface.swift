//
//  Interface.swift
//  NetworkKit
//
//  Created by CodingIran on 2025/7/17.
//

import Foundation
import Network

public struct Interface: Sendable {
    /// The name of the interface.
    public let name: String

    /// The type of the interface, such as Wi-Fi or loopback.
    public var type: InterfaceType { determineInterface() }

    /// The system interface index associated with the interface.
    public let index: UInt32

    /// The IPv4 addresses of the interface
    public let ipv4Addresses: [Network.IPv4Address]

    /// The primary IPv4 address of the interface
    public var primaryIPv4Address: Network.IPv4Address? { ipv4Addresses.first }

    /// The IPv6 addresses of the interface
    public let ipv6Addresses: [Network.IPv6Address]

    /// The primary IPv6 address of the interface
    public var primaryIPv6Address: Network.IPv6Address? { ipv6Addresses.first }

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

    /// The address family of the interface
    public let ethernetAddress: String?

    /// The IPv4 gateway address of the interface
    public var ipv4Gateway: Network.IPv4Address? {
        for ifaddr in ipv4Ifaddrs {
            if let gatewayAddress = ifaddr.gatewayAddress {
                return Network.IPv4Address(gatewayAddress)
            }
        }
        return nil
    }

    /// The IPv6 gateway address of the interface
    public var ipv6Gateway: Network.IPv6Address? {
        for ifaddr in ipv6Ifaddrs {
            if let gatewayAddress = ifaddr.gatewayAddress {
                return Network.IPv6Address(gatewayAddress)
            }
        }
        return nil
    }

    /// The hardware (MAC) address of the interface
    public var hardwareAddress: String? {
        #if os(macOS) && canImport(SystemConfiguration)
            // Prefer real hardware address from SystemConfiguration
            if let address = scInterface?.hardwareAddress {
                return address
            }
        #endif
        // Fallback to hardware address from IOKit
        return linkLayerIfaddrs.first?.hardwareAddress
    }

    /// The link layer ifaddrs of the interface
    private let linkLayerIfaddrs: [Ifaddrs]

    /// The IPv4 ifaddrs of the interface
    private let ipv4Ifaddrs: [Ifaddrs]

    /// The IPv6 ifaddrs of the interface
    private let ipv6Ifaddrs: [Ifaddrs]

    /// The SystemConfiguration interfaces of the interface
    @available(macOS 10.15, *)
    private let scInterface: SCInterface?

    /// The NetworkKit NWInterface associated with this interface
    public private(set) var nwInterface: NWInterface?
}

public extension Interface {
    /// Returns all interfaces on the system.
    ///
    /// - Returns: An array of `Interface` objects representing all interfaces on the system.
    ///            Returns an empty array if no interfaces are found.
    static func allInterfaces() -> [Interface] {
        let ifaddrsList = Ifaddrs.ifaddrsList()

        guard !ifaddrsList.isEmpty else { return [] }

        // Group interfaces by name
        let groupedByName = Dictionary(grouping: ifaddrsList, by: { $0.name })

        // Get SystemConfiguration interface info for precise type determination
        #if os(macOS) && canImport(SystemConfiguration)
            let scInterfaces = listAllHardwareInterfaces()
        #else
            let scInterfaces: [SCInterface] = []
        #endif

        // Convert each group to a single Interface
        return groupedByName.compactMap { name, ifaddrs in
            // Basic info (from any entry, as this info should be same for same interface)
            guard let firstIfaddr = ifaddrs.first else { return nil }
            let index = firstIfaddr.index
            let isUp = firstIfaddr.isUp
            let isRunning = firstIfaddr.isRunning
            let supportsMulticast = firstIfaddr.supportsMulticast

            // Extract address family related info
            let linkLayerIfaddrs = ifaddrs.filter { $0.family == .link }
            let ipv4Ifaddrs = ifaddrs.filter { $0.family == .inet }
            let ipv6Ifaddrs = ifaddrs.filter { $0.family == .inet6 }

            // Extract IPv4 address info
            let ipv4Addresses: [Network.IPv4Address] = ipv4Ifaddrs.compactMap { ifaddr in
                guard let addrString = ifaddr.address else { return nil }
                return Network.IPv4Address(addrString)
            }

            /// Extract IPv4 netmask info
            let ipv4Netmask: Network.IPv4Address? = ipv4Ifaddrs.first { $0.netmask != nil }?.netmask
                .flatMap { Network.IPv4Address($0) }
            /// Extract IPv4 broadcast address info
            let ipv4Broadcast: Network.IPv4Address? = ipv4Ifaddrs.first { $0.broadcastAddress != nil }?.broadcastAddress
                .flatMap { Network.IPv4Address($0) }
            // Extract IPv6 address info
            let ipv6Addresses: [Network.IPv6Address] = ipv6Ifaddrs.compactMap { ifaddr in
                guard let addrString = ifaddr.address else { return nil }
                return Network.IPv6Address(addrString)
            }

            /// Extract IPv6 netmask info
            let ipv6Netmask: Network.IPv6Address? = ipv6Ifaddrs.first { $0.netmask != nil }?.netmask
                .flatMap { Network.IPv6Address($0) }
            /// Extract IPv6 broadcast address info
            let ipv6Broadcast: Network.IPv6Address? = ipv6Ifaddrs.first { $0.broadcastAddress != nil }?.broadcastAddress
                .flatMap { Network.IPv6Address($0) }
            // Get ethernet address (network-used address) from AF_LINK
            let ethernetAddress = linkLayerIfaddrs.first?.address

            // Get SystemConfiguration interface
            let scInterface = scInterfaces.first { $0.bsdName == name }

            return Interface(
                name: name,
                index: index,
                ipv4Addresses: ipv4Addresses,
                ipv6Addresses: ipv6Addresses,
                ipv4Netmask: ipv4Netmask,
                ipv6Netmask: ipv6Netmask,
                ipv4Broadcast: ipv4Broadcast,
                ipv6Broadcast: ipv6Broadcast,
                isUp: isUp,
                isRunning: isRunning,
                supportsMulticast: supportsMulticast,
                ethernetAddress: ethernetAddress,
                linkLayerIfaddrs: linkLayerIfaddrs,
                ipv4Ifaddrs: ipv4Ifaddrs,
                ipv6Ifaddrs: ipv6Ifaddrs,
                scInterface: scInterface
            )
        }
        .sorted { $0.index < $1.index } // Sort by interface index
    }
}

public extension Interface {
    /// Associates a NWInterface with this Interface.
    mutating func associateNWInterface(_ interface: NWInterface) {
        nwInterface = interface
    }

    private func determineInterface() -> Interface.InterfaceType {
        // If the interface is loopback, return loopback
        if linkLayerIfaddrs.contains(where: { $0.isLoopback }) { return .loopback }
        // If we have a NWInterface, try to determine its type
        if let nwInterface,
           let type = InterfaceType(nwInterfaceType: nwInterface.type) { return type }
        // If we have a SystemConfiguration interface, use its type
        if let scInterface { return scInterface.type }
        // Fallback to heuristic type determination
        return determineInterfaceTypeHeuristic()
    }

    /// Heuristic-based interface type determination
    private func determineInterfaceTypeHeuristic() -> InterfaceType {
        // Heuristic determination based on interface name
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
        /// The network interface type used for communication over Wi-Fi networks.
        case wifi

        /// The network interface type used for communication over cellular networks.
        case cellular

        /// The network interface type used for communication over wired Ethernet networks.
        case wiredEthernet

        /// The network interface type used for communication over bridge networks.
        case bridge

        /// The network interface type used for communication over local loopback networks.
        case loopback

        /// The network interface type used for communication over virtual networks or networks of unknown types.
        case other

        #if os(macOS) && canImport(SystemConfiguration)

            private static var _kSCNetworkInterfaceTypeBridge: CFString { "Bridge" as CFString }

            init(scInterfaceType: CFString) {
                switch scInterfaceType {
                case kSCNetworkInterfaceTypeEthernet:
                    self = .wiredEthernet
                case kSCNetworkInterfaceTypeIEEE80211, kSCNetworkInterfaceTypeWWAN:
                    self = .wifi
                case InterfaceType._kSCNetworkInterfaceTypeBridge:
                    self = .bridge
                default:
                    self = .other
                }
            }

        #endif

        init?(nwInterfaceType: NWInterface.InterfaceType) {
            switch nwInterfaceType {
            case .wifi:
                self = .wifi
            case .cellular:
                self = .cellular
            case .wiredEthernet:
                self = .wiredEthernet
            case .loopback:
                self = .loopback
            default:
                return nil
            }
        }

        public var nwInterfaceType: NWInterface.InterfaceType {
            switch self {
            case .wifi: return .wifi
            case .cellular: return .cellular
            case .wiredEthernet: return .wiredEthernet
            case .loopback: return .loopback
            case .other: return .other
            case .bridge: return .other // NWInterface does not have a bridge type, return other for now
            }
        }

        public var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Wired Ethernet"
            case .bridge: return "Bridge"
            case .loopback: return "Loopback"
            case .other: return "Other"
            }
        }
    }
}

@available(macOS 10.15, *)
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

#if os(macOS) && canImport(SystemConfiguration)

    import SystemConfiguration

    public extension Interface {
        /// The list of all interfaces on the system.
        /// Alike `networksetup -listallhardwareports`
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

extension Interface: Equatable, Hashable {
    public static func == (lhs: Interface, rhs: Interface) -> Bool {
        lhs.name == rhs.name &&
            lhs.type == rhs.type &&
            lhs.index == rhs.index &&
            lhs.ipv4Addresses == rhs.ipv4Addresses &&
            lhs.ipv6Addresses == rhs.ipv6Addresses &&
            lhs.ipv4Netmask == rhs.ipv4Netmask &&
            lhs.ipv6Netmask == rhs.ipv6Netmask &&
            lhs.ipv4Broadcast == rhs.ipv4Broadcast &&
            lhs.ipv6Broadcast == rhs.ipv6Broadcast &&
            lhs.isUp == rhs.isUp &&
            lhs.isRunning == rhs.isRunning &&
            lhs.supportsMulticast == rhs.supportsMulticast &&
            lhs.ethernetAddress == rhs.ethernetAddress
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(index)
        hasher.combine(ipv4Addresses)
        hasher.combine(ipv6Addresses)
        hasher.combine(ipv4Netmask)
        hasher.combine(ipv6Netmask)
        hasher.combine(ipv4Broadcast)
        hasher.combine(ipv6Broadcast)
        hasher.combine(isUp)
        hasher.combine(isRunning)
        hasher.combine(supportsMulticast)
        hasher.combine(ethernetAddress)
    }
}

extension Interface: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "Interface(name: \(name), type: \(type), index: \(index), isUp: \(isUp), isRunning: \(isRunning))"
    }

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
