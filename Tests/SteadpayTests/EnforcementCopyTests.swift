import XCTest
@testable import Steadpay

final class EnforcementCopyTests: XCTestCase {
    let iso = "2026-06-20T12:00:00Z"
    let d = "June 20, 2026"

    func ctx(
        declineCategory: String? = nil,
        nextRetryAt: String? = nil,
        isFinalRetry: Bool = false,
        lockoutReason: String? = nil
    ) -> EnforcementContext {
        EnforcementContext(
            declineCategory: declineCategory,
            nextRetryAt: nextRetryAt,
            isFinalRetry: isFinalRetry,
            lockoutReason: lockoutReason
        )
    }

    func testResolveLocale() {
        XCTAssertEqual(resolveLocale("fr"), "fr")
        XCTAssertEqual(resolveLocale("es-ES"), "es")
        XCTAssertEqual(resolveLocale("de_DE"), "de")
        XCTAssertEqual(resolveLocale("jp"), "en")
        XCTAssertEqual(resolveLocale(nil), "en")
    }

    func testFormatRetryDate() {
        XCTAssertEqual(formatRetryDate(iso, locale: "en"), d)
        XCTAssertEqual(formatRetryDate(iso, locale: "de"), "20. Juni 2026")
        XCTAssertEqual(formatRetryDate(nil, locale: "en"), "")
        XCTAssertEqual(formatRetryDate("not-a-date", locale: "en"), "")
    }

    func testWarningCopyHasNoCta() {
        XCTAssertNil(warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso), locale: "en").cta)
    }

    func testWarningCopyVariantsEn() {
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso), locale: "en").message,
            "We'll retry on \(d). Please ensure sufficient funds are available.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso, isFinalRetry: true), locale: "en").message,
            "This is our final retry on \(d). Please add funds — your access will be restricted if it fails.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "bank_hold", nextRetryAt: iso), locale: "en").message,
            "We'll retry on \(d). You may want to contact your bank.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "processing_error", nextRetryAt: iso), locale: "en").message,
            "There was a temporary processing issue. We'll retry on \(d).")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "card_issue", nextRetryAt: iso), locale: "en").message,
            "We'll retry on \(d), but your saved card may need updating to go through.")
    }

    func testWarningCopyFallback() {
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: nil), locale: "en").message,
            "Your payment failed. We'll retry automatically — please keep your payment method up to date.")
    }

    func testWarningCopyLocalized() {
        XCTAssertTrue(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso, isFinalRetry: true), locale: "fr")
                .message.contains("Ceci est notre dernier essai"))
    }

    func testLockoutCopyEn() {
        let c1 = lockoutCopy(ctx(declineCategory: "card_issue", lockoutReason: "hard_decline"), locale: "en")
        XCTAssertEqual(c1.message, "Your payment method needs to be updated to restore access.")
        XCTAssertEqual(c1.cta, "Update card")

        XCTAssertEqual(
            lockoutCopy(ctx(declineCategory: "bank_hold", lockoutReason: "hard_decline"), locale: "en").message,
            "Your payment was declined by your bank. Please update your payment method or contact your bank.")
        XCTAssertEqual(
            lockoutCopy(ctx(declineCategory: "insufficient_funds", lockoutReason: "retry_exhausted"), locale: "en").message,
            "We were unable to process your payment after multiple attempts. Please add funds or update your payment method.")
        XCTAssertEqual(
            lockoutCopy(ctx(declineCategory: "bank_hold", lockoutReason: "retry_exhausted"), locale: "en").message,
            "We were unable to process your payment after multiple attempts. Please update your payment method or contact your bank.")
    }

    func testLockoutCtaLocalized() {
        XCTAssertEqual(
            lockoutCopy(ctx(declineCategory: "card_issue", lockoutReason: "hard_decline"), locale: "de").cta,
            "Karte aktualisieren")
    }
}
