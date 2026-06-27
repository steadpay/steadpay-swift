import Foundation

private let failOpenResponse = StatusResponse(
    status: .active,
    entitlements: Entitlements(poweredByWatermark: false, customDomain: false, downstreamWebhooks: false),
    cardUpdateUrl: nil
)

public func fetchSubscriberStatus(
    baseURL: String,
    tenantSlug: String,
    customerId: String,
    publishableKey: String,
    hmac: String,
    session: URLSession = .shared
) async throws -> StatusResponse {
    let encodedSlug = tenantSlug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tenantSlug
    let encodedCustomer = customerId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? customerId
    let encodedHmac = hmac.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hmac

    guard let url = URL(string: "\(baseURL)/api/subscriber-status/\(encodedSlug)?stripe_customer_id=\(encodedCustomer)&hmac=\(encodedHmac)") else {
        throw GatlioError.invalidURL
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 10
    request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
        throw GatlioError.unexpectedStatus(0)
    }

    if http.statusCode == 402 { return failOpenResponse }
    if http.statusCode == 401 { throw GatlioError.unauthorized }
    if http.statusCode == 404 { throw GatlioError.tenantNotFound }
    guard http.statusCode == 200 else {
        throw GatlioError.unexpectedStatus(http.statusCode)
    }

    let json = try JSONDecoder().decode(APIResponse.self, from: data)
    return StatusResponse(
        status: GatlioStatus(rawValue: json.status) ?? .error,
        entitlements: Entitlements(
            poweredByWatermark: json.entitlements.powered_by_watermark,
            customDomain: json.entitlements.custom_domain,
            downstreamWebhooks: json.entitlements.downstream_webhooks
        ),
        cardUpdateUrl: json.card_update_url.flatMap { URL(string: $0) },
        declineCategory: json.decline_category,
        nextRetryAt: json.next_retry_at,
        isFinalRetry: json.is_final_retry ?? false,
        lockoutReason: json.lockout_reason
    )
}
