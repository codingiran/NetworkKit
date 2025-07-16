//
//  Interface.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/10/24.
//

import Darwin
import Foundation

typealias InetFamily = UInt8
typealias Flags = Int32
func destinationAddress(_ data: ifaddrs) -> UnsafeMutablePointer<sockaddr>! { return data.ifa_dstaddr }
func socketLength4(_ addr: sockaddr) -> UInt32 { return socklen_t(addr.sa_len) }

/**
 * Represents a network interface on the system (e.g., en0 with a specific IP address).
 * Wraps the `getifaddrs` system call.
 */
public struct Interface: Sendable {
    public var id = UUID()

    /// True if the interface is running (`IFF_RUNNING`).
    public var isRunning: Bool { return running }

    /// True if the interface is up (`IFF_UP`).
    public var isUp: Bool { return up }

    /// True if the interface is a loopback interface (`IFF_LOOPBACK`).
    public var isLoopback: Bool { return loopback }

    /// True if the interface supports multicast (`IFF_MULTICAST`).
    public var supportsMulticast: Bool { return multicastSupported }

    /// The interface name (e.g., "en0").
    public let name: String

    /// The address family of the interface (IPv4, IPv6, Ethernet, or other).
    public let family: Family

    /// The hardware (MAC) address of the interface, if available.
    public let hardwareAddress: String?

    /// The primary address of the interface (IPv4, IPv6, or Ethernet).
    public let address: String?

    /// The netmask of the interface (IPv4 or IPv6).
    public let netmask: String?

    /// The broadcast address of the interface (if applicable).
    public let broadcastAddress: String?

    fileprivate let running: Bool
    fileprivate let up: Bool
    fileprivate let loopback: Bool
    fileprivate let multicastSupported: Bool

    /// Initializes a new Interface with the given properties.
    /// - Parameters:
    ///   - name: The interface name.
    ///   - family: The address family.
    ///   - hardwareAddress: The hardware (MAC) address.
    ///   - address: The primary address.
    ///   - netmask: The netmask.
    ///   - running: Whether the interface is running.
    ///   - up: Whether the interface is up.
    ///   - loopback: Whether the interface is a loopback interface.
    ///   - multicastSupported: Whether the interface supports multicast.
    ///   - broadcastAddress: The broadcast address.
    public init(name: String,
                family: Family,
                hardwareAddress: String?,
                address: String?,
                netmask: String?,
                running: Bool,
                up: Bool,
                loopback: Bool,
                multicastSupported: Bool,
                broadcastAddress: String?)
    {
        self.name = name
        self.family = family
        self.hardwareAddress = hardwareAddress
        self.address = address
        self.netmask = netmask
        self.running = running
        self.up = up
        self.loopback = loopback
        self.multicastSupported = multicastSupported
        self.broadcastAddress = broadcastAddress
    }

    private init(data: ifaddrs) {
        let flags = Flags(data.ifa_flags)
        let broadcastValid: Bool = ((flags & IFF_BROADCAST) == IFF_BROADCAST)
        let family = Interface.extractFamily(data)
        self.init(name: String(cString: data.ifa_name),
                  family: family,
                  hardwareAddress: Interface.extractHardwareAddress(data),
                  address: Interface.extractAddress(data.ifa_addr),
                  netmask: Interface.extractAddress(data.ifa_netmask),
                  running: (flags & IFF_RUNNING) == IFF_RUNNING,
                  up: (flags & IFF_UP) == IFF_UP,
                  loopback: (flags & IFF_LOOPBACK) == IFF_LOOPBACK,
                  multicastSupported: (flags & IFF_MULTICAST) == IFF_MULTICAST,
                  broadcastAddress: (broadcastValid && destinationAddress(data) != nil) ? Interface.extractAddress(destinationAddress(data)) : nil)
    }

    /**
     * Returns the network format representation of the interface's IP address (using `inet_pton`).
     */
    public var addressBytes: [UInt8]? {
        guard let addr = address else { return nil }

        let af: Int32
        let len: Int
        switch family {
        case .ipv4:
            af = AF_INET
            len = 4
        case .ipv6:
            af = AF_INET6
            len = 16
        default:
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: len)
        let result = inet_pton(af, addr, &bytes)
        return (result == 1) ? bytes : nil
    }
}

public extension Interface {
    /// Returns all interfaces of IPv4 or IPv6 family.
    static func allInterfaces() -> [Interface] {
        interfaces { $1 == .ipv4 || $1 == .ipv6 }
    }

