//
//  Endpoint.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

/// Represents a network endpoint consisting of a host and port.
public struct Endpoint: Sendable {
    /// The host of the endpoint (can be a name, IPv4, or IPv6 address).
    public let host: Network.NWEndpoint.Host
    /// The port of the endpoint.
    public let port: Network.NWEndpoint.Port

    /// Creates a new endpoint with the specified host and port.
    /// - Parameters:
    ///   - host: The host (name, IPv4, or IPv6 address).
    ///   - port: The port number.
    public init(host: Network.NWEndpoint.Host, port: Network.NWEndpoint.Port) {
        self.host = host
        self.port = port
    }
}

extension Endpoint: Equatable {
    public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        return lhs.host == rhs.host && lhs.port == rhs.port
    }
}

extension Endpoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(host)
        hasher.combine(port)
    }
}

extension Endpoint: Codable {
    /// Decodes an endpoint from a string representation.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let parsed = Endpoint(from: string) {
            host = parsed.host
            port = parsed.port
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid Endpoint representation"
            )
        }
    }

    /// Encodes the endpoint as a string representation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringRepresentation)
    }
}

public extension Endpoint {
    /// Returns the string representation of the endpoint (e.g., "host:port").
    var stringRepresentation: String {
        switch host {
        case let .name(hostname, _):
            return "\(hostname):\(port)"
        case let .ipv4(address):
            return "\(address):\(port)"
        case let .ipv6(address):
            return "[\(address)]:\(port)"
        @unknown default:
            fatalError()
        }
    }

    /// Initializes an endpoint from a string (e.g., "host:port", "[IPv6]:port").
    /// - Parameter string: The string to parse.
    /// - Returns: An `Endpoint` if parsing succeeds, otherwise nil.
    init?(from string: String) {
        // Separation of host and port is based on 'parse_endpoint' function in
        // https://git.zx2c4.com/wireguard-tools/tree/src/config.c
        guard let firstC = string.first else { return nil }
        let startOfPort: String.Index
        let hostString: String
        if firstC == "[" {
            // Look for IPv6-style endpoint, like [::1]:80
            let startOfHost = string.index(after: string.startIndex)
            guard let endOfHost = string.dropFirst().firstIndex(of: "]") else { return nil }
            let afterEndOfHost = string.index(after: endOfHost)
            if afterEndOfHost == string.endIndex { return nil }
            guard string[afterEndOfHost] == ":" else { return nil }
            startOfPort = string.index(after: afterEndOfHost)
            hostString = String(string[startOfHost ..< endOfHost])
        } else {
            // Look for an IPv4-style endpoint, like 127.0.0.1:80
            guard let endOfHost = string.firstIndex(of: ":") else { return nil }
            startOfPort = string.index(after: endOfHost)
            hostString = String(string[string.startIndex ..< endOfHost])
        }

        // Validate that we have a non-empty host string
        guard !hostString.isEmpty else { return nil }

        // If it looks like an IPv4 address (only digits, dots, and possibly leading zeros), validate it properly
        let isIPv4Like = hostString.allSatisfy { $0.isWholeNumber || $0 == "." }
        if isIPv4Like, hostString.contains(".") {
            guard IPv4Address(hostString) != nil else { return nil }
        }

        // If it contains colons and looks like IPv6 (hex digits, colons only), validate it
        if hostString.contains(":") {
            let isIPv6Like = hostString.allSatisfy { $0.isHexDigit || $0 == ":" }
            if isIPv6Like {
                guard IPv6Address(hostString) != nil else { return nil }
            }
        }

        guard let endpointPort = NWEndpoint.Port(String(string[startOfPort ..< string.endIndex])) else { return nil }
        let invalidCharacterIndex = hostString.unicodeScalars.firstIndex { char in
            !CharacterSet.urlHostAllowed.contains(char)
        }
        guard invalidCharacterIndex == nil else { return nil }
        host = NWEndpoint.Host(hostString)
        port = endpointPort
    }
}

public extension Endpoint {
    /// Returns true if the host is an IP address (IPv4 or IPv6), false if it is a hostname.
    func hasHostAsIPAddress() -> Bool {
        switch host {
        case .name:
            return false
        case .ipv4:
            return true
        case .ipv6:
            return true
        @unknown default:
            fatalError()
        }
    }

    /// Returns the hostname if the host is a name, otherwise nil.
    func hostname() -> String? {
        switch host {
        case let .name(hostname, _):
            return hostname
        case .ipv4:
            return nil
        case .ipv6:
            return nil
        @unknown default:
            fatalError()
        }
    }
}
