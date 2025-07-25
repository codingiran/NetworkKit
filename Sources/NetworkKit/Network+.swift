//
//  Network+.swift
//  NetworkKit
//
//  Created by CodingIran on 2025/7/16.
//

import Foundation
import Network

public extension Network.NWPath {
    var isSatisfied: Bool { status == .satisfied }

    var statusName: String {
        switch status {
        case .satisfied: return "satisfied"
        case .unsatisfied: return "unsatisfied"
        case .requiresConnection: return "requires connection"
        @unknown default: return "unknown"
        }
    }

    @available(macOS 11.0, iOS 14.2, watchOS 7.1, tvOS 14.2, macCatalyst 14.2, visionOS 1.0, *)
    var unsatisfiedReasonText: String? {
        switch unsatisfiedReason {
        case .notAvailable: return "no specific reason"
        case .cellularDenied: return "user has disabled cellular"
        case .wifiDenied: return "user has disabled wifi"
        case .localNetworkDenied: return "user has disabled local network access"
        case .vpnInactive: return "required VPN is not active"
        @unknown default: return "unknown reason"
        }
    }

    /// Network interfaces used by this path
    var usedInterfaces: [NWInterface] {
        availableInterfaces.filter { usesInterfaceType($0.type) }
    }

    /// Physical network interfaces used by this path, excluding virtual interfaces
    var usedPhysicalInterfaces: [NWInterface] {
        usedInterfaces.filter {
            switch $0.type {
            case .wifi, .cellular, .wiredEthernet: return true
            default: return false
            }
        }
    }
}

public extension Network.NWInterface.InterfaceType {
    var name: String {
        switch self {
        case .other: return "other"
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .wiredEthernet: return "wiredEthernet"
        case .loopback: return "loopback"
        @unknown default: return "unknown"
        }
    }
}
