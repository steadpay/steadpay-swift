import XCTest
@testable import Gatlio

final class EnforcementCopyTests: XCTestCase {
    // Use the real wire format: JS Date.toISOString() always emits fractional seconds.
    let iso = "2026-06-20T12:00:00.000Z"
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

    func testFormatRetryDatePinnsUTC() {
        // T01:00:00.000Z is still June 20 UTC but June 19 in any UTC− zone.
        XCTAssertEqual(formatRetryDate("2026-06-20T01:00:00.000Z", locale: "en"), "June 20, 2026")
    }

    func testWarningCopyHasNoCta() {
        XCTAssertNil(warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso), locale: "en").cta)
    }

    func testWarningCopyVariantsEn() {
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso), locale: "en").message,
            "Your payment failed. We'll retry on \(d) — please ensure funds are available.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso, isFinalRetry: true), locale: "en").message,
            "Your payment failed. Final retry on \(d) — add funds or your access will be restricted.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "bank_hold", nextRetryAt: iso), locale: "en").message,
            "Your payment was held by your bank. We'll retry on \(d) — you may want to contact them.")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "processing_error", nextRetryAt: iso), locale: "en").message,
            "Your payment failed due to a temporary issue. We'll retry on \(d).")
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: "card_issue", nextRetryAt: iso), locale: "en").message,
            "Your payment failed. We'll retry on \(d), but your saved card may need updating.")
    }

    func testWarningCopyFallback() {
        XCTAssertEqual(
            warningCopy(ctx(declineCategory: nil), locale: "en").message,
            "Your payment failed. We'll retry automatically — please keep your payment method up to date.")
    }

    func testWarningCopyLocalized() {
        XCTAssertTrue(
            warningCopy(ctx(declineCategory: "insufficient_funds", nextRetryAt: iso, isFinalRetry: true), locale: "fr")
                .message.contains("Dernier essai"))
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
