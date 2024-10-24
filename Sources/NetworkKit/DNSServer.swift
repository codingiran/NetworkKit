//
//  DNSServer.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

public struct DNSServer {
    public let address: Network.IPAddress

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
    var stringRepresentation: String {
        return "\(address)"
    }

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
