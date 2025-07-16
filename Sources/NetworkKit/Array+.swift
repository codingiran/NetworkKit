//
//  Array+.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation

public extension Array {
    /// Asynchronously maps each element of the array using the provided transform, sequentially.
    /// - Parameter transform: An async throwing closure that transforms each element.
    /// - Returns: An array containing the transformed elements, in order.
    func asyncMap<T>(_ transform: @Sendable @escaping (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    /// Concurrently maps each element of the array using the provided async transform.
    /// - Parameter transform: An async throwing closure that transforms each element.
    /// - Returns: An array containing the transformed elements, in order.
    /// - Note: All transformations are performed concurrently. Requires Element and T to conform to Sendable.
    func concurrentMap<T>(_ transform: @Sendable @escaping (Element) async throws -> T) async throws -> [T] where Element: Sendable, T: Sendable {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}
