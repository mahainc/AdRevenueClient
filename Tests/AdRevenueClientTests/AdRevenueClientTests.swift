import Foundation
import Testing
@testable import AdRevenueClient
@testable import AdRevenueClientLive

@Suite("AdRevenueClient")
struct AdRevenueClientTests {

    @Test("publish() fans out to every active events() subscriber")
    func multicastFanOut() async throws {
        let client = AdRevenueClient.liveValue

        async let firstCollect: [AdRevenueEvent] = collect(client.events(), count: 2)
        async let secondCollect: [AdRevenueEvent] = collect(client.events(), count: 2)

        // Give both subscribers time to register.
        try await Task.sleep(nanoseconds: 20_000_000)

        client.publish(.fixture(amount: 0.01))
        client.publish(.fixture(amount: 0.02))

        let (first, second) = try await (firstCollect, secondCollect)
        #expect(first.map(\.amount) == [0.01, 0.02])
        #expect(second.map(\.amount) == [0.01, 0.02])
    }

    @Test("events() stream terminates when subscriber task is cancelled")
    func terminationCleansUp() async throws {
        let client = AdRevenueClient.liveValue

        let task = Task { () -> Int in
            var count = 0
            for await _ in client.events() { count += 1 }
            return count
        }

        try await Task.sleep(nanoseconds: 20_000_000)
        client.publish(.fixture(amount: 0.05))
        try await Task.sleep(nanoseconds: 20_000_000)

        task.cancel()
        let received = await task.value
        #expect(received >= 1)

        // After cancel, a fresh subscriber still receives future events.
        async let followup: [AdRevenueEvent] = collect(client.events(), count: 1)
        try await Task.sleep(nanoseconds: 20_000_000)
        client.publish(.fixture(amount: 0.07))
        let events = try await followup
        #expect(events.first?.amount == 0.07)
    }

    @Test("noop mock swallows publish and yields nothing")
    func noopMock() async {
        let client = AdRevenueClient.noop
        client.publish(.fixture(amount: 0.10))
        var events: [AdRevenueEvent] = []
        for await event in client.events() { events.append(event) }
        #expect(events.isEmpty)
    }

    @Test("AdRevenueEvent round-trips through JSON")
    func codableRoundTrip() throws {
        let original = AdRevenueEvent.fixture(
            amount: 0.123,
            currency: "USD",
            adUnitId: "ca-app-pub-1234/5678",
            format: .rewarded,
            source: .googleMobileAds
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdRevenueEvent.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Helpers

    private func collect<S: AsyncSequence>(
        _ stream: S,
        count: Int
    ) async throws -> [S.Element] where S.Element: Sendable, S: Sendable {
        var out: [S.Element] = []
        for try await element in stream {
            out.append(element)
            if out.count >= count { break }
        }
        return out
    }
}

extension AdRevenueEvent {
    static func fixture(
        amount: Double = 0.01,
        currency: String = "USD",
        adUnitId: String = "ca-app-pub-0000000000000000/0000000000",
        format: AdFormat = .interstitial,
        source: Source = .googleMobileAds,
        receivedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> AdRevenueEvent {
        AdRevenueEvent(
            amount: amount,
            currency: currency,
            adUnitId: adUnitId,
            format: format,
            source: source,
            receivedAt: receivedAt
        )
    }
}
