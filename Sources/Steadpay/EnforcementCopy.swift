import Foundation

// Context-aware enforcement copy (#041).
//
// Mirrors the web enforcement snippet's copy tables so the mobile experience is
// identical: decline-category-driven warning copy (no card-update CTA on soft
// declines) and lockout copy differentiated by lockout reason × decline category.

public struct EnforcementContext: Equatable, Sendable {
    public let declineCategory: String?
    public let nextRetryAt: String?
    public let isFinalRetry: Bool
    public let lockoutReason: String?

    public init(
        declineCategory: String? = nil,
        nextRetryAt: String? = nil,
        isFinalRetry: Bool = false,
        lockoutReason: String? = nil
    ) {
        self.declineCategory = declineCategory
        self.nextRetryAt = nextRetryAt
        self.isFinalRetry = isFinalRetry
        self.lockoutReason = lockoutReason
    }
}

public struct EnforcementCopy: Equatable, Sendable {
    public let message: String
    /// Card-update CTA label. Always nil in warning state (#041).
    public let cta: String?

    public init(message: String, cta: String?) {
        self.message = message
        self.cta = cta
    }
}

private let supportedLocales = ["en", "fr", "es", "de"]

/// Validates a raw locale string down to one of the supported language codes,
/// falling back to English.
public func resolveLocale(_ locale: String?) -> String {
    let loc = (locale ?? "en").lowercased()
    let code = String(loc.prefix(2))
    return supportedLocales.contains(code) ? code : "en"
}

