//
//  DNSServer.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

/// Represents a DNS server using an IP address.
public struct DNSServer: Sendable {
    /// The IP address of the DNS server.
    public let address: Network.IPAddress

    /// Creates a DNS server with the specified IP address.
    /// - Parameter address: The IP address of the DNS server.
    public init(address: Network.IPAddress) {
        self.address = address
    }
}

extension DNSServer: Equatable {
    public static func == (lhs: DNSServer, rhs: DNSServer) -> Bool {
        return lhs.address.rawValue == rhs.address.rawValue
    }
}

public extension DNSServer {
    /// Returns the string representation of the DNS server's IP address.
    var stringRepresentation: String {
        return "\(address)"
    }

    /// Initializes a DNS server from a string representation of an IP address.
    /// - Parameter addressString: The string to parse as an IP address.
    /// - Returns: A `DNSServer` if the string is a valid IPv4 or IPv6 address, otherwise nil.
    init?(from addressString: String) {
        if let addr = Network.IPv4Address(addressString) {
            address = addr
        } else if let addr = Network.IPv6Address(addressString) {
            address = addr
        } else {
            return nil
        }
    }
}
