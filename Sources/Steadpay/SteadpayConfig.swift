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
        precondition(apiBase.hasPrefix("https://"), "apiBase must start with https://")
        precondition(!tenantSlug.isEmpty, "tenantSlug must not be empty")
        precondition(!customerId.isEmpty, "customerId must not be empty")
        precondition(publishableKey.hasPrefix("pk_"), "publishableKey must start with pk_")
        self.apiBase = apiBase
        self.tenantSlug = tenantSlug
        self.customerId = customerId
        self.publishableKey = publishableKey
        self.pollInterval = pollInterval
    }
}
