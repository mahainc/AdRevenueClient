import AdRevenueClient
import FunnelClient

/// Ad-revenue bridge from the standalone publisher stream into FunnelClient.
public final class AdRevenueFunnelProvider: FunnelClient.AdRevenue.Providing, @unchecked Sendable {
    private static let microsPerUnit = 1_000_000.0
    private let adRevenueClient: AdRevenueClient

    public init(adRevenueClient: AdRevenueClient) {
        self.adRevenueClient = adRevenueClient
    }

    public func events() -> AsyncStream<FunnelClient.AdRevenue.Event> {
        let (stream, continuation) = AsyncStream<FunnelClient.AdRevenue.Event>.makeStream()
        let task = Task {
            for await event in adRevenueClient.events() {
                continuation.yield(Self.funnelEvent(from: event))
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    /// `adSource` carries ``AdRevenueClient/Event/network`` — the mediation network
    /// that filled the impression — not ``AdRevenueClient/Event/source``, which only
    /// names the SDK that reported it. The funnel forwards this straight into the GA4
    /// `ad_impression` parameter of the same name, so reporting the SDK here would
    /// collapse every network in the mediation stack into one value.
    private static func funnelEvent(from event: AdRevenueClient.Event) -> FunnelClient.AdRevenue.Event {
        FunnelClient.AdRevenue.Event(
            unitID: event.adUnitId,
            featureID: event.featureId,
            slotRef: event.slotRef,
            adFormat: event.format.rawValue,
            adSource: event.network,
            value: event.amount / microsPerUnit,
            currency: event.currency
        )
    }
}
