import Combine
import Foundation

public typealias URLOpener = (URL) -> Void
public typealias FetchFunction = (String, String, String, String) async throws -> StatusResponse

@MainActor
public final class SteadpayClient: ObservableObject {
    @Published public private(set) var status: SteadpayStatus = .loading
    @Published public private(set) var cardUpdateUrl: URL? = nil
    @Published public private(set) var entitlements: Entitlements? = nil
    @Published public private(set) var dismissed: Bool = false

    private let config: SteadpayConfig
    private var callbacks: SteadpayCallbacks?
    private let forcedStatus: SteadpayStatus?
    private let urlOpener: URLOpener
    private let fetch: FetchFunction

    private var pollingTask: Task<Void, Never>?
    private var isRecoveryPath = false
    private var lastStatus: SteadpayStatus? = nil

    public init(
        config: SteadpayConfig,
        callbacks: SteadpayCallbacks? = nil,
        forcedStatus: SteadpayStatus? = nil,
        urlOpener: @escaping URLOpener = { _ in },
        fetch: FetchFunction? = nil
    ) {
        self.config = config
        self.callbacks = callbacks
        self.forcedStatus = forcedStatus
        self.urlOpener = urlOpener
        self.fetch = fetch ?? { apiBase, tenantSlug, customerId, publishableKey in
            try await fetchSubscriberStatus(
                baseURL: apiBase,
                tenantSlug: tenantSlug,
                customerId: customerId,
                publishableKey: publishableKey
            )
        }
    }

    public func start() {
        if let forced = forcedStatus {
            status = forced
            cardUpdateUrl = URL(string: "https://example.com/update-card?forced=1")
            entitlements = Entitlements(poweredByWatermark: true, customDomain: true, downstreamWebhooks: true)
            return
        }
        startPolling()
    }

    public func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    public func triggerCardUpdate() {
        guard let url = cardUpdateUrl, url.scheme == "https" else { return }
        isRecoveryPath = true
        dismissed = false
        urlOpener(url)
        startPolling()
    }

    public func dismissWarning() {
        dismissed = true
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.runPollingLoop()
        }
    }

    private static let minPollInterval: TimeInterval = 60

    private func runPollingLoop() async {
        await doPoll()
        guard !Task.isCancelled, status != .lockout else { return }

        let clampedInterval = max(Self.minPollInterval, config.pollInterval)
        let intervalNS = UInt64(clampedInterval * 1_000_000_000)
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: intervalNS)
            if Task.isCancelled { break }
            await doPoll()
            if status == .lockout { break }
        }
    }

    private func doPoll() async {
        let wasRecovery = isRecoveryPath
        isRecoveryPath = false

        do {
            let response = try await fetch(
                config.apiBase,
                config.tenantSlug,
                config.customerId,
                config.publishableKey
            )

            let cbName = computeTransition(
                lastStatus: lastStatus,
                newStatus: response.status,
                isRecoveryPath: wasRecovery
            )

            status = response.status
            cardUpdateUrl = response.cardUpdateUrl
            entitlements = response.entitlements
            lastStatus = response.status

            if let cb = cbName { fireCallback(cb) }
        } catch {
            status = .error
            lastStatus = .error
            callbacks?.onError?(error)
        }
    }

    private func fireCallback(_ name: CallbackName) {
        let id = config.customerId
        switch name {
        case .onLockout:   callbacks?.onLockout?(id)
        case .onWarning:   callbacks?.onWarning?(id)
        case .onActive:    callbacks?.onActive?(id)
        case .onRecovered: callbacks?.onRecovered?(id)
        }
    }
}
