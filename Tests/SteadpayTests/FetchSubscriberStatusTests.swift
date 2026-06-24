import XCTest
@testable import Steadpay

final class FetchSubscriberStatusTests: XCTestCase {
    let BASE_URL = "https://app.steadpay.io"
    let TENANT = "acme"
    let CUSTOMER = "cus_123"
    let KEY = "pk_live_abc"
    let HMAC = "hmac_test_abc"

    private func mockResponse(status: Int, body: [String: Any]) throws -> (URLRequest) throws -> (HTTPURLResponse, Data) {
        return { request in
            let data = try JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }

    func testReturnsActiveResponseOn200() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 200, body: [
            "status": "active",
            "entitlements": [
                "powered_by_watermark": true,
                "custom_domain": false,
                "downstream_webhooks": false
            ],
            "card_update_url": "https://app.steadpay.io/update-card"
        ])

        let result = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertEqual(result.status, .active)
        XCTAssertEqual(result.entitlements.poweredByWatermark, true)
        XCTAssertEqual(result.cardUpdateUrl, URL(string: "https://app.steadpay.io/update-card"))
    }

    func testParsesContextAwareCopyFields() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 200, body: [
            "status": "warning",
            "entitlements": [
                "powered_by_watermark": true,
                "custom_domain": false,
                "downstream_webhooks": false
            ],
            "card_update_url": "https://app.steadpay.io/update-card",
            "decline_category": "insufficient_funds",
            "next_retry_at": "2026-06-20T12:00:00Z",
            "is_final_retry": true,
            "lockout_reason": NSNull()
        ])

        let result = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertEqual(result.declineCategory, "insufficient_funds")
        XCTAssertEqual(result.nextRetryAt, "2026-06-20T12:00:00Z")
        XCTAssertTrue(result.isFinalRetry)
        XCTAssertNil(result.lockoutReason)
    }

    func testContextFieldsDefaultWhenAbsent() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 200, body: [
            "status": "active",
            "entitlements": [
                "powered_by_watermark": true,
                "custom_domain": false,
                "downstream_webhooks": false
            ],
            "card_update_url": "https://app.steadpay.io/update-card"
        ])

        let result = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertNil(result.declineCategory)
        XCTAssertNil(result.nextRetryAt)
        XCTAssertFalse(result.isFinalRetry)
        XCTAssertNil(result.lockoutReason)
    }

    func testReturnsFailOpenActiveOn402() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 402, body: [:])

        let result = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertEqual(result.status, .active)
        XCTAssertEqual(result.entitlements.poweredByWatermark, false)
        XCTAssertNil(result.cardUpdateUrl)
    }

    func testThrowsUnauthorizedOn401() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 401, body: [:])

        do {
            _ = try await fetchSubscriberStatus(
                baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
                publishableKey: KEY, hmac: HMAC, session: .mock
            )
            XCTFail("Expected throw")
        } catch SteadpayError.unauthorized {
            // pass
        }
    }

    func testThrowsTenantNotFoundOn404() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 404, body: [:])

        do {
            _ = try await fetchSubscriberStatus(
                baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
                publishableKey: KEY, hmac: HMAC, session: .mock
            )
            XCTFail("Expected throw")
        } catch SteadpayError.tenantNotFound {
            // pass
        }
    }

    func testThrowsUnexpectedStatusOn500() async throws {
        MockURLProtocol.requestHandler = try mockResponse(status: 500, body: [:])

        do {
            _ = try await fetchSubscriberStatus(
                baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
                publishableKey: KEY, hmac: HMAC, session: .mock
            )
            XCTFail("Expected throw")
        } catch SteadpayError.unexpectedStatus(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func testPropagatesNetworkError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await fetchSubscriberStatus(
                baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
                publishableKey: KEY, hmac: HMAC, session: .mock
            )
            XCTFail("Expected throw")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testSendsCorrectAuthorizationHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try self.mockResponse(status: 200, body: [
                "status": "active",
                "entitlements": ["powered_by_watermark": false, "custom_domain": false, "downstream_webhooks": false],
                "card_update_url": NSNull()
            ])(request)
        }

        _ = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer \(KEY)")
    }

    func testSendsCorrectEndpointPath() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return try self.mockResponse(status: 200, body: [
                "status": "active",
                "entitlements": ["powered_by_watermark": false, "custom_domain": false, "downstream_webhooks": false],
                "card_update_url": NSNull()
            ])(request)
        }

        _ = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertTrue(capturedURL?.path.contains("/api/subscriber-status/\(TENANT)") ?? false)
        XCTAssertTrue(capturedURL?.query?.contains("stripe_customer_id=\(CUSTOMER)") ?? false)
    }

    func testRequestTimeoutIsSet() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try self.mockResponse(status: 200, body: [
                "status": "active",
                "entitlements": ["powered_by_watermark": false, "custom_domain": false, "downstream_webhooks": false],
                "card_update_url": NSNull()
            ])(request)
        }

        _ = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertEqual(capturedRequest?.timeoutInterval, 10)
    }

    func testSendsHmacQueryParam() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return try self.mockResponse(status: 200, body: [
                "status": "active",
                "entitlements": ["powered_by_watermark": false, "custom_domain": false, "downstream_webhooks": false],
                "card_update_url": NSNull()
            ])(request)
        }

        _ = try await fetchSubscriberStatus(
            baseURL: BASE_URL, tenantSlug: TENANT, customerId: CUSTOMER,
            publishableKey: KEY, hmac: HMAC, session: .mock
        )

        XCTAssertTrue(capturedURL?.query?.contains("hmac=\(HMAC)") ?? false)
    }
}
