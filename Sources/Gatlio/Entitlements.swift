public struct Entitlements: Equatable {
    public let poweredByWatermark: Bool
    public let customDomain: Bool
    public let downstreamWebhooks: Bool

    public init(poweredByWatermark: Bool, customDomain: Bool, downstreamWebhooks: Bool) {
        self.poweredByWatermark = poweredByWatermark
        self.customDomain = customDomain
        self.downstreamWebhooks = downstreamWebhooks
    }
}
