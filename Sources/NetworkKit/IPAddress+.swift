//
//  IPAddress+.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

extension IPv4Address: Codable {
    /// Decodes an IPv4 address from a string.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let ipString = try container.decode(String.self)

        if let decoded = IPv4Address(ipString) {
            self = decoded
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid IPv4 representation"
            )
        }
    }

    /// Encodes the IPv4 address as a string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(reflecting: self))
    }
}

extension IPv6Address: Codable {
    /// Decodes an IPv6 address from a string.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let ipString = try container.decode(String.self)

        if let decoded = IPv6Address(ipString) {
            self = decoded
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid IPv6 representation"
            )
        }
    }

    /// Encodes the IPv6 address as a string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(reflecting: self))
    }
}

public extension IPv4Address {
    /// Initializes an IPv4 address from an `addrinfo` struct.
    /// - Parameter addrInfo: The `addrinfo` struct containing the address.
    init?(addrInfo: addrinfo) {
        guard addrInfo.ai_family == AF_INET else { return nil }
        let addressData = addrInfo.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { ptr -> Data in
            Data(bytes: &ptr.pointee.sin_addr, count: MemoryLayout<in_addr>.size)
        }
        self.init(addressData)
    }
}

public extension IPv6Address {
    /// Initializes an IPv6 address from an `addrinfo` struct.
    /// - Parameter addrInfo: The `addrinfo` struct containing the address.
    init?(addrInfo: addrinfo) {
        guard addrInfo.ai_family == AF_INET6 else { return nil }
        let addressData = addrInfo.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { ptr -> Data in
            Data(bytes: &ptr.pointee.sin6_addr, count: MemoryLayout<in6_addr>.size)
        }
        self.init(addressData)
    }
}

public extension IPv4Address {
    /// Returns true if the address is a local address (loopback, link-local, multicast, or in the loopback range).
    var isLocalAddress: Bool {
        isLoopback || isLinkLocal || isMulticast || isLoopbackRange
    }

    /// Returns true if the address is in the full loopback range (127.0.0.0/8).
    /// Foundation's isLoopback only returns true for 127.0.0.1.
    private var isLoopbackRange: Bool {
        let addressData = rawValue
        let firstOctet = addressData[addressData.startIndex]
        return firstOctet == 127
    }
}

public extension IPv6Address {
    /// Returns true if the address is a local address (loopback, link-local, unique local, or multicast).
    var isLocalAddress: Bool {
        isLoopback || isLinkLocal || isUniqueLocal || isMulticast
    }
}

public extension IPAddress {
    /// Returns true if the address is IPv4.
    var isIPv4: Bool {
        self is IPv4Address
    }

    /// Returns true if the address is IPv6.
    var isIPv6: Bool {
        self is IPv6Address
    }
}
