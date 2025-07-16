import Network
@testable import NetworkKit
import XCTest

final class NetworkKitArrayTests: XCTestCase {
    // MARK: - Array Extension Tests

    func testAsyncMap() async {
        let array = [1, 2, 3, 4, 5]
        let result = await array.asyncMap { value in
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value * 2
        }
        XCTAssertEqual(result, [2, 4, 6, 8, 10])
    }

    func testAsyncMapWithThrowing() async {
        let array = [1, 2, 3, 4, 5]
        do {
            _ = try await array.asyncMap { value in
                if value == 3 {
                    throw TestError.mockError
                }
                return value * 2
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testConcurrentMap() async throws {
        let array = [1, 2, 3, 4, 5]
        let result = try await array.concurrentMap { value in
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value * 2
        }
        XCTAssertEqual(result.sorted(), [2, 4, 6, 8, 10])
    }

    func testConcurrentMapWithThrowing() async {
        let array = [1, 2, 3, 4, 5]
        do {
            _ = try await array.concurrentMap { value in
                if value == 3 {
                    throw TestError.mockError
                }
                return value * 2
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Advanced Array Tests

    func testAsyncMapWithEmptyArray() async {
        let emptyArray: [Int] = []
        let result = await emptyArray.asyncMap { value in
            value * 2
        }
        XCTAssertEqual(result, [])
    }

    func testConcurrentMapWithEmptyArray() async throws {
        let emptyArray: [Int] = []
        let result = try await emptyArray.concurrentMap { value in
            value * 2
        }
        XCTAssertEqual(result, [])
    }

    func testAsyncMapPreservesOrder() async {
        let array = [1, 2, 3, 4, 5]
        let result = await array.asyncMap { value in
            // Simulate varying processing times
            try? await Task.sleep(nanoseconds: UInt64((6 - value) * 1_000_000)) // Inverse time
            return value
        }
        XCTAssertEqual(result, [1, 2, 3, 4, 5])
    }

    func testConcurrentMapWithLargeArray() async throws {
        let largeArray = Array(1 ... 100)
        let result = try await largeArray.concurrentMap { value in
            value * value
        }
        let expected = largeArray.map { $0 * $0 }
        XCTAssertEqual(result.sorted(), expected)
    }

    // MARK: - Helper Types

    enum TestError: Error {
        case mockError
    }
}
