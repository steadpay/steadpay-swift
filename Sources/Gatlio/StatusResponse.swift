import Foundation

public struct StatusResponse {
    public let status: GatlioStatus
    public let entitlements: Entitlements
    public let cardUpdateUrl: URL?

    // Context-aware copy fields (#041). Nil/false when there is no active failure.
    public let declineCategory: String?
    public let nextRetryAt: String?
    public let isFinalRetry: Bool
    public let lockoutReason: String?

    public init(
        status: GatlioStatus,
        entitlements: Entitlements,
        cardUpdateUrl: URL?,
        declineCategory: String? = nil,
        nextRetryAt: String? = nil,
        isFinalRetry: Bool = false,
        lockoutReason: String? = nil
    ) {
        self.status = status
        self.entitlements = entitlements
        self.cardUpdateUrl = cardUpdateUrl
        self.declineCategory = declineCategory
        self.nextRetryAt = nextRetryAt
        self.isFinalRetry = isFinalRetry
        self.lockoutReason = lockoutReason
    }

    /// Context signals for `warningCopy` / `lockoutCopy`.
    public var enforcementContext: EnforcementContext {
        EnforcementContext(
            declineCategory: declineCategory,
            nextRetryAt: nextRetryAt,
            isFinalRetry: isFinalRetry,
            lockoutReason: lockoutReason
        )
    }
}

struct APIResponse: Decodable {
    let status: String
    let entitlements: APIEntitlements
    let card_update_url: String?
    let decline_category: String?
    let next_retry_at: String?
    let is_final_retry: Bool?
    let lockout_reason: String?

    struct APIEntitlements: Decodable {
        let powered_by_watermark: Bool
        let custom_domain: Bool
        let downstream_webhooks: Bool
    }
}
