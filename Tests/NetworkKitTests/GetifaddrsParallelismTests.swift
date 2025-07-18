import Darwin
@testable import NetworkKit
import XCTest

final class GetifaddrsParallelismTests: XCTestCase {
    func testGetifaddrsParallelism() async throws {
        print("\n=== Testing getifaddrs() Parallelism ===")

        // 测试单次 getifaddrs 调用的时间
        func timeGetifaddrs() -> TimeInterval {
            let start = CFAbsoluteTimeGetCurrent()

            var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
            if getifaddrs(&ifaddrsPtr) == 0 {
                // 简单遍历一下，模拟真实使用
                var ifaddrPtr = ifaddrsPtr
                var count = 0
                while ifaddrPtr != nil {
                    count += 1
                    ifaddrPtr = ifaddrPtr!.pointee.ifa_next
                }
                freeifaddrs(ifaddrsPtr)
                print("Found \(count) interface entries")
            }

            let end = CFAbsoluteTimeGetCurrent()
            return end - start
        }

        // 1. 测量单次调用时间
        print("\n--- Single getifaddrs() calls ---")
        var singleCallTimes: [TimeInterval] = []
        for i in 0 ..< 5 {
            let time = timeGetifaddrs()
            singleCallTimes.append(time)
            print("Call \(i + 1): \(String(format: "%.6f", time))s")
        }

        let avgSingleTime = singleCallTimes.reduce(0, +) / Double(singleCallTimes.count)
        print("Average single call time: \(String(format: "%.6f", avgSingleTime))s")

        // 2. 测量并发调用时间
        print("\n--- Concurrent getifaddrs() calls ---")
        let concurrentCount = 10

        var concurrentTimes: [TimeInterval] = []
        for round in 0 ..< 3 {
            let start = CFAbsoluteTimeGetCurrent()

            // 使用 TaskGroup 同时发起多个 getifaddrs 调用
            let results = try await withThrowingTaskGroup(of: TimeInterval.self) { group in
                var taskResults: [TimeInterval] = []

                for i in 0 ..< concurrentCount {
                    group.addTask {
                        timeGetifaddrs()
                    }
                }

                for try await result in group {
                    taskResults.append(result)
                }

                return taskResults
            }

            let end = CFAbsoluteTimeGetCurrent()
            let totalConcurrentTime = end - start
            concurrentTimes.append(totalConcurrentTime)

            print("Round \(round + 1):")
            print("  Total time for \(concurrentCount) concurrent calls: \(String(format: "%.6f", totalConcurrentTime))s")
            print("  Individual call times: \(results.map { String(format: "%.6f", $0) }.joined(separator: ", "))")
            print("  Average individual time: \(String(format: "%.6f", results.reduce(0, +) / Double(results.count)))s")
        }

        let avgConcurrentTime = concurrentTimes.reduce(0, +) / Double(concurrentTimes.count)
        print("\nAverage concurrent execution time: \(String(format: "%.6f", avgConcurrentTime))s")

        // 3. 分析结果
        print("\n--- Analysis ---")
        print("Single call average: \(String(format: "%.6f", avgSingleTime))s")
        print("Concurrent calls average: \(String(format: "%.6f", avgConcurrentTime))s")

        let theoreticalParallelTime = avgSingleTime // 如果完全并行，时间应该接近单次调用
        let theoreticalSerialTime = avgSingleTime * Double(concurrentCount) // 如果完全串行

        print("Theoretical parallel time (perfect): \(String(format: "%.6f", theoreticalParallelTime))s")
        print("Theoretical serial time (completely serial): \(String(format: "%.6f", theoreticalSerialTime))s")

        let parallelismRatio = (theoreticalSerialTime - avgConcurrentTime) / (theoreticalSerialTime - theoreticalParallelTime)
        print("Parallelism ratio: \(String(format: "%.2f", parallelismRatio)) (0=serial, 1=parallel)")

        let speedup = theoreticalSerialTime / avgConcurrentTime
        print("Speedup: \(String(format: "%.2f", speedup))x")

        if parallelismRatio < 0.3 {
            print("✅ Conclusion: getifaddrs() appears to be mostly SERIAL")
        } else if parallelismRatio > 0.7 {
            print("❌ Conclusion: getifaddrs() appears to be mostly PARALLEL")
        } else {
            print("⚠️  Conclusion: getifaddrs() has limited parallelism")
        }

        // 4. 验证系统资源竞争
        print("\n--- System Resource Analysis ---")
        print("Number of CPU cores: \(ProcessInfo.processInfo.processorCount)")

        // 如果是资源竞争导致的，应该能看到单个调用在并发环境下变慢
        let concurrentSingleCallTimes = try await withThrowingTaskGroup(of: TimeInterval.self) { group in
            var results: [TimeInterval] = []
            for _ in 0 ..< 5 {
                group.addTask {
                    timeGetifaddrs()
                }
            }
            for try await result in group {
                results.append(result)
            }
            return results
        }

        let avgConcurrentSingleTime = concurrentSingleCallTimes.reduce(0, +) / Double(concurrentSingleCallTimes.count)
        print("Average single call time under concurrency: \(String(format: "%.6f", avgConcurrentSingleTime))s")

        let slowdownRatio = avgConcurrentSingleTime / avgSingleTime
        print("Slowdown ratio under concurrency: \(String(format: "%.2f", slowdownRatio))x")

        if slowdownRatio > 1.5 {
            print("✅ Evidence of resource contention (supports serial hypothesis)")
        } else {
            print("⚠️  No significant resource contention detected")
        }
    }
}
