import XCTest
@testable import Steadpay

final class ComputeTransitionTests: XCTestCase {

    // MARK: — null → status (initial load)

    func testNullToLockoutFiresOnLockout() {
        XCTAssertEqual(computeTransition(lastStatus: nil, newStatus: .lockout, isRecoveryPath: false), .onLockout)
    }

    func testNullToWarningSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: nil, newStatus: .warning, isRecoveryPath: false))
    }

    func testNullToActiveSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: nil, newStatus: .active, isRecoveryPath: false))
    }

    // MARK: — transitions to lockout

    func testWarningToLockoutFiresOnLockout() {
        XCTAssertEqual(computeTransition(lastStatus: .warning, newStatus: .lockout, isRecoveryPath: false), .onLockout)
    }

    func testActiveToLockoutFiresOnLockout() {
        XCTAssertEqual(computeTransition(lastStatus: .active, newStatus: .lockout, isRecoveryPath: false), .onLockout)
    }

    // MARK: — transitions to warning

    func testActiveToWarningFiresOnWarning() {
        XCTAssertEqual(computeTransition(lastStatus: .active, newStatus: .warning, isRecoveryPath: false), .onWarning)
    }

    func testLockoutToWarningFiresOnWarning() {
        XCTAssertEqual(computeTransition(lastStatus: .lockout, newStatus: .warning, isRecoveryPath: false), .onWarning)
    }

    // MARK: — transitions to active

    func testLockoutToActiveFiresOnActive() {
        XCTAssertEqual(computeTransition(lastStatus: .lockout, newStatus: .active, isRecoveryPath: false), .onActive)
    }

    func testLockoutToActiveOnRecoveryPathFiresOnRecovered() {
        XCTAssertEqual(computeTransition(lastStatus: .lockout, newStatus: .active, isRecoveryPath: true), .onRecovered)
    }

    func testWarningToActiveFiresOnActive() {
        XCTAssertEqual(computeTransition(lastStatus: .warning, newStatus: .active, isRecoveryPath: false), .onActive)
    }

    func testWarningToActiveOnRecoveryPathFiresOnActive() {
        XCTAssertEqual(computeTransition(lastStatus: .warning, newStatus: .active, isRecoveryPath: true), .onActive)
    }

    // MARK: — same → same (no transition)

    func testActiveToActiveSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: .active, newStatus: .active, isRecoveryPath: false))
    }

    func testWarningToWarningSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: .warning, newStatus: .warning, isRecoveryPath: false))
    }

    func testLockoutToLockoutSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: .lockout, newStatus: .lockout, isRecoveryPath: false))
    }

    // MARK: — non-billing statuses as newStatus

    func testActiveToLoadingSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: .active, newStatus: .loading, isRecoveryPath: false))
    }

    func testActiveToErrorSuppressed() {
        XCTAssertNil(computeTransition(lastStatus: .active, newStatus: .error, isRecoveryPath: false))
    }
}
