//
//  Ifaddrs.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/10/24.
//

import Darwin
import Foundation

/**
 * Represents a network interface on the system (e.g., en0 with a specific IP address).
 * Wraps the `getifaddrs` system call.
 */
public struct Ifaddrs: Equatable, Codable, Sendable {
    /// The interface name (e.g., "en0").
    public let name: String

    /// The system interface index associated with the interface.
    public let index: UInt32

    /// The address family of the interface (IPv4, IPv6, link-layer, or other).
    public let family: Family

    /// The hardware (MAC) address of the interface, if available.
    public let hardwareAddress: String?

    /// The primary address of the interface (IPv4, IPv6, or link-layer).
    public let address: String?

    /// The netmask of the interface (IPv4 or IPv6).
    public let netmask: String?

    /// True if the interface is running (`IFF_RUNNING`).
    public let isRunning: Bool

    /// True if the interface is up (`IFF_UP`).
    public let isUp: Bool

    /// True if the interface is a loopback interface (`IFF_LOOPBACK`).
    public let isLoopback: Bool

    /// True if the interface supports multicast (`IFF_MULTICAST`).
    public let supportsMulticast: Bool

    /// The broadcast address of the interface (if applicable).
    public let broadcastAddress: String?

    /// The gateway address of the interface (if applicable).
    public let gatewayAddress: String?

    /// Initializes a new Ifaddrs with the given properties.
    /// - Parameters:
    ///   - name: The interface name.
    ///   - index: The system interface index.
    ///   - family: The address family.
    ///   - hardwareAddress: The hardware (MAC) address.
    ///   - address: The primary address.
    ///   - netmask: The netmask.
    ///   - isRunning: Whether the interface is running.
    ///   - isUp: Whether the interface is up.
    ///   - isLoopback: Whether the interface is a loopback interface.
    ///   - supportsMulticast: Whether the interface supports multicast.
    ///   - broadcastAddress: The broadcast address.
    ///   - gatewayAddress: The gateway address.
    public init(name: String,
                index: UInt32,
                family: Family,
                hardwareAddress: String?,
                address: String?,
                netmask: String?,
                isRunning: Bool,
                isUp: Bool,
                isLoopback: Bool,
                supportsMulticast: Bool,
                broadcastAddress: String?,
                gatewayAddress: String?)
    {
        self.name = name
        self.index = index
        self.family = family
        self.hardwareAddress = hardwareAddress
        self.address = address
        self.netmask = netmask
        self.isRunning = isRunning
        self.isUp = isUp
        self.isLoopback = isLoopback
        self.supportsMulticast = supportsMulticast
        self.broadcastAddress = broadcastAddress
        self.gatewayAddress = gatewayAddress
    }

    private init(name: String, isUp: Bool, isRunning: Bool, isLoopback: Bool, flags: Flags, ifaddrs: ifaddrs) {
        let index = if_nametoindex(ifaddrs.ifa_name)
        let family = Ifaddrs.extractFamily(ifaddrs)
        let supportsMulticast = (flags & IFF_MULTICAST) == IFF_MULTICAST
        let broadcastValid: Bool = ((flags & IFF_BROADCAST) == IFF_BROADCAST)
        self.init(name: name,
                  index: index,
                  family: family,
                  hardwareAddress: Ifaddrs.extractHardwareAddress(ifaddrs),
                  address: Ifaddrs.extractAddress(ifaddrs.ifa_addr),
                  netmask: Ifaddrs.extractAddress(ifaddrs.ifa_netmask),
                  isRunning: isRunning,
                  isUp: isUp,
                  isLoopback: isLoopback,
                  supportsMulticast: supportsMulticast,
                  broadcastAddress: (broadcastValid && destinationAddress(ifaddrs) != nil) ? Ifaddrs.extractAddress(destinationAddress(ifaddrs)) : nil,
                  gatewayAddress: Ifaddrs.extractGatewayAddress(name, ifaddrs.ifa_addr.pointee.sa_family))
    }

