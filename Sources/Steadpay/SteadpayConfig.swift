import Foundation

public struct SteadpayConfig {
    public let apiBase: String
    public let tenantSlug: String
    public let customerId: String
    public let publishableKey: String
    public let pollInterval: TimeInterval

    public init(
        apiBase: String,
        tenantSlug: String,
        customerId: String,
        publishableKey: String,
        pollInterval: TimeInterval = 600
    ) {
        self.apiBase = apiBase
        self.tenantSlug = tenantSlug
        self.customerId = customerId
        self.publishableKey = publishableKey
        self.pollInterval = pollInterval
    }
}
