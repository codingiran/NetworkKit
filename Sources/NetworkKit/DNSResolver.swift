//
//  DNSResolver.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation
import Network

/// Provides DNS resolution utilities for endpoints.
public enum DNSResolver: Sendable {}

public extension DNSResolver {
    /// Concurrent queue used for DNS resolutions.
    private static let resolverQueue = DispatchQueue(label: "DNSResolverQueue", qos: .default, attributes: .concurrent)

    /// Asynchronously resolves an array of endpoints, returning their resolved IP addresses or errors.
    /// - Parameter endpoints: An array of optional `Endpoint` values to resolve.
    /// - Returns: An array of optional `Result<Endpoint, DNSResolutionError>`, preserving input order.
    static func resolveAsync(endpoints: [Endpoint?]) async throws -> [Result<Endpoint, DNSResolutionError>?] {
        let isAllEndpointsAlreadyResolved = endpoints.allSatisfy { maybeEndpoint -> Bool in
            maybeEndpoint?.hasHostAsIPAddress() ?? true
        }

        if isAllEndpointsAlreadyResolved {
            return endpoints.map { endpoint in
                endpoint.map { .success($0) }
            }
        }

        return try await endpoints.concurrentMap { endpoint in
            guard let endpoint = endpoint else { return nil }

            if endpoint.hasHostAsIPAddress() {
                return .success(endpoint)
            } else {
                return Result { try DNSResolver.resolveSync(endpoint: endpoint) }
                    .mapError { error -> DNSResolutionError in
                        // swiftlint:disable:next force_cast
                        error as! DNSResolutionError
                    }
            }
        }
    }

    /// Synchronously resolves a single endpoint to its IP address.
    /// - Parameter endpoint: The endpoint to resolve.
    /// - Returns: A new `Endpoint` with the resolved IP address.
    /// - Throws: `DNSResolutionError` if resolution fails.
    private static func resolveSync(endpoint: Endpoint) throws -> Endpoint {
        guard case let .name(name, _) = endpoint.host else {
            return endpoint
        }

        var hints = addrinfo()
        hints.ai_flags = AI_ALL // Get both IPv4 and IPv6 addresses, even on DNS64 networks
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP

        var resultPointer: UnsafeMutablePointer<addrinfo>?
        defer {
            resultPointer.flatMap { freeaddrinfo($0) }
        }

        let errorCode = getaddrinfo(name, "\(endpoint.port)", &hints, &resultPointer)
        if errorCode != 0 {
            throw DNSResolutionError(errorCode: errorCode, address: name)
        }

        var ipv4Address: IPv4Address?
        var ipv6Address: IPv6Address?

        var next: UnsafeMutablePointer<addrinfo>? = resultPointer
        let iterator = AnyIterator { () -> addrinfo? in
            let result = next?.pointee
            next = result?.ai_next
            return result
        }

        for addrInfo in iterator {
            if let maybeIpv4Address = IPv4Address(addrInfo: addrInfo) {
                ipv4Address = maybeIpv4Address
                break // Prefer IPv4 address if found
            } else if let maybeIpv6Address = IPv6Address(addrInfo: addrInfo) {
                ipv6Address = maybeIpv6Address
                continue // Keep searching for IPv4 if only IPv6 found
            }
        }

        // Prefer IPv4 address over IPv6
        if let ipv4Address = ipv4Address {
            return Endpoint(host: .ipv4(ipv4Address), port: endpoint.port)
        } else if let ipv6Address = ipv6Address {
            return Endpoint(host: .ipv6(ipv6Address), port: endpoint.port)
        } else {
            // Instead of fatalError, throw a DNSResolutionError for no address found
            throw DNSResolutionError(errorCode: -1, address: name)
        }
    }
}

extension Endpoint {
    /// Returns a new endpoint with its host re-resolved to an IP address.
    /// - Throws: `DNSResolutionError` if DNS resolution fails.
    func withReresolvedIP() throws -> Endpoint {
        #if os(iOS)
            let hostname: String
            switch host {
            case let .name(name, _):
                hostname = name
            case let .ipv4(address):
                hostname = "\(address)"
            case let .ipv6(address):
                hostname = "\(address)"
            @unknown default:
                fatalError()
            }

            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_DGRAM
            hints.ai_protocol = IPPROTO_UDP
            hints.ai_flags = 0 // Set to zero to resolve using DNS64

            var result: UnsafeMutablePointer<addrinfo>?
            defer {
                result.flatMap { freeaddrinfo($0) }
            }

            let errorCode = getaddrinfo(hostname, "\(port)", &hints, &result)
            if errorCode != 0 {
                throw DNSResolutionError(errorCode: errorCode, address: hostname)
            }

            let addrInfo = result!.pointee
            if let ipv4Address = IPv4Address(addrInfo: addrInfo) {
                return Endpoint(host: .ipv4(ipv4Address), port: port)
            } else if let ipv6Address = IPv6Address(addrInfo: addrInfo) {
                return Endpoint(host: .ipv6(ipv6Address), port: port)
            } else {
                fatalError()
            }
        #elseif os(macOS)
            return self
        #else
            #error("Unimplemented")
        #endif
    }
}

/// An error type describing DNS resolution failures.
public struct DNSResolutionError: LocalizedError, Sendable {
    /// The error code returned by the resolver.
    public let errorCode: Int32
    /// The address that failed to resolve.
    public let address: String

    init(errorCode: Int32, address: String) {
        self.errorCode = errorCode
        self.address = address
    }

    /// A human-readable description of the error.
    public var errorDescription: String? {
        return String(cString: gai_strerror(errorCode))
    }
}
