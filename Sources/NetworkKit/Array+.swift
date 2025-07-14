//
//  Array+.swift
//  NetworkKit
//
//  Created by CodingIran on 2024/5/29.
//

import Foundation

public extension Array {
    func asyncMap<T>(_ transform: @Sendable @escaping (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

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
