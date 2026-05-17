import Foundation

/// Helpers to run async work with explicit QoS.
enum QoSRunner {
    /// Awaitable runner that hops to the given QoS and priority, returning the result.
    private static func run<T>(
        qos: DispatchQoS.QoSClass,
        priority: TaskPriority,
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: qos).async {
                Task.detached(priority: priority) {
                    do {
                        let result = try await work()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Fire-and-forget runner for synchronous call sites (e.g. button actions).
    private static func fireAndForget(
        qos: DispatchQoS.QoSClass,
        priority: TaskPriority,
        _ work: @escaping @Sendable () async -> Void
    ) {
        DispatchQueue.global(qos: qos).async {
            Task.detached(priority: priority) {
                await work()
            }
        }
    }

    static func userInitiated<T>(
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await run(qos: .userInitiated, priority: .userInitiated, work)
    }

    static func utility<T>(
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await run(qos: .utility, priority: .utility, work)
    }

    static func fireAndForgetUserInitiated(
        _ work: @escaping @Sendable () async -> Void
    ) {
        fireAndForget(qos: .userInitiated, priority: .userInitiated, work)
    }

    static func fireAndForgetUtility(
        _ work: @escaping @Sendable () async -> Void
    ) {
        fireAndForget(qos: .utility, priority: .utility, work)
    }
}
