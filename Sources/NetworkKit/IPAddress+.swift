//
//  IPAddress+.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

extension IPv4Address: Codable {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(String(reflecting: self))
    }
}

extension IPv6Address: Codable {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(String(reflecting: self))
    }
}

public extension IPv4Address {
    init?(addrInfo: addrinfo) {
        guard addrInfo.ai_family == AF_INET else { return nil }

        let addressData = addrInfo.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { ptr -> Data in
            Data(bytes: &ptr.pointee.sin_addr, count: MemoryLayout<in_addr>.size)
        }

        self.init(addressData)
    }
}

public extension IPv6Address {
    init?(addrInfo: addrinfo) {
        guard addrInfo.ai_family == AF_INET6 else { return nil }

        let addressData = addrInfo.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { ptr -> Data in
            Data(bytes: &ptr.pointee.sin6_addr, count: MemoryLayout<in6_addr>.size)
        }

        self.init(addressData)
    }
}

public extension IPv4Address {
    var isLocalAddress: Bool {
        return self.isLoopback || self.isLinkLocal || self.isMulticast
    }
}

public extension IPv6Address {
    var isLocalAddress: Bool {
        return self.isLoopback || self.isLinkLocal || self.isUniqueLocal || self.isMulticast
    }
}
