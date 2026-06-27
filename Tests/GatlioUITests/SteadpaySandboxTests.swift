import XCTest
@testable import GatlioUI
import Gatlio

final class GatlioSandboxTests: XCTestCase {

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

    func testOnRecoveredNeverFires_onActiveFiresInstead() {
        let model = SandboxViewModel()
        var activeFired = false
        // Sandbox always passes isRecoveryPath=false, so lockout→active fires onActive not onRecovered
        model.onActive = { activeFired = true }
        model.changeStatus(.lockout)
        model.changeStatus(.active)
        XCTAssertTrue(activeFired)
        // SandboxViewModel intentionally exposes no onRecovered property
    }

    func testErrorPillIsNoOpWhenAlreadyInErrorState() {
        let model = SandboxViewModel()
        var errorCount = 0
        model.onError = { _ in errorCount += 1 }
        model.changeStatus(.error)
        model.changeStatus(.error)
        model.changeStatus(.error)
        XCTAssertEqual(errorCount, 1)
        XCTAssertEqual(model.log.filter { $0.contains("onError") }.count, 1)
    }

    func testDismissWarningHidesBanner() {
        let model = SandboxViewModel()
        model.changeStatus(.warning)
        XCTAssertFalse(model.isDismissed)
        model.dismissWarning()
        XCTAssertTrue(model.isDismissed)
    }

    func testDismissedResetOnStatusChange() {
        let model = SandboxViewModel()
        model.changeStatus(.warning)
        model.dismissWarning()
        XCTAssertTrue(model.isDismissed)
        model.changeStatus(.active)
        XCTAssertFalse(model.isDismissed)
    }

    // MARK: - Note string

    func testOnRecoveredNoteText() {
        XCTAssertEqual(
            sandboxRecoveredNote,
            "onRecovered requires a real card update — test against a live Gatlio environment."
        )
    }
}
