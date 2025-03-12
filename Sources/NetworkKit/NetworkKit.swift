//
//  NetworkKit.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/10/24.
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.9)
#error("NetworkKit doesn't support Swift versions below 5.9.")
#endif

/// Current NetworkKit version Release 0.0.9. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
public let version = "0.0.9"
