import SwiftUI
import Steadpay

public struct SteadpaySandbox<Content: View>: View {
    private let forcedStatus: SteadpayStatus
    private let lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)?
    private let warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)?
    private let content: Content

    public init(
        forcedStatus: SteadpayStatus,
        lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)? = nil,
        warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.forcedStatus = forcedStatus
        self.lockoutScreen = lockoutScreen
        self.warningBanner = warningBanner
        self.content = content()
    }

    public var body: some View {
        SteadpayGate(
            tenantSlug: "sandbox",
            customerId: "cus_sandbox",
            publishableKey: "pk_test_sandbox",
            apiBase: "https://example.com",
            forcedStatus: forcedStatus,
            lockoutScreen: lockoutScreen,
            warningBanner: warningBanner
        ) {
            content
        }
    }
}

#Preview("Lockout") {
    SteadpaySandbox(forcedStatus: .lockout) {
        Text("Protected content")
    }
}

#Preview("Warning") {
    SteadpaySandbox(forcedStatus: .warning) {
        Text("Protected content")
    }
}

#Preview("Active") {
    SteadpaySandbox(forcedStatus: .active) {
        Text("Protected content")
    }
}
