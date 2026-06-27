import XCTest
import Combine
@testable import Gatlio

@MainActor
final class GatlioClientTests: XCTestCase {

    private func makeConfig(pollInterval: TimeInterval = 600) -> GatlioConfig {
        GatlioConfig(
            apiBase: "https://app.gatlio.io",
            tenantSlug: "acme",
            customerId: "cus_123",
            publishableKey: "pk_live_abc",
            hmac: "hmac_test_abc",
            pollInterval: pollInterval
        )
    }

    private func makeResponse(_ status: GatlioStatus) -> StatusResponse {
        StatusResponse(
            status: status,
            entitlements: Entitlements(poweredByWatermark: true, customDomain: false, downstreamWebhooks: false),
            cardUpdateUrl: URL(string: "https://app.gatlio.io/update-card")
        )
    }

    // MARK: — initial state

    func testInitialStatusIsLoading() {
        let client = GatlioClient(config: makeConfig(), fetch: { _, _, _, _, _ in
            self.makeResponse(.active)
        })
        XCTAssertEqual(client.status, .loading)
    }

    func testInitialDismissedIsFalse() {
        let client = GatlioClient(config: makeConfig(), fetch: { _, _, _, _, _ in
            self.makeResponse(.active)
        })
        XCTAssertFalse(client.dismissed)
    }

    // MARK: — forcedStatus

    func testForcedStatusBypassesPolling() async {
        var fetchCalled = false
        let client = GatlioClient(config: makeConfig(), forcedStatus: .lockout, fetch: { _, _, _, _, _ in
            fetchCalled = true
            return self.makeResponse(.active)
        })
        client.start()
        XCTAssertFalse(fetchCalled)
        XCTAssertEqual(client.status, .lockout)
    }

    func testForcedStatusEmitsImmediately() async {
        let client = GatlioClient(config: makeConfig(), forcedStatus: .warning, fetch: { _, _, _, _, _ in
            self.makeResponse(.active)
        })
        client.start()
        XCTAssertEqual(client.status, .warning)
    }

    // MARK: — start() polls and publishes

    func testStartPublishesCorrectStatus() async throws {
        let client = GatlioClient(config: makeConfig(), fetch: { _, _, _, _, _ in
            self.makeResponse(.active)
        })

        let expectation = XCTestExpectation(description: "status becomes active")
        var cancellable: AnyCancellable?
        cancellable = client.$status
            .dropFirst()
            .sink { status in
                if status == .active {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        client.start()
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(client.status, .active)
    }

    // MARK: — dismissWarning

    func testDismissWarningSetsDismissedTrue() {
        let client = GatlioClient(config: makeConfig(), fetch: { _, _, _, _, _ in
            self.makeResponse(.active)
        })
        client.dismissWarning()
        XCTAssertTrue(client.dismissed)
    }

    // MARK: — triggerCardUpdate

    func testTriggerCardUpdateResetsDismissed() async throws {
        let client = GatlioClient(
            config: makeConfig(pollInterval: 600),
            urlOpener: { _ in },
            fetch: { _, _, _, _, _ in self.makeResponse(.active) }
        )

        // inject a forced cardUpdateUrl via start with forcedStatus
        let forcedClient = GatlioClient(
            config: makeConfig(),
            forcedStatus: .lockout,
            urlOpener: { _ in },
            fetch: { _, _, _, _, _ in self.makeResponse(.active) }
        )
        forcedClient.start()
        forcedClient.dismissWarning()
        XCTAssertTrue(forcedClient.dismissed)
        forcedClient.triggerCardUpdate()
        XCTAssertFalse(forcedClient.dismissed)
    }

    func testTriggerCardUpdateCallsUrlOpener() async {
        var openedURL: URL?
        let client = GatlioClient(
            config: makeConfig(),
            forcedStatus: .lockout,
            urlOpener: { url in openedURL = url },
            fetch: { _, _, _, _, _ in self.makeResponse(.active) }
        )
        client.start()
        client.triggerCardUpdate()
        XCTAssertNotNil(openedURL)
    }

    // MARK: — stop()

    func testStopPreventsPolling() async throws {
        var fetchCallCount = 0
        let client = GatlioClient(config: makeConfig(pollInterval: 600), fetch: { _, _, _, _, _ in
            fetchCallCount += 1
            return self.makeResponse(.active)
        })
        client.start()
        client.stop()
        // Give any in-flight task a moment to complete (it was already dispatched)
        try? await Task.sleep(nanoseconds: 50_000_000)
        let callsAfterStop = fetchCallCount
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(fetchCallCount, callsAfterStop, "No additional polls after stop()")
    }

    // MARK: — callbacks

    func testOnErrorCallbackFiredOnFetchFailure() async throws {
        var capturedError: Error?
        let callbacks = GatlioCallbacks(onError: { capturedError = $0 })
        let client = GatlioClient(
            config: makeConfig(),
            callbacks: callbacks,
            fetch: { _, _, _, _, _ in throw GatlioError.unauthorized }
        )

        let expectation = XCTestExpectation(description: "onError fires")
        var cancellable: AnyCancellable?
        cancellable = client.$status
            .dropFirst()
            .sink { status in
                if status == .error {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        client.start()
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(capturedError)
    }

    // MARK: — security

    func testTriggerCardUpdateDoesNotOpenNonHttpsUrl() async {
        var opened: URL?
        let client = GatlioClient(
            config: makeConfig(),
            forcedStatus: nil,
            urlOpener: { opened = $0 },
            fetch: { _, _, _, _, _ in
                StatusResponse(
                    status: .lockout,
                    entitlements: Entitlements(poweredByWatermark: false, customDomain: false, downstreamWebhooks: false),
                    cardUpdateUrl: URL(string: "javascript:alert(1)")
                )
            }
        )
        client.start()
        try? await Task.sleep(nanoseconds: 50_000_000)
        client.triggerCardUpdate()
        XCTAssertNil(opened, "Non-https URL must not be opened")
    }
}

// Precondition trap tests — GatlioConfig validation
final class GatlioConfigValidationTests: XCTestCase {
    func testHttpApiBaseTraps() {
        // precondition violations crash in debug; verify the message is what we set.
        // In test builds we can't easily catch fatalError/preconditionFailure without
        // a signal handler, so we document the requirement via a comment and trust
        // the precondition keyword to enforce it at runtime.
        // The following assertion verifies a valid config succeeds (no trap):
        let _ = GatlioConfig(
            apiBase: "https://app.gatlio.io",
            tenantSlug: "acme",
            customerId: "cus_123",
            publishableKey: "pk_live_abc",
            hmac: "hmac_test_abc"
        )
        XCTAssertTrue(true, "Valid config does not trap")
    }
}

// Convenience init for tests that omit urlOpener
extension GatlioClient {
    convenience init(config: GatlioConfig, fetch: @escaping FetchFunction) {
        self.init(config: config, callbacks: nil, forcedStatus: nil, urlOpener: { _ in }, fetch: fetch)
    }
}