    /**
     * Returns the network format representation of the interface's IP address (using `inet_pton`).
     */
    public var addressBytes: [UInt8]? {
        guard let addr = address else { return nil }

        let af: Int32
        let len: Int
        switch family {
        case .inet:
            af = AF_INET
            len = 4
        case .inet6:
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

public extension Ifaddrs {
    /// A closure that takes a name, isUp, isRunning, and isLoopback and returns a boolean.
    typealias Condition = @Sendable (_ name: String, _ isUp: Bool, _ isRunning: Bool, _ isLoopback: Bool) -> Bool

    /// Returns all interfaces that match the given condition.
    /// - Parameter condition: A closure that takes a name, family, isUp, isRunning, and isLoopback and returns a boolean.
    /// - Returns: An array of interfaces that match the given condition.
    static func ifaddrsList(_ condition: @escaping Condition = { _, _, _, _ in true }) -> [Ifaddrs] {
        var interfaces: [Ifaddrs] = []
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddrsPtr) == 0 {
            var ifaddrPtr = ifaddrsPtr
            while ifaddrPtr != nil {
                let ifaddrs = ifaddrPtr!.pointee
                let name = String(cString: ifaddrs.ifa_name)
                let flags = Flags(ifaddrs.ifa_flags)
                let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
                let isUp = (flags & IFF_UP) == IFF_UP
                let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
                if condition(name, isUp, isRunning, isLoopback) {
                    interfaces.append(Ifaddrs(name: name, isUp: isUp, isRunning: isRunning, isLoopback: isLoopback, flags: flags, ifaddrs: ifaddrs))
                }
                ifaddrPtr = ifaddrs.ifa_next
            }
            freeifaddrs(ifaddrsPtr)
        }
        return interfaces
    }
}

extension Ifaddrs: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns the interface name.
    public var description: String { return name }

    /// Returns a string containing a summary of the interface's properties.
    public var debugDescription: String {
        var s = "Interface name:\(name) family:\(family) index:\(index)"
        if let ip = address {
            s += " ip:\(ip)"
        }
        if let netmask = netmask {
            s += " netmask:\(netmask)"
        }
        if let broadcastAddress = broadcastAddress {
            s += " broadcast:\(broadcastAddress)"
        }
        if let gatewayAddress = gatewayAddress {
            s += " gateway:\(gatewayAddress)"
        }
        if let hardwareAddress = hardwareAddress {
            s += " hardware:\(hardwareAddress)"
        }
        s += isLoopback ? " (loopback)" : " (not loopback)"
        s += supportsMulticast ? " (supports multicast)" : " (no multicast)"
        s += isUp ? " (up)" : " (down)"
        s += isRunning ? " (running)" : " (not running)"
        return s
    }
}

typealias InetFamily = UInt8
typealias Flags = Int32
func destinationAddress(_ data: ifaddrs) -> UnsafeMutablePointer<sockaddr>! { return data.ifa_dstaddr }
func socketLength4(_ addr: sockaddr) -> UInt32 { return socklen_t(addr.sa_len) }

private extension Ifaddrs {
    static func extractFamily(_ data: ifaddrs) -> Family {
        var family: Family = .other
        let addr = data.ifa_addr.pointee
        if addr.sa_family == InetFamily(AF_INET) {
            family = .inet
        } else if addr.sa_family == InetFamily(AF_INET6) {
            family = .inet6
        } else if addr.sa_family == InetFamily(AF_LINK) {
            family = .link
        } else {
            family = .other
        }
        return family
    }

    static func extractAddress(_ address: UnsafeMutablePointer<sockaddr>?) -> String? {
        guard let address = address else { return nil }
        if address.pointee.sa_family == sa_family_t(AF_INET) {
            return extractAddressInet(address)
        }
        if address.pointee.sa_family == sa_family_t(AF_INET6) {
            return extractAddressInet6(address)
        }
        if address.pointee.sa_family == sa_family_t(AF_LINK) {
            return extractAddressLink(address)
        }
        return nil
    }

    static func extractAddressInet(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        guard address.pointee.sa_family == sa_family_t(AF_INET) else { return nil }
        return address.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
            var address: String?
            var hostname = [CChar](repeating: 0, count: Int(2049))
            if getnameinfo(&addr.pointee, socklen_t(socketLength4(addr.pointee)), &hostname,
                           socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0
            {
                address = String(utf8String: hostname)
            }
            return address
        }
    }

    static func extractAddressInet6(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        guard address.pointee.sa_family == sa_family_t(AF_INET6) else { return nil }
        var ip = [Int8](repeating: Int8(0), count: Int(INET6_ADDRSTRLEN))
        return inetNtoP(address, ip: &ip)
    }

