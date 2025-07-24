//
//  WiFiSSID.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/12/18.
//

import Foundation

#if canImport(Network)
    import Network
#endif

#if canImport(CoreWLAN)
    import CoreWLAN
#endif

#if canImport(SystemConfiguration)
    import SystemConfiguration
    import SystemConfiguration.CaptiveNetwork
#endif

/// Utility for retrieving the current Wi-Fi SSID on supported platforms.
public enum WiFiSSID: Sendable {
    /// Returns the current Wi-Fi SSID, using modern or legacy methods as needed.
    /// - Parameter tryLegacy: If true, attempts legacy methods if the modern API fails (macOS only).
    /// - Parameter interfaceName: The name of the network interface (macOS only).
    /// - Returns: The current Wi-Fi SSID, or nil if unavailable.
    @available(macOS 10.15, *)
    @available(iOS 13.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static func currentWiFiSSID(tryLegacy: Bool = false,
                                       interfaceName: String? = currentInterfaceName()) -> String?
    {
        #if os(macOS)
            if let ssid = CWWiFiClient.shared().interface()?.ssid() {
                return ssid
            }
            guard tryLegacy else {
                return nil
            }
            return currentSSIDLegacy(interfaceName: interfaceName) ?? currentWiFiSSIDLegacySlow()
        #elseif os(iOS)
            var ssid: String?
            if let interfaces = CNCopySupportedInterfaces() as NSArray? {
                for interface in interfaces {
                    if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                        ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                        break
                    }
                }
            }
            return ssid
        #else
            return nil
        #endif
    }

    /// Returns the current Wi-Fi SSID using legacy methods (macOS only).
    /// - Parameter interfaceName: The name of the network interface.
    /// - Returns: The SSID string, or nil if unavailable.
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static func currentSSIDLegacy(interfaceName: String? = currentInterfaceName()) -> String? {
        #if os(macOS)
            guard let interfaceName, !interfaceName.isEmpty else { return nil }
            return currentSSID(of: interfaceName)
        #else
            return nil
        #endif
    }

    /// Returns the current Wi-Fi SSID for a specific interface name (macOS only).
    /// - Parameter interfaceName: The name of the network interface.
    /// - Returns: The SSID string, or nil if unavailable.
    public static func currentSSID(of interfaceName: String) -> String? {
        #if os(macOS)
            guard !interfaceName.isEmpty else { return nil }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "ipconfig getsummary \"\(interfaceName)\" | grep '  SSID : ' | awk -F ': ' '{print $2}'"]
            let pipe = Pipe()
            process.standardOutput = pipe
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard !data.isEmpty,
                      let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !output.isEmpty
                else {
                    return nil
                }
                return output
            } catch {
                return nil
            }
        #else
            return nil
        #endif
    }

    /// Returns the current Wi-Fi interface name (macOS only).
    /// - Returns: The interface name, or nil if unavailable.
    public static func currentInterfaceName() -> String? {
        #if os(macOS)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}'"]
            let pipe = Pipe()
            process.standardOutput = pipe
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return output
            } catch {
                return nil
            }
        #else
            return nil
        #endif
    }

    /// Returns the current Wi-Fi SSID using a slow legacy method (macOS only).
    /// - Returns: The SSID string, or nil if unavailable.
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static func currentWiFiSSIDLegacySlow() -> String? {
        #if os(macOS)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1;print $0 | \"tr -d ':'\";exit}'"]
            let pipe = Pipe()
            process.standardOutput = pipe
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return output
            } catch {
                return nil
            }
        #else
            return nil
        #endif
    }
}
