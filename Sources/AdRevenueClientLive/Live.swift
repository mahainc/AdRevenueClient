import AdRevenueClient
import Dependencies

extension AdRevenueClient: DependencyKey {
    /// `static let`, not a computed `var`: this client is a pub/sub seam, so the publisher
    /// and every subscriber have to reach the **same** `AdRevenueActor`. A computed property
    /// mints a fresh actor with an empty subscriber list on each evaluation, which would
    /// leave paid impressions published into an instance nobody is listening to. Dependency
    /// caching happens to prevent that today; binding the instance here makes it structural.
    public static let liveValue: Self = makeLive()

    /// A client backed by its own relay.
    ///
    /// Exists for tests: `liveValue` is now process-wide by design, so two tests that both
    /// reach for it would publish into a shared subscriber list and see each other's events.
    static func makeLive() -> Self {
        let actor = AdRevenueActor()
        return AdRevenueClient(
            publish: { event in
                Task { await actor.publish(event) }
            },
            events: {
                actor.events()
            }
        )
    }
}
