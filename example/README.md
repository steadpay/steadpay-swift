# ArcaExample — gatlio-swift

A fictional analytics SaaS app that demonstrates a complete `gatlio-swift` integration. Arcta is used as the host app throughout Gatlio's example suite so you can compare SDK behaviour across platforms side by side.

## Screens

| Screen | File | Purpose |
|--------|------|---------|
| Login | `ArcaExample/LoginView.swift` | Fake login form — any credentials navigate to Home |
| Home | `ArcaExample/HomeView.swift` | Main content wrapped in `GatlioSandbox` |
| Settings | `ArcaExample/SettingsView.swift` | Static account info screen |
| Content | `ArcaExample/ArctaContentView.swift` | Fake analytics dashboard — the "protected" content |

`GatlioSandbox` lives in `HomeView.swift`. It wraps `ArctaContentView` and surfaces a `DEV` badge in the bottom-right corner of the screen.

## Running

### Prerequisites

- macOS with Xcode 16.4.0
- The package resolves `gatlio-swift` from the local path — no extra setup needed

### Open the project

```sh
open example/ArcaExample.xcodeproj
```

Select an iPhone simulator from the scheme picker (e.g. iPhone 16 Pro) and press **⌘R**.

### Command line

```sh
xcodebuild \
  -project example/ArcaExample.xcodeproj \
  -scheme ArcaExample \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

### Physical iPhone

Plug in → Xcode detects the device → select it in the scheme picker → **⌘R**. A free Apple developer account is sufficient for personal device testing.

> Physical devices can't reach `localhost`. Use ngrok (`ngrok http 3000`) to expose your local Gatlio instance and enter the ngrok URL in Live mode.

## Testing with GatlioSandbox

### Sandbox mode (no server needed)

1. Sign in with any credentials and navigate to Home.
2. Tap the **DEV** badge in the bottom-right corner.
3. A `.sheet()` slides up showing four state pills: `active`, `warning`, `lockout`, `error`.
4. Tap any pill — the UI transitions immediately. No network calls, no rebuild.

What to verify in each state:

| State | Expected behaviour |
|-------|--------------------|
| `active` | Content renders normally; no banner, no gate |
| `warning` | Amber banner appears above content; tap **Dismiss** to hide for the session |
| `lockout` | Full-screen gate covers all content; nothing behind it is tappable |
| `error` | Content still renders (fail open); no crash |

The sheet also shows a **callback log** (last 5 invocations). Confirm `onLockout`, `onWarning`, and `onActive` fire on the correct transitions without adding `print` statements.

### Sandbox mode — what fires and what doesn't

| Transition | Callback fired |
|-----------|---------------|
| `active → warning` | `onWarning` |
| `active → lockout` | `onLockout` |
| `warning → lockout` | `onLockout` |
| `lockout → active` | `onActive` |
| `warning → active` | `onActive` |
| any → `error` | `onError` |
| same → same | nothing |

`onRecovered` is **not** fired by the sandbox — it requires the real card update flow. Test it in Live mode with a Stripe test card.

### SwiftUI Previews — instant visual iteration

Every view file ships with `#Preview` blocks. Open any file in Xcode and toggle the preview panel (**⌘⌥↩**) to see all states rendered side by side — no simulator launch needed.

### Live mode (real Gatlio instance)

1. Start Gatlio locally (`npm run dev`) and expose it via ngrok.
2. Run `npm run seed` to create the `test-harness` tenant and seeded subscribers.
3. In the example app, tap the **DEV** badge and switch to **Live** mode in the sheet.
4. Enter:
   - **API base**: your ngrok URL
   - **Tenant slug**: `test-harness`
   - **Publishable key**: from the seed script output
   - **Customer ID**: one of `cus_harness_active`, `cus_harness_warning`, `cus_harness_lockout`
5. Tap **Connect** — the SDK polls the real status API.

To force a state transition mid-test, update the subscriber in Postgres:

```sql
UPDATE subscribers SET status = 'lockout'
WHERE stripe_customer_id = 'cus_harness_warning';
```

Background the app and foreground it — `UIApplication.didBecomeActiveNotification` fires a poll and the UI updates.

> The iOS Simulator can reach `localhost` directly — no ngrok needed for simulator testing. Physical devices require a public URL.

## Integration reference

```swift
// ArcaExample/HomeView.swift
import GatlioUI

GatlioSandbox(
    onLockout: { print("lockout") },
    onWarning: { print("warning") },
    onActive: { print("active") }
) {
    ArctaContentView()
}
```

For production, replace `GatlioSandbox` with `GatlioGate`:

```swift
import GatlioUI

GatlioGate(
    apiBase: "https://api.gatlio.io",
    tenantSlug: "your-slug",
    publishableKey: "pk_live_xxx",
    customerId: currentUser.stripeCustomerId,
    onLockout: { analytics.track("billing_lockout") },
    onRecovered: { analytics.track("billing_recovered") }
) {
    YourApp()
}
```

UIKit apps import `Gatlio` (not `GatlioUI`) and observe `GatlioClient` directly via Combine or KVO — see the main SDK README for the UIKit integration path.
