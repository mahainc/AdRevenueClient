import Foundation

extension AdRevenueClient {
    public struct Event: Sendable, Equatable, Codable {
        public let amount: Double
        public let currency: String
        public let adUnitId: String
        public let format: AdFormat
        public let source: Source
        public let receivedAt: Date
        /// The gate/feature that requested this ad (e.g. "highlights", "news"),
        /// so a subscriber can break revenue down by feature. Empty when the
        /// load site didn't supply one — the ad-unit id alone is ambiguous
        /// because several features can share a unit.
        public let featureId: String
        /// The mediation network that actually filled this impression, named the
        /// way the ad SDK names it — "AppLovin", "Meta Audience Network", "Google
        /// AdMob Network". Distinct from ``source``, which says which SDK *told*
        /// us about the impression; a single `googleMobileAds` source fills from
        /// a dozen different networks and revenue reporting needs to tell them
        /// apart. Empty when the SDK reports no loaded network.
        public let network: String
        /// The gate slot that requested this ad, when the caller tracks slots
        /// (several slots can share one feature and one ad unit). Empty when the
        /// caller has no slot concept.
        public let slotRef: String

        public init(
            amount: Double,
            currency: String,
            adUnitId: String,
            format: AdFormat,
            source: Source,
            receivedAt: Date = .now,
            featureId: String = "",
            network: String = "",
            slotRef: String = ""
        ) {
            self.amount = amount
            self.currency = currency
            self.adUnitId = adUnitId
            self.format = format
            self.source = source
            self.receivedAt = receivedAt
            self.featureId = featureId
            self.network = network
            self.slotRef = slotRef
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
}

// MARK: - Backward-compatibility shim (delete once consumers migrate)

public typealias AdRevenueEvent = AdRevenueClient.Event
