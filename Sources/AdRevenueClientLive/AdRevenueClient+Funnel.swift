import AdRevenueClient
import FunnelClient

/// Ad-revenue bridge from the standalone publisher stream into FunnelClient.
///
/// The conformance sits on the client itself rather than on a wrapper type, so a host
/// reaches it through the dependency key it already has — `@Dependency(\.adRevenueClient)`
/// hands back something that already satisfies the port. The relay state lives in
/// `AdRevenueActor`, which the client's closures capture, so nothing needs to be stored here.
extension AdRevenueClient: FunnelClient.AdRevenue.Providing {
    private static let microsPerUnit = 1_000_000.0

    /// The port's `events()` and this client's own `events` closure differ only in element
    /// type; the explicit annotation below is what keeps the call unambiguous.
    public func events() -> AsyncStream<FunnelClient.AdRevenue.Event> {
        let source: AsyncStream<AdRevenueClient.Event> = events()
        let (stream, continuation) = AsyncStream<FunnelClient.AdRevenue.Event>.makeStream()
        let task = Task {
            for await event in source {
                continuation.yield(Self.funnelEvent(from: event))
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    /// `adSource` carries ``AdRevenueClient/Event/network`` — the mediation network that
    /// filled the impression — not ``AdRevenueClient/Event/source``, which only names the
    /// SDK that reported it. The funnel forwards this straight into the GA4 `ad_impression`
    /// parameter of the same name, so reporting the SDK here would collapse every network in
    /// the mediation stack into one value.
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
