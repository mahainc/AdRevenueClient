import Dependencies

extension DependencyValues {
    public var adRevenueClient: AdRevenueClient {
        get { self[AdRevenueClient.self] }
        set { self[AdRevenueClient.self] = newValue }
    }
}

extension AdRevenueClient: TestDependencyKey {
    public static var testValue: Self {
        Self()
    }

    public static var previewValue: Self {
        Self()
    }
}

extension AdRevenueClient {
    /// No-op publisher, empty stream. Useful for happy-path test stores that
    /// don't assert on the revenue pipeline.
    public static let noop: Self = .init(
        publish: { _ in },
        events: { .finished }
    )
}