    /// Returns all interfaces that match the given condition.
    /// - Parameter condition: A closure that takes a name and a family and returns a boolean.
    /// - Returns: An array of interfaces that match the given condition.
    static func interfaces(_ condition: (String, Family) -> Bool = { _, _ in true }) -> [Interface] {
        var interfaces: [Interface] = []
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddrsPtr) == 0 {
            var ifaddrPtr = ifaddrsPtr
            while ifaddrPtr != nil {
                let ptr = ifaddrPtr!.pointee
                let family = Interface.extractFamily(ptr)
                let name = String(cString: ptr.ifa_name)
                if condition(name, family) {
                    interfaces.append(Interface(data: ptr))
                }
                ifaddrPtr = ptr.ifa_next
            }
            freeifaddrs(ifaddrsPtr)
        }
        return interfaces
    }

    /// Returns all interface names that match the given condition.
    /// - Parameter condition: A closure that takes a name and a family and returns a boolean.
    /// - Returns: An array of interface names that match the given condition.
    static func interfaceNameList(_ condition: (String, Family) -> Bool = { _, _ in true }) -> [String] {
        let nameSet: Set<String> = Set(interfaces(condition).compactMap {
            let name = $0.name
            guard !name.isEmpty else { return nil }
            return name
        })
        return Array(nameSet)
    }
}

private extension Interface {
    static func extractFamily(_ data: ifaddrs) -> Family {
        var family: Family = .other
        let addr = data.ifa_addr.pointee
        if addr.sa_family == InetFamily(AF_INET) {
            family = .ipv4
        } else if addr.sa_family == InetFamily(AF_INET6) {
            family = .ipv6
        } else if addr.sa_family == InetFamily(AF_LINK) {
            family = .ethernet
        } else {
            family = .other
        }
        return family
    }

    static func extractAddress(_ address: UnsafeMutablePointer<sockaddr>?) -> String? {
        guard let address = address else { return nil }
        if address.pointee.sa_family == sa_family_t(AF_INET) {
            return extractAddress_ipv4(address)
        }
        if address.pointee.sa_family == sa_family_t(AF_INET6) {
            return extractAddress_ipv6(address)
        }
        if address.pointee.sa_family == sa_family_t(AF_LINK) {
            return extractAddress_mac(address)
        }
        return nil
    }

    static func extractAddress_ipv4(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        guard address.pointee.sa_family == sa_family_t(AF_INET) else { return nil }
        return address.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
            var address: String?
            var hostname = [CChar](repeating: 0, count: Int(2049))
            if getnameinfo(&addr.pointee, socklen_t(socketLength4(addr.pointee)), &hostname,
                           socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0
            {
                address = String(utf8String: hostname)
            } else {
                //            var error = String.fromCString(gai_strerror(errno))!
                //            println("ERROR: \(error)")
            }
            return address
        }
    }

    static func extractAddress_ipv6(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        guard address.pointee.sa_family == sa_family_t(AF_INET6) else { return nil }
        var ip = [Int8](repeating: Int8(0), count: Int(INET6_ADDRSTRLEN))
        return inetNtoP(address, ip: &ip)
    }

    static func extractAddress_mac(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        guard address.pointee.sa_family == sa_family_t(AF_LINK) else { return nil }
        let socketAddress = address.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { $0 }
        let MAC_Byte_Count = 6
        guard Int(socketAddress.pointee.sdl_alen) == MAC_Byte_Count else { return nil }
        var macAddressBytes = [UInt8](repeating: 0, count: MAC_Byte_Count)
        let destination = macAddressBytes
            .withUnsafeMutableBufferPointer { $0.baseAddress }
        var sourceData = socketAddress.pointee.sdl_data
        let source = withUnsafePointer(to: &sourceData) {
            UnsafeRawPointer($0)
        }.advanced(by: Int(socketAddress.pointee.sdl_nlen))
        memcpy(destination, source, MAC_Byte_Count)
        let macAddress = macAddressBytes.map { String(format: "%02x", $0) }.joined(separator: ":")
        return macAddress
    }

    static func inetNtoP(_ addr: UnsafeMutablePointer<sockaddr>, ip: UnsafeMutablePointer<Int8>) -> String? {
        return addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { addr6 in
            let conversion: UnsafePointer<CChar> = inet_ntop(AF_INET6, &addr6.pointee.sin6_addr, ip, socklen_t(INET6_ADDRSTRLEN))
            return String(cString: conversion)
        }
    }

