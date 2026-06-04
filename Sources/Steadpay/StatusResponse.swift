import Foundation

public struct StatusResponse {
    public let status: SteadpayStatus
    public let entitlements: Entitlements
    public let cardUpdateUrl: URL?

    public init(status: SteadpayStatus, entitlements: Entitlements, cardUpdateUrl: URL?) {
        self.status = status
        self.entitlements = entitlements
        self.cardUpdateUrl = cardUpdateUrl
    }
}

struct APIResponse: Decodable {
    let status: String
    let entitlements: APIEntitlements
    let card_update_url: String?

    struct APIEntitlements: Decodable {
        let powered_by_watermark: Bool
        let custom_domain: Bool
        let downstream_webhooks: Bool
    }
}
