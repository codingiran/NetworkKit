//
//  NetworkKit.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/10/24.
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.5)
#error("NetworkKit doesn't support Swift versions below 5.5.")
#endif

public enum NetworkKit: Sendable {
    /// Current NetworkKit version Release 0.0.7. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
    public static let version = "0.0.7"
}
