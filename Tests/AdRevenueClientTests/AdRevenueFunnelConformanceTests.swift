// The funnel conformance tests compile only when the `Funnel` trait is enabled —
// the trait is what puts FunnelClient in the dependency graph at all, so without
// it this file has no module to import. They live apart from
// `AdRevenueClientTests.swift` precisely so that file stays funnel-free and the
// test target still builds with the trait off. See Package.swift.
#if Funnel
import FunnelClient
import Testing

@testable import AdRevenueClient
@testable import AdRevenueClientLive

/// `AdRevenueEvent.fixture` is declared (internal) in `AdRevenueClientTests.swift`
/// and both files are the same test module, so it is reachable here unchanged —
/// nothing had to be duplicated or widened for the split.
@Suite("AdRevenueClient+Funnel")
struct AdRevenueFunnelConformanceTests {

    @Test("Funnel conformance maps event fields and passes the currency amount through unscaled")
    func funnelConformanceMapping() async throws {
        let (source, continuation) = AsyncStream<AdRevenueEvent>.makeStream()
        let client = AdRevenueClient(publish: { _ in }, events: { source })
        // The client itself satisfies the port, so a host needs no wrapper type. The
        // annotation picks the port's `events()` over the client's own same-named closure.
        let mapped: AsyncStream<FunnelClient.AdRevenue.Event> = client.events()

        continuation.yield(
            .fixture(
                amount: 0.0034,
                currency: "USD",
                adUnitId: "unit-1",
                format: .rewarded,
                source: .googleMobileAds,
                featureId: "highlights",
                network: "AppLovin",
                slotRef: "slot-7"
            )
        )
        continuation.finish()

        var events: [FunnelClient.AdRevenue.Event] = []
        for await event in mapped {
            events.append(event)
        }

        #expect(events.count == 1)
        #expect(events.first?.unitID == "unit-1")
        #expect(events.first?.featureID == "highlights")
        #expect(events.first?.slotRef == "slot-7")
        #expect(events.first?.adFormat == "rewarded")
        // The mediation network that filled the impression, NOT `source` — reporting
        // the SDK here would collapse every mediated network into one GA4 value.
        #expect(events.first?.adSource == "AppLovin")
        // `amount` is already in currency units (iOS `GADAdValue.value`), so it must not be rescaled.
        #expect(events.first?.value == 0.0034)
        #expect(events.first?.currency == "USD")
    }

    @Test("Funnel conformance names app-open ads the way the funnel guest does")
    func funnelConformanceAppOpenFormat() async {
        let (source, continuation) = AsyncStream<AdRevenueEvent>.makeStream()
        let client = AdRevenueClient(publish: { _ in }, events: { source })
        let mapped: AsyncStream<FunnelClient.AdRevenue.Event> = client.events()

        continuation.yield(.fixture(format: .appOpen))
        continuation.yield(.fixture(format: .native))
        continuation.finish()

        var formats: [String] = []
        for await event in mapped {
            formats.append(event.adFormat)
        }

        #expect(formats == ["resume", "native"])
    }
}
#endif
