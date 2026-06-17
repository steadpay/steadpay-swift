import SwiftUI
import Steadpay

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

private struct SteadpayGateCore: View {
    @StateObject private var client: SteadpayClient

    private let lockoutScreen: ((@escaping () -> Void, Entitlements?, String, String) -> AnyView)?
    private let warningBanner: ((@escaping () -> Void, String) -> AnyView)?
    private let content: AnyView

    init(
        config: SteadpayConfig,
        callbacks: SteadpayCallbacks?,
        forcedStatus: SteadpayStatus?,
        lockoutScreen: ((@escaping () -> Void, Entitlements?, String, String) -> AnyView)?,
        warningBanner: ((@escaping () -> Void, String) -> AnyView)?,
        content: AnyView
    ) {
        let opener: URLOpener = { url in
#if canImport(UIKit)
            UIApplication.shared.open(url)
#else
            NSWorkspace.shared.open(url)
#endif
        }
        _client = StateObject(
            wrappedValue: SteadpayClient(
                config: config,
                callbacks: callbacks,
                forcedStatus: forcedStatus,
                urlOpener: opener
            )
        )
        self.lockoutScreen = lockoutScreen
        self.warningBanner = warningBanner
        self.content = content
    }

    var body: some View {
        Group {
            if client.status == .lockout {
                let copy = lockoutCopy(client.enforcementContext, locale: client.locale)
                if let builder = lockoutScreen {
                    builder(client.triggerCardUpdate, client.entitlements, copy.message, copy.cta ?? "")
                } else {
                    LockoutScreen(
                        poweredByWatermark: client.entitlements?.poweredByWatermark ?? true,
                        message: copy.message,
                        cta: copy.cta ?? "",
                        onTriggerCardUpdate: client.triggerCardUpdate
                    )
                }
            } else {
                ZStack(alignment: .top) {
                    content
                    if client.status == .warning && !client.dismissed {
                        let message = warningCopy(client.enforcementContext, locale: client.locale).message
                        if let builder = warningBanner {
                            builder(client.dismissWarning, message)
                        } else {
                            WarningBanner(
                                message: message,
                                onDismiss: client.dismissWarning
                            )
                        }
                    }
                }
            }
        }
        .onAppear { client.start() }
        .onDisappear { client.stop() }
    }
}

public struct SteadpayGate<Content: View>: View {
    private let tenantSlug: String
    private let customerId: String
    private let publishableKey: String
    private let apiBase: String
    private let pollInterval: TimeInterval
    private let forcedStatus: SteadpayStatus?
    private let callbacks: SteadpayCallbacks?
    private let lockoutScreen: ((@escaping () -> Void, Entitlements?, String, String) -> AnyView)?
    private let warningBanner: ((@escaping () -> Void, String) -> AnyView)?
    private let content: Content

    public init(
        tenantSlug: String,
        customerId: String,
        publishableKey: String,
        apiBase: String,
        pollInterval: TimeInterval = 600,
        forcedStatus: SteadpayStatus? = nil,
        callbacks: SteadpayCallbacks? = nil,
        lockoutScreen: ((@escaping () -> Void, Entitlements?, String, String) -> AnyView)? = nil,
        warningBanner: ((@escaping () -> Void, String) -> AnyView)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.tenantSlug = tenantSlug
        self.customerId = customerId
        self.publishableKey = publishableKey
        self.apiBase = apiBase
        self.pollInterval = pollInterval
        self.forcedStatus = forcedStatus
        self.callbacks = callbacks
        self.lockoutScreen = lockoutScreen
        self.warningBanner = warningBanner
        self.content = content()
    }

    public var body: some View {
        SteadpayGateCore(
            config: SteadpayConfig(
                apiBase: apiBase,
                tenantSlug: tenantSlug,
                customerId: customerId,
                publishableKey: publishableKey,
                pollInterval: pollInterval
            ),
            callbacks: callbacks,
            forcedStatus: forcedStatus,
            lockoutScreen: lockoutScreen,
            warningBanner: warningBanner,
            content: AnyView(content)
        )
        .id(customerId)
    }
}
