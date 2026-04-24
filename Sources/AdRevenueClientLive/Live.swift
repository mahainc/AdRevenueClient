import AdRevenueClient
import Dependencies

extension AdRevenueClient: DependencyKey {
    public static var liveValue: Self {
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
