import Foundation

public struct AdRevenueEvent: Sendable, Equatable, Codable {
    public let amount: Double
    public let currency: String
    public let adUnitId: String
    public let format: AdFormat
    public let source: Source
    public let receivedAt: Date

    public init(
        amount: Double,
        currency: String,
        adUnitId: String,
        format: AdFormat,
        source: Source,
        receivedAt: Date = .now
    ) {
        self.amount = amount
        self.currency = currency
        self.adUnitId = adUnitId
        self.format = format
        self.source = source
        self.receivedAt = receivedAt
    }

    public enum AdFormat: String, Sendable, Equatable, Codable {
        case appOpen, interstitial, rewarded, banner, native
    }

    /// Which SDK produced the event. Useful for dedup + debug attribution when
    /// the same impression could theoretically be observed on two paths.
    public enum Source: String, Sendable, Equatable, Codable {
        case adsSwift, googleMobileAds
    }
}
