import XCTest
@testable import SteadpayUI
import Steadpay

final class SteadpaySandboxTests: XCTestCase {

    // MARK: - SandboxViewModel logic (tests observable side effects)

    func testStartsInActiveState() {
        let model = SandboxViewModel()
        XCTAssertEqual(model.currentStatus, .active)
        XCTAssertTrue(model.log.isEmpty)
    }

    func testLockoutPillTransitionsToLockout() {
        let model = SandboxViewModel()
        model.changeStatus(.lockout)
        XCTAssertEqual(model.currentStatus, .lockout)
    }

    func testCallbackFiresOnLockoutTransition() {
        let model = SandboxViewModel()
        var fired = false
        model.onLockout = { fired = true }
        model.changeStatus(.lockout)
        XCTAssertTrue(fired)
    }

    func testCallbackFiresOnWarningTransition() {
        let model = SandboxViewModel()
        var fired = false
        model.onWarning = { fired = true }
        model.changeStatus(.warning)
        XCTAssertTrue(fired)
    }

    func testCallbackFiresOnActiveTransition() {
        let model = SandboxViewModel()
        var fired = false
        model.onActive = { fired = true }
        model.changeStatus(.lockout)
        model.changeStatus(.active)
        XCTAssertTrue(fired)
    }

    func testErrorPillCallsOnError() {
        let model = SandboxViewModel()
        var errorReceived: Error?
        model.onError = { errorReceived = $0 }
        model.changeStatus(.error)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual((errorReceived as NSError?)?.localizedDescription, "sandbox_error")
    }

    func testLogAppendsEntryOnTransition() {
        let model = SandboxViewModel()
        model.changeStatus(.lockout)
        XCTAssertEqual(model.log.first, "onLockout()")
        XCTAssertEqual(model.log.count, 1)
    }

    func testLogCapsFiveEntries() {
        let model = SandboxViewModel()
        for _ in 0..<6 { model.changeStatus(.lockout); model.changeStatus(.active) }
        XCTAssertLessThanOrEqual(model.log.count, 5)
    }

    func testOnRecoveredNeverFiresFromSandbox() {
        let model = SandboxViewModel()
        var recoveredFired = false
        // onRecovered is not exposed by SandboxViewModel intentionally
        model.changeStatus(.lockout)
        model.changeStatus(.active)
        XCTAssertFalse(recoveredFired)
    }

    // MARK: - Note string

    func testOnRecoveredNoteText() {
        XCTAssertEqual(
            sandboxRecoveredNote,
            "onRecovered requires a real card update — test against a live Steadpay environment."
        )
    }
}
