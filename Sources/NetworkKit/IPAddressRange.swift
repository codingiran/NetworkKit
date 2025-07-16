//
//  IPAddressRange.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

public struct IPAddressRange: Sendable {
    /// The base IP address of the range.
    public let address: IPAddress
    /// The network prefix length (CIDR notation).
    public let networkPrefixLength: UInt8

    init(address: IPAddress, networkPrefixLength: UInt8) {
        self.address = address
        self.networkPrefixLength = networkPrefixLength
    }
}

extension IPAddressRange: Equatable {
    public static func == (lhs: IPAddressRange, rhs: IPAddressRange) -> Bool {
        return lhs.address.rawValue == rhs.address.rawValue && lhs.networkPrefixLength == rhs.networkPrefixLength
    }
}

extension IPAddressRange: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address.rawValue)
        hasher.combine(networkPrefixLength)
    }
}

extension IPAddressRange: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        if let parsed = IPAddressRange.parseAddressString(string) {
            address = parsed.0
            networkPrefixLength = parsed.1
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid IPAddressRange representation"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringRepresentation)
    }
}

public extension IPAddressRange {
    /// Returns the string representation of the IP address range in CIDR notation.
    var stringRepresentation: String {
        return "\(address)/\(networkPrefixLength)"
    }

    /// Initializes an `IPAddressRange` from a string in CIDR notation.
    /// - Parameter string: The string to parse (e.g., "192.168.1.0/24").
    init?(from string: String) {
        guard let parsed = IPAddressRange.parseAddressString(string) else { return nil }
        address = parsed.0
        networkPrefixLength = parsed.1
    }

    /// Parses a string into an IP address and prefix length.
    /// - Parameter string: The string to parse.
    /// - Returns: A tuple of IPAddress and prefix length, or nil if invalid.
    private static func parseAddressString(_ string: String) -> (IPAddress, UInt8)? {
        let endOfIPAddress = string.lastIndex(of: "/") ?? string.endIndex
        let addressString = String(string[string.startIndex ..< endOfIPAddress])
        let address: IPAddress
        if let addr = IPv4Address(addressString) {
            address = addr
        } else if let addr = IPv6Address(addressString) {
            address = addr
        } else {
            return nil
        }

        let maxNetworkPrefixLength: UInt8 = address is IPv4Address ? 32 : 128
        var networkPrefixLength: UInt8
        if endOfIPAddress < string.endIndex { // "/" was located
            let indexOfNetworkPrefixLength = string.index(after: endOfIPAddress)
            guard indexOfNetworkPrefixLength < string.endIndex else { return nil }
            let networkPrefixLengthSubstring = string[indexOfNetworkPrefixLength ..< string.endIndex]
            guard let npl = UInt8(networkPrefixLengthSubstring) else { return nil }
            networkPrefixLength = min(npl, maxNetworkPrefixLength)
        } else {
            networkPrefixLength = maxNetworkPrefixLength
        }

        return (address, networkPrefixLength)
    }

    /// Returns the subnet mask as an IPAddress for the current range.
    func subnetMask() -> IPAddress {
        if address is IPv4Address {
            let mask = networkPrefixLength > 0 ? ~UInt32(0) << (32 - networkPrefixLength) : UInt32(0)
            let bytes = Data([
                UInt8(truncatingIfNeeded: mask >> 24),
                UInt8(truncatingIfNeeded: mask >> 16),
                UInt8(truncatingIfNeeded: mask >> 8),
                UInt8(truncatingIfNeeded: mask >> 0),
            ])
            return IPv4Address(bytes)!
        }
        if address is IPv6Address {
            var bytes = Data(repeating: 0, count: 16)
            for i in 0 ..< Int(networkPrefixLength / 8) {
                bytes[i] = 0xFF
            }
            let nibble = networkPrefixLength % 32
            if nibble != 0 {
                let mask = ~UInt32(0) << (32 - nibble)
                let i = Int(networkPrefixLength / 32 * 4)
                bytes[i + 0] = UInt8(truncatingIfNeeded: mask >> 24)
                bytes[i + 1] = UInt8(truncatingIfNeeded: mask >> 16)
                bytes[i + 2] = UInt8(truncatingIfNeeded: mask >> 8)
                bytes[i + 3] = UInt8(truncatingIfNeeded: mask >> 0)
            }
            return IPv6Address(bytes)!
        }
        fatalError()
    }