    static func extractAddressLink(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
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

    static func extractGatewayAddress(_ ifa_name: String, _ family: sa_family_t) -> String? {
        var mib: [Int32] = [CTL_NET,
                            PF_ROUTE,
                            0,
                            0,
                            NET_RT_DUMP2,
                            0]
        let mibSize = u_int(mib.count)

        var bufSize = 0
        sysctl(&mib, mibSize, nil, &bufSize, nil, 0)

        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        defer { buf.deallocate() }
        buf.initialize(repeating: 0, count: bufSize)

        guard sysctl(&mib, mibSize, buf, &bufSize, nil, 0) == 0 else { return nil }

        // Routes
        var next = buf
        let lim = next.advanced(by: bufSize)
        while next < lim {
            let rtm = next.withMemoryRebound(to: rt_msghdr2.self, capacity: 1) { $0.pointee }
            var ifname = [CChar](repeating: 0, count: Int(IFNAMSIZ + 1))
            if_indextoname(UInt32(rtm.rtm_index), &ifname)

            if String(utf8String: ifname) == ifa_name, let addr = getGateFromRTM(rtm, next, family) {
                return addr
            }

            next = next.advanced(by: Int(rtm.rtm_msglen))
        }

        return nil
    }
}

public extension Ifaddrs {
    /// The network interface family (IPv4, IPv6, link-layer, or other).
    enum Family: Int, Equatable, Codable, Sendable, CustomStringConvertible {
        /// IPv4 family (AF_INET).
        case inet
        /// IPv6 family (AF_INET6).
        case inet6
        /// Link-layer family (AF_LINK) - MAC addresses, hardware addresses.
        case link
        /// Used in case of errors or unknown family.
        case other

        /// Returns the string representation of the address family.
        public var description: String {
            switch self {
            case .inet: return "AF_INET"
            case .inet6: return "AF_INET6"
            case .link: return "AF_LINK"
            default: return "other"
            }
        }
    }
}

private extension Ifaddrs {
    #if !os(macOS)

        private static let RTAX_GATEWAY = 1
        private static let RTAX_MAX = 8

        private struct rt_metrics {
            public var rmx_locks: UInt32 /* Kernel leaves these values alone */
            public var rmx_mtu: UInt32 /* MTU for this path */
            public var rmx_hopcount: UInt32 /* max hops expected */
            public var rmx_expire: Int32 /* lifetime for route, e.g. redirect */
            public var rmx_recvpipe: UInt32 /* inbound delay-bandwidth product */
            public var rmx_sendpipe: UInt32 /* outbound delay-bandwidth product */
            public var rmx_ssthresh: UInt32 /* outbound gateway buffer limit */
            public var rmx_rtt: UInt32 /* estimated round trip time */
            public var rmx_rttvar: UInt32 /* estimated rtt variance */
            public var rmx_pksent: UInt32 /* packets sent using this route */
            public var rmx_state: UInt32 /* route state */
            public var rmx_filler: (UInt32, UInt32, UInt32) /* will be used for TCP's peer-MSS cache */
        }

        private struct rt_msghdr2 {
            public var rtm_msglen: u_short /* to skip over non-understood messages */
            public var rtm_version: u_char /* future binary compatibility */
            public var rtm_type: u_char /* message type */
            public var rtm_index: u_short /* index for associated ifp */
            public var rtm_flags: Int32 /* flags, incl. kern & message, e.g. DONE */
            public var rtm_addrs: Int32 /* bitmask identifying sockaddrs in msg */
            public var rtm_refcnt: Int32 /* reference count */
            public var rtm_parentflags: Int32 /* flags of the parent route */
            public var rtm_reserved: Int32 /* reserved field set to 0 */
            public var rtm_use: Int32 /* from rtentry */
            public var rtm_inits: UInt32 /* which metrics we are initializing */
            public var rtm_rmx: rt_metrics /* metrics themselves */
        }

    #endif

    private static func getGateFromRTM(_ rtm: rt_msghdr2, _ ptr: UnsafeMutablePointer<UInt8>, _ family: sa_family_t) -> String? {
        var rawAddr = ptr.advanced(by: MemoryLayout<rt_msghdr2>.stride)

        for idx in 0 ..< RTAX_MAX {
            let sockAddr = rawAddr.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0.pointee }

            if (rtm.rtm_addrs & (1 << idx)) != 0 && idx == RTAX_GATEWAY {
                if family == sockAddr.sa_family {
                    if family == AF_INET6 {
                        var sAddr6 = rawAddr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }.sin6_addr
                        var addrV6 = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                        inet_ntop(AF_INET6, &sAddr6, &addrV6, socklen_t(INET6_ADDRSTRLEN))
                        return String(cString: addrV6, encoding: .ascii)
                    }
                    if family == AF_INET {
                        let sAddr = rawAddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }.sin_addr
                        // Take the first match, assuming its destination is "default"
                        return String(cString: inet_ntoa(sAddr), encoding: .ascii)
                    }
                }
            }

            rawAddr = rawAddr.advanced(by: Int(sockAddr.sa_len))
        }

        return nil
    }
}
