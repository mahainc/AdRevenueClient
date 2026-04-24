import AdRevenueClient
import Foundation

/// Actor-backed multicast: each `events()` call registers a fresh continuation,
/// every `publish` fan-outs to all active continuations, and `onTermination`
/// auto-unregisters when the subscriber's stream task is cancelled. Mirrors the
/// same pattern `RemoteConfigActor` uses for `adConfigUpdates()`.
actor AdRevenueActor {
    private var continuations: [UUID: AsyncStream<AdRevenueClient.Event>.Continuation] = [:]

    init() {}

    func publish(_ event: AdRevenueClient.Event) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    nonisolated func events() -> AsyncStream<AdRevenueClient.Event> {
        AsyncStream { continuation in
            let id = UUID()
            Task { await self.register(id: id, continuation: continuation) }
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.unregister(id: id) }
            }
        }
    }

    private func register(
        id: UUID,
        continuation: AsyncStream<AdRevenueClient.Event>.Continuation
    ) {
        continuations[id] = continuation
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