    /// Returns the network address (masked address) for the range.
    func maskedAddress() -> IPAddress {
        let subnet = subnetMask().rawValue
        var masked = Data(address.rawValue)
        if subnet.count != masked.count {
            fatalError()
        }
        for i in 0 ..< subnet.count {
            masked[i] &= subnet[i]
        }
        if subnet.count == 4 {
            return IPv4Address(masked)!
        }
        if subnet.count == 16 {
            return IPv6Address(masked)!
        }
        fatalError()
    }
}

// MARK: - Contains

public extension IPAddressRange {
    /// Checks if the given IP address is within the range.
    /// - Parameter ip: The IP address to check.
    /// - Returns: True if the IP is in the range, false otherwise.
    func contains(_ ip: IPAddress) -> Bool {
        guard ip.isIPv4 == address.isIPv4 else {
            return false
        }

        let subnet = subnetMask().rawValue
        var maskedIP = Data(ip.rawValue)
        if subnet.count != maskedIP.count {
            return false
        }
        for i in 0 ..< subnet.count {
            maskedIP[i] &= subnet[i]
        }
        return maskedIP == maskedAddress().rawValue
    }

    /// Checks if the given IP address string is within the range.
    /// - Parameter ip: The IP address string to check.
    /// - Returns: True if the IP is in the range, false otherwise.
    func contains(_ ip: String) -> Bool {
        guard let ipAddress: IPAddress = {
            if let ipv4 = IPv4Address(ip) {
                return ipv4
            }
            if let ipv6 = IPv6Address(ip) {
                return ipv6
            }
            return nil
        }() else {
            return false
        }

        return contains(ipAddress)
    }
}

public extension IPAddressRange {
    /// Returns the first usable IP address in the range.
    var firstUsableIP: IPAddress? {
        return self[0]
    }

    /// Returns the last usable IP address in the range.
    var lastUsableIP: IPAddress? {
        let count = usableIPAddressCount
        guard count > 0 else { return nil }
        return self[Int(count - 1)]
    }

    /// Returns the total number of usable IP addresses in the range.
    var usableIPAddressCount: UInt64 {
        if isSingleHost {
            return 1
        }

        let hostBits = hostBitCount
        guard hostBits < 64 else {
            // For very large IPv6 ranges, return a reasonable maximum value.
            return UInt64.max
        }

        let totalAddresses = UInt64(1) << hostBits
        // Subtract network and broadcast addresses
        return totalAddresses > 2 ? totalAddresses - 2 : 0
    }

    /// Returns true if the range represents a single host address (/32 for IPv4, /128 for IPv6).
    var isSingleHost: Bool {
        let maxPrefixLength: UInt8 = address.isIPv4 ? 32 : 128
        return networkPrefixLength >= maxPrefixLength
    }

    /// Returns the number of host bits in the range.
    var hostBitCount: UInt8 {
        let maxPrefixLength: UInt8 = address.isIPv4 ? 32 : 128
        return maxPrefixLength - networkPrefixLength
    }

    /// Returns the broadcast address for the range.
    var broadcastAddress: IPAddress {
        let networkAddr = maskedAddress().rawValue
        let hostBits = hostBitCount

        if address.isIPv4 {
            let hostMask = hostBits >= 32 ? UInt32.max : (UInt32(1) << hostBits) - 1
            let networkValue = networkAddr.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            let broadcastValue = (networkValue | hostMask).bigEndian
            var broadcastValueCopy = broadcastValue
            let broadcastData = Data(bytes: &broadcastValueCopy, count: 4)
            return IPv4Address(broadcastData)!
        } else {
            // IPv6
            var broadcastData = Data(networkAddr)
            let fullBytes = Int(hostBits / 8)
            let remainingBits = hostBits % 8

            // Set full bytes to 0xFF
            for i in (16 - fullBytes) ..< 16 {
                broadcastData[i] = 0xFF
            }

            // Handle remaining bits
            if remainingBits > 0 && fullBytes < 16 {
                let byteIndex = 16 - fullBytes - 1
                let mask = UInt8((1 << remainingBits) - 1)
                broadcastData[byteIndex] |= mask
            }

            return IPv6Address(broadcastData)!
        }
    }

