# steadpay-swift

Swift SDK for [Steadpay](https://steadpay.io) billing enforcement. SwiftUI view that enforces subscriber billing states natively — supports iOS 15+ and macOS 13+.

## Installation

Add the package via Swift Package Manager:

```
https://github.com/steadpay/steadpay-swift
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/steadpay/steadpay-swift.git", from: "1.0.0")
```

Then add `SteadpayUI` (and optionally `Steadpay` for direct client usage) as a target dependency.

## Quick start

Wrap the authenticated portion of your app in `SteadpayGate`:

```swift
import SteadpayUI

SteadpayGate(
    tenantSlug: "acme",
    customerId: currentUser.stripeCustomerId,
    publishableKey: "pk_live_abc123",
    apiBase: "https://app.steadpay.io"
) {
    YourApp()
}
```

When billing is current, `YourApp` renders normally. In `warning` state a dismissable banner appears above it. In `lockout` a full-screen overlay replaces all content until the card is updated.

## `SteadpayGate` — parameters

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| `tenantSlug` | `String` | ✓ | — |
| `customerId` | `String` | ✓ | — |
| `publishableKey` | `String` | ✓ | — |
| `apiBase` | `String` | ✓ | — |
| `pollInterval` | `TimeInterval` | | `600` |
| `forcedStatus` | `SteadpayStatus?` | | `nil` |
| `callbacks` | `SteadpayCallbacks?` | | `nil` |
| `lockoutScreen` | `((@escaping () -> Void, Entitlements?) -> AnyView)?` | | built-in |
| `warningBanner` | `((@escaping () -> Void, @escaping () -> Void) -> AnyView)?` | | built-in |
| `content` | `@ViewBuilder` | ✓ | — |

## Callbacks

```swift
SteadpayGate(
    // ...
    callbacks: SteadpayCallbacks(
        onLockout: { print("locked out") },
        onWarning: { print("warning") },
        onActive: { print("active") },
        onRecovered: { print("recovered after card update") },
        onError: { err in print("error: \(err)") }
    )
) {
    YourApp()
}
```

Callbacks fire on status *transitions*, not on every poll tick.

## Custom enforcement UI

Wrap your custom views in `AnyView(...)`:

```swift
SteadpayGate(
    // ...
    lockoutScreen: { triggerCardUpdate, _ in
        AnyView(MyBrandedLockout(onUpdate: triggerCardUpdate))
    },
    warningBanner: { triggerCardUpdate, dismissWarning in
        AnyView(MyBrandedBanner(onUpdate: triggerCardUpdate, onDismiss: dismissWarning))
    }
) {
    YourApp()
}
```

## Testing your integration

### Force a state — `forcedStatus`

```swift
SteadpayGate(
    tenantSlug: "acme",
    customerId: "cus_test",
    publishableKey: "pk_test_abc",
    apiBase: "https://app.steadpay.io",
    forcedStatus: .lockout  // no network calls
) {
    YourApp()
}
```

Remove `forcedStatus` before shipping.

### Interactive harness — `SteadpaySandbox`

`SteadpaySandbox` is a drop-in dev view that lets you switch billing states and verify your callbacks without a real Steadpay account.

**How it works:** your content renders at full size with a small `DEV` badge anchored to the bottom-right corner as a true overlay. Tap the badge to open a `.sheet()` control panel; tap a state pill to switch states; swipe down or tap outside to dismiss the sheet.

```swift
import SteadpayUI

SteadpaySandbox(
    onLockout: { print("locked out") },
    onWarning: { print("warning") },
    onActive: { print("active") },
    onError: { err in print("error: \(err)") }
) {
    YourApp()
}
```

The sandbox accepts custom `lockoutScreen` and `warningBanner` overrides — pass them to verify your own UI and dismiss handlers:

```swift
SteadpaySandbox(
    lockoutScreen: { triggerCardUpdate, _ in
        AnyView(MyBrandedLockout(onUpdate: triggerCardUpdate))
    },
    warningBanner: { triggerCardUpdate, dismissWarning in
        AnyView(MyBrandedBanner(onUpdate: triggerCardUpdate, onDismiss: dismissWarning))
    }
) {
    YourApp()
}
```

**What the control sheet shows:**
- Four state pills (`active`, `warning`, `lockout`, `error`) — tap to transition
- Current-status indicator
- Callback log (last 5 invocations, newest first)
- `onRecovered` limitation note

**Callback rules:**

| Transition | Fires |
|-----------|-------|
| `.active → .warning` | `onWarning` |
| `.active → .lockout` | `onLockout` |
| `.warning → .lockout` | `onLockout` |
| `.lockout → .active` | `onActive` |
| `.warning → .active` | `onActive` |
| any → `.error` | `onError` (first press only) |
| same → same | nothing |

**`onRecovered` is not fired by the sandbox** — it requires the real card update flow (`triggerCardUpdate()` → browser → poll returns `.active`). Test it against a live Steadpay environment with a Stripe test card.

Remove `SteadpaySandbox` before shipping to production.

## Direct client usage (UIKit / non-SwiftUI)

```swift
import Steadpay

let client = SteadpayClient(
    config: SteadpayConfig(
        apiBase: "https://app.steadpay.io",
        tenantSlug: "acme",
        customerId: currentUser.stripeCustomerId,
        publishableKey: "pk_live_abc123"
    )
)
client.start()

// Subscribe to individual @Published properties via Combine:
client.$status
    .receive(on: DispatchQueue.main)
    .sink { status in /* update UI */ }
    .store(in: &cancellables)
```

Call `client.stop()` in `deinit` or `viewDidDisappear`.

## License

MIT