/// Formats an ISO-8601 timestamp into a locale-appropriate long date. The UTC
/// calendar date is used so the rendered day is deterministic across devices.
public func formatRetryDate(_ iso: String?, locale: String) -> String {
    guard let iso, !iso.isEmpty else { return "" }
    // Backend serialises via JS Date.toISOString() which always emits fractional
    // seconds (.000Z). Try with fractional seconds first; fall back for any
    // bare-second literal that comes in from tests or other callers.
    let parserMs = ISO8601DateFormatter()
    parserMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let parserPlain = ISO8601DateFormatter()
    guard let date = parserMs.date(from: iso) ?? parserPlain.date(from: iso) else { return "" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: resolveLocale(locale))
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

private struct WarningVariant {
    let normal: String
    let last: String
}

private let warningTable: [String: [String: WarningVariant]] = [
    "en": [
        "insufficient_funds": WarningVariant(
            normal: "Your payment failed. We'll retry on {date} — please ensure funds are available.",
            last: "Your payment failed. Final retry on {date} — add funds or your access will be restricted."),
        "bank_hold": WarningVariant(
            normal: "Your payment was held by your bank. We'll retry on {date} — you may want to contact them.",
            last: "Your payment was held by your bank. Final retry on {date} — contact your bank or your access will be restricted."),
        "processing_error": WarningVariant(
            normal: "Your payment failed due to a temporary issue. We'll retry on {date}.",
            last: "Your payment failed. Final retry on {date} — your access will be restricted if it fails."),
        "card_issue": WarningVariant(
            normal: "Your payment failed. We'll retry on {date}, but your saved card may need updating.",
            last: "Your payment failed. Final retry on {date} — update your card or your access will be restricted."),
    ],
    "fr": [
        "insufficient_funds": WarningVariant(
            normal: "Votre paiement a échoué. Nous réessaierons le {date} — veuillez vous assurer que des fonds suffisants sont disponibles.",
            last: "Votre paiement a échoué. Dernier essai le {date} — ajoutez des fonds ou votre accès sera restreint."),
        "bank_hold": WarningVariant(
            normal: "Votre paiement a été bloqué par votre banque. Nous réessaierons le {date} — vous pouvez la contacter.",
            last: "Votre paiement a été bloqué par votre banque. Dernier essai le {date} — contactez votre banque ou votre accès sera restreint."),
        "processing_error": WarningVariant(
            normal: "Votre paiement a échoué en raison d'un problème temporaire. Nous réessaierons le {date}.",
            last: "Votre paiement a échoué. Dernier essai le {date} — votre accès sera restreint en cas d'échec."),
        "card_issue": WarningVariant(
            normal: "Votre paiement a échoué. Nous réessaierons le {date}, mais votre carte enregistrée devra peut-être être mise à jour.",
            last: "Votre paiement a échoué. Dernier essai le {date} — votre carte doit probablement être mise à jour ou votre accès sera restreint."),
    ],
    "es": [
        "insufficient_funds": WarningVariant(
            normal: "Tu pago falló. Volveremos a intentarlo el {date} — asegúrate de que haya fondos suficientes.",
            last: "Tu pago falló. Último intento el {date} — añade fondos o tu acceso se restringirá."),
        "bank_hold": WarningVariant(
            normal: "Tu banco retuvo el pago. Volveremos a intentarlo el {date} — quizás quieras contactarles.",
            last: "Tu banco retuvo el pago. Último intento el {date} — contacta con tu banco o tu acceso se restringirá."),
        "processing_error": WarningVariant(
            normal: "Tu pago falló por un problema temporal. Volveremos a intentarlo el {date}.",
            last: "Tu pago falló. Último intento el {date} — tu acceso se restringirá si falla."),
        "card_issue": WarningVariant(
            normal: "Tu pago falló. Volveremos a intentarlo el {date}, pero es posible que tu tarjeta guardada deba actualizarse.",
            last: "Tu pago falló. Último intento el {date} — actualiza tu tarjeta o tu acceso se restringirá."),
    ],
    "de": [
        "insufficient_funds": WarningVariant(
            normal: "Ihre Zahlung ist fehlgeschlagen. Wir versuchen es am {date} erneut — bitte stellen Sie sicher, dass ausreichend Guthaben verfügbar ist.",
            last: "Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — laden Sie Guthaben auf oder Ihr Zugang wird eingeschränkt."),
        "bank_hold": WarningVariant(
            normal: "Ihre Zahlung wurde von Ihrer Bank zurückgehalten. Wir versuchen es am {date} erneut — Sie können sich an Ihre Bank wenden.",
            last: "Ihre Zahlung wurde von Ihrer Bank zurückgehalten. Letzter Versuch am {date} — wenden Sie sich an Ihre Bank oder Ihr Zugang wird eingeschränkt."),
        "processing_error": WarningVariant(
            normal: "Ihre Zahlung ist aufgrund eines vorübergehenden Problems fehlgeschlagen. Wir versuchen es am {date} erneut.",
            last: "Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — andernfalls wird Ihr Zugang eingeschränkt."),
        "card_issue": WarningVariant(
            normal: "Ihre Zahlung ist fehlgeschlagen. Wir versuchen es am {date} erneut, aber Ihre gespeicherte Karte muss möglicherweise aktualisiert werden.",
            last: "Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — aktualisieren Sie Ihre Karte oder Ihr Zugang wird eingeschränkt."),
    ],
]

private let warningFallback: [String: String] = [
    "en": "Your payment failed. We'll retry automatically — please keep your payment method up to date.",
    "fr": "Votre paiement a échoué. Nous réessaierons automatiquement — veuillez garder votre moyen de paiement à jour.",
    "es": "Tu pago falló. Volveremos a intentarlo automáticamente — mantén tu método de pago actualizado.",
    "de": "Ihre Zahlung ist fehlgeschlagen. Wir versuchen es automatisch erneut — bitte halten Sie Ihre Zahlungsmethode aktuell.",
]

// Lockout copy: locale → reason → category (with a per-reason "_default").
private let lockoutTable: [String: [String: [String: String]]] = [
    "en": [
        "hard_decline": [
            "card_issue": "Your payment method needs to be updated to restore access.",
            "bank_hold": "Your payment was declined by your bank. Please update your payment method or contact your bank.",
            "_default": "Your payment method needs to be updated to restore access.",
        ],
        "retry_exhausted": [
            "insufficient_funds": "We were unable to process your payment after multiple attempts. Please add funds or update your payment method.",
            "_default": "We were unable to process your payment after multiple attempts. Please update your payment method or contact your bank.",
        ],
    ],
    "fr": [
        "hard_decline": [
            "card_issue": "Votre moyen de paiement doit être mis à jour pour rétablir l'accès.",
            "bank_hold": "Votre paiement a été refusé par votre banque. Veuillez mettre à jour votre moyen de paiement ou contacter votre banque.",
            "_default": "Votre moyen de paiement doit être mis à jour pour rétablir l'accès.",
        ],
        "retry_exhausted": [
            "insufficient_funds": "Nous n'avons pas pu traiter votre paiement après plusieurs tentatives. Veuillez ajouter des fonds ou mettre à jour votre moyen de paiement.",
            "_default": "Nous n'avons pas pu traiter votre paiement après plusieurs tentatives. Veuillez mettre à jour votre moyen de paiement ou contacter votre banque.",
        ],
    ],
    "es": [
        "hard_decline": [
            "card_issue": "Tu método de pago debe actualizarse para restaurar el acceso.",
            "bank_hold": "Tu banco rechazó el pago. Actualiza tu método de pago o contacta con tu banco.",
            "_default": "Tu método de pago debe actualizarse para restaurar el acceso.",
        ],
        "retry_exhausted": [
            "insufficient_funds": "No pudimos procesar tu pago después de varios intentos. Añade fondos o actualiza tu método de pago.",
            "_default": "No pudimos procesar tu pago después de varios intentos. Actualiza tu método de pago o contacta con tu banco.",
        ],
    ],
    "de": [
        "hard_decline": [
            "card_issue": "Ihre Zahlungsmethode muss aktualisiert werden, um den Zugang wiederherzustellen.",
            "bank_hold": "Ihre Zahlung wurde von Ihrer Bank abgelehnt. Bitte aktualisieren Sie Ihre Zahlungsmethode oder wenden Sie sich an Ihre Bank.",
            "_default": "Ihre Zahlungsmethode muss aktualisiert werden, um den Zugang wiederherzustellen.",
        ],
        "retry_exhausted": [
            "insufficient_funds": "Wir konnten Ihre Zahlung nach mehreren Versuchen nicht verarbeiten. Bitte laden Sie Guthaben auf oder aktualisieren Sie Ihre Zahlungsmethode.",
            "_default": "Wir konnten Ihre Zahlung nach mehreren Versuchen nicht verarbeiten. Bitte aktualisieren Sie Ihre Zahlungsmethode oder wenden Sie sich an Ihre Bank.",
        ],
    ],
]

private let ctaTable: [String: String] = [
    "en": "Update card",
    "fr": "Mettre à jour la carte",
    "es": "Actualizar tarjeta",
    "de": "Karte aktualisieren",
]

/// Decline-specific warning copy. Never carries a card-update CTA (#041).
public func warningCopy(_ ctx: EnforcementContext, locale: String) -> EnforcementCopy {
    let loc = resolveLocale(locale)
    let date = formatRetryDate(ctx.nextRetryAt, locale: loc)
    let variant = ctx.declineCategory.flatMap { warningTable[loc]?[$0] }
    let template: String
    if let variant {
        template = ctx.isFinalRetry ? variant.last : variant.normal
    } else {
        template = warningFallback[loc] ?? warningFallback["en"]!
    }
    return EnforcementCopy(message: template.replacingOccurrences(of: "{date}", with: date), cta: nil)
}

/// Lockout copy differentiated by lockout reason × decline category, with the
/// localized Update card CTA.
public func lockoutCopy(_ ctx: EnforcementContext, locale: String) -> EnforcementCopy {
    let loc = resolveLocale(locale)
    let reasons = lockoutTable[loc] ?? lockoutTable["en"]!
    let group = reasons[ctx.lockoutReason ?? "hard_decline"] ?? reasons["hard_decline"]!
    let message = (ctx.declineCategory.flatMap { group[$0] }) ?? group["_default"]!
    return EnforcementCopy(message: message, cta: ctaTable[loc] ?? ctaTable["en"]!)
}
