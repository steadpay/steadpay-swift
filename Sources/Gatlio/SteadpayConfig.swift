import Foundation

public struct GatlioConfig {
    public let apiBase: String
    public let tenantSlug: String
    public let customerId: String
    public let publishableKey: String
    public let hmac: String
    public let pollInterval: TimeInterval
    /// Override the language for enforcement copy. Defaults to the device locale.
    public let locale: String?

    public init(
        apiBase: String,
        tenantSlug: String,
        customerId: String,
        publishableKey: String,
        hmac: String,
        pollInterval: TimeInterval = 600,
        locale: String? = nil
    ) {
        precondition(apiBase.hasPrefix("https://"), "apiBase must start with https://")
        precondition(!tenantSlug.isEmpty, "tenantSlug must not be empty")
        precondition(!customerId.isEmpty, "customerId must not be empty")
        precondition(publishableKey.hasPrefix("pk_"), "publishableKey must start with pk_")
        precondition(!hmac.isEmpty, "hmac must not be empty")
        self.apiBase = apiBase
        self.tenantSlug = tenantSlug
        self.customerId = customerId
        self.publishableKey = publishableKey
        self.hmac = hmac
        self.pollInterval = pollInterval
        self.locale = locale
    }
}