    static func extractHardwareAddress(_ data: ifaddrs) -> String? {
        #if os(macOS)
            guard let matchingDict = IOBSDNameMatching(kIOMasterPortDefault, 0, String(cString: data.ifa_name)) else {
                return nil
            }
            var iterator: io_iterator_t = 0
            defer {
                IOObjectRelease(iterator)
            }
            guard IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
                return nil
            }
            var macAddress: [UInt8]?
            var intfService = IOIteratorNext(iterator)

            while intfService != 0 {
                var controllerService: io_object_t = 0

                if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS {
                    if let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0) {
                        let data = (dataUM.takeRetainedValue() as! CFData) as Data
                        macAddress = [0, 0, 0, 0, 0, 0]
                        data.copyBytes(to: &macAddress!, count: macAddress!.count)
                    }

                    IOObjectRelease(controllerService)
                }

                IOObjectRelease(intfService)
                intfService = IOIteratorNext(iterator)
            }
            guard let macAddress else {
                return nil
            }
            return macAddress.map { String(format: "%02x", $0) }.joined(separator: ":")
        #else
            return nil
        #endif
    }
}

public extension Interface {
    /// The network interface family (IPv4, IPv6, Ethernet, or other).
    enum Family: Int, Equatable, Codable, Sendable {
        /// IPv4 family.
        case ipv4
        /// IPv6 family.
        case ipv6
        /// Ethernet family.
        case ethernet
        /// Used in case of errors or unknown family.
        case other

        /// Returns the string representation of the address family.
        public func toString() -> String {
            switch self {
            case .ipv4: return "IPv4"
            case .ipv6: return "IPv6"
            case .ethernet: return "Ethernet"
            default: return "other"
            }
        }
    }
}

extension Interface: Identifiable, Equatable, Codable {
    public static func == (lhs: Interface, rhs: Interface) -> Bool {
        return lhs.name == rhs.name
            && lhs.family == rhs.family
            && lhs.hardwareAddress == rhs.hardwareAddress
            && lhs.address == rhs.address
            && lhs.netmask == rhs.netmask
            && lhs.running == rhs.running
            && lhs.up == rhs.up
            && lhs.loopback == rhs.loopback
            && lhs.multicastSupported == rhs.multicastSupported
    }
}

extension Interface: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns the interface name.
    public var description: String { return name }

    /// Returns a string containing a summary of the interface's properties.
    public var debugDescription: String {
        var s = "Interface name:\(name) family:\(family.toString())"
        if let ip = address {
            s += " ip:\(ip)"
        }
        s += isUp ? " (up)" : " (down)"
        s += isRunning ? " (running)" : " (not running)"
        return s
    }
}

#if canImport(SystemConfiguration)

    import SystemConfiguration

    #if os(macOS)

        @available(macOS 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public struct NetworkInterface: Sendable {
            public let hardwarePortName: String
            public let bsdName: String
            public let ethernetAddress: String
            public let interfaceType: String

            public init(hardwarePortName: String, bsdName: String, ethernetAddress: String, interfaceType: String) {
                self.hardwarePortName = hardwarePortName
                self.bsdName = bsdName
                self.ethernetAddress = ethernetAddress
                self.interfaceType = interfaceType
            }
        }

        public extension Interface {
            @available(macOS 10.15, *)
            @available(iOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            static func allNetworkInterfaceInfo() -> [NetworkInterface] {
                var interfacesInfo: [NetworkInterface] = []
                if let allInterfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
                    for interface in allInterfaces {
                        if let hardwarePortName = SCNetworkInterfaceGetLocalizedDisplayName(interface),
                           let bsdName = SCNetworkInterfaceGetBSDName(interface),
                           let ethernetAddress = SCNetworkInterfaceGetHardwareAddressString(interface),
                           let kind = SCNetworkInterfaceGetInterfaceType(interface)
                        {
                            let interfaceInfo = NetworkInterface(hardwarePortName: hardwarePortName as String,
                                                                 bsdName: bsdName as String,
                                                                 ethernetAddress: ethernetAddress as String,
                                                                 interfaceType: kind as String)
                            interfacesInfo.append(interfaceInfo)
                        }
                    }
                }
                return interfacesInfo
            }
        }

    #endif

#endif
