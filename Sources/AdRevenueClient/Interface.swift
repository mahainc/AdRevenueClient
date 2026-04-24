import DependenciesMacros

/// Single publish/subscribe seam for paid ad-impression revenue events.
///
/// Publishers (GoogleMobileAds `paidEventHandler`, ads_swift `AdRevenueDelegate`)
/// call `publish(_:)`. Long-lived subscribers (e.g. an `AdRevenueSyncer` reducer)
/// iterate `events()` and fan out to Adjust / Analytics / etc.
///
/// Replaces the per-consumer fan-out that previously lived inside MobileAdsClient,
/// so the ad SDK bridge no longer imports AdjustClient or AnalyticClient.
@DependencyClient
public struct AdRevenueClient: Sendable {
    public var publish: @Sendable (_ event: AdRevenueEvent) -> Void
    public var events: @Sendable () -> AsyncStream<AdRevenueEvent> = { .finished }
}