    /// Increments or decrements an IP address by a given offset.
    /// - Parameters:
    ///   - ipAddress: The base IP address.
    ///   - offset: The offset to add (can be negative).
    /// - Returns: The resulting IP address after applying the offset.
    func incrementIPAddress(_ ipAddress: IPAddress, by offset: Int64) -> IPAddress {
        let data = ipAddress.rawValue

        if ipAddress.isIPv4 {
            let value = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            let newValue = UInt32(Int64(value) + offset)
            var bigEndianValue = newValue.bigEndian
            let newData = Data(bytes: &bigEndianValue, count: 4)
            return IPv4Address(newData)!
        } else {
            // IPv6 - use big integer arithmetic
            var result = Array(data.reversed()) // Convert to little-endian for calculation
            var carry = offset

            for i in 0 ..< result.count {
                if carry == 0 { break }

                let sum = Int64(result[i]) + carry
                result[i] = UInt8(sum & 0xFF)
                carry = sum >> 8
            }

            let newData = Data(result.reversed()) // Convert back to big-endian
            return IPv6Address(newData)!
        }
    }
}

// MARK: - Subscript

public extension IPAddressRange {
    /// Returns the IP address at the specified 0-based index, or nil if out of range.
    /// - Parameter index: The 0-based index of the usable IP address.
    /// - Returns: The IP address at the given index, or nil if out of range.
    subscript(index: Int) -> IPAddress? {
        guard index >= 0, UInt64(index) < usableIPAddressCount else {
            return nil
        }

        if isSingleHost {
            return index == 0 ? address : nil
        }

        // The 0th usable IP is network address + 1, so the index-th is network address + index + 1
        return incrementIPAddress(maskedAddress(), by: Int64(index + 1))
    }

    /// Safe subscript: returns the IP address at the given index, or nil if out of range.
    /// - Parameter index: The 0-based index.
    /// - Returns: The IP address at the given index, or nil if out of range.
    subscript(safe index: Int) -> IPAddress? {
        return self[index] // The base subscript already includes all bounds checks
    }

    /// Returns an array of IP addresses for the specified range of indices.
    /// - Parameter range: The 0-based index range.
    /// - Returns: An array of IP addresses within the range.
    subscript(range: Range<Int>) -> [IPAddress] {
        return range.compactMap { self[$0] }
    }

    /// Returns an array of IP addresses for the specified closed range of indices.
    /// - Parameter range: The 0-based closed index range.
    /// - Returns: An array of IP addresses within the closed range.
    subscript(range: ClosedRange<Int>) -> [IPAddress] {
        return range.compactMap { self[$0] }
    }

    /// Returns an array of IP addresses from the specified start index to the end (up to a limit).
    /// - Parameter range: The partial range from a start index.
    /// - Returns: An array of IP addresses from the start index to the end (up to 1000 addresses).
    subscript(range: PartialRangeFrom<Int>) -> [IPAddress] {
        let endIndex = min(range.lowerBound + 1000, Int(usableIPAddressCount)) // Limit to avoid memory issues
        return (range.lowerBound ..< endIndex).compactMap { self[$0] }
    }

    /// Returns an array of IP addresses from the start up to (but not including) the specified end index.
    /// - Parameter range: The partial range up to an end index.
    /// - Returns: An array of IP addresses from the start up to the end index.
    subscript(range: PartialRangeUpTo<Int>) -> [IPAddress] {
        return (0 ..< range.upperBound).compactMap { self[$0] }
    }

    /// Returns an array of IP addresses from the start up to and including the specified end index.
    /// - Parameter range: The partial range through an end index.
    /// - Returns: An array of IP addresses from the start through the end index.
    subscript(range: PartialRangeThrough<Int>) -> [IPAddress] {
        return (0 ... range.upperBound).compactMap { self[$0] }
    }
}
