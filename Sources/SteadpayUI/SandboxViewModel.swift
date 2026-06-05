import Foundation
import Steadpay

internal let sandboxRecoveredNote =
    "onRecovered requires a real card update — test against a live Steadpay environment."

internal final class SandboxViewModel: ObservableObject {
    @Published var currentStatus: SteadpayStatus = .active
    @Published var isPanelOpen: Bool = false
    @Published var isDismissed: Bool = false
    @Published var log: [String] = []
    private(set) var lastStatus: SteadpayStatus? = .active

    var onLockout: (() -> Void)?
    var onWarning: (() -> Void)?
    var onActive: (() -> Void)?
    var onError: ((Error) -> Void)?

    func changeStatus(_ next: SteadpayStatus) {
        if next == .error {
            if currentStatus == .error { return }
            let err = NSError(
                domain: "SteadpaySandbox", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "sandbox_error"]
            )
            onError?(err)
            appendLog("onError(sandbox_error)")
            currentStatus = .error
            lastStatus = .error
            isDismissed = false
            return
        }

        let cbName = computeTransition(lastStatus: lastStatus, newStatus: next, isRecoveryPath: false)
        if next != .warning { isDismissed = false }
        currentStatus = next
        lastStatus = next

        guard let cbName else { return }
        switch cbName {
        case .onLockout: onLockout?()
        case .onWarning: onWarning?()
        case .onActive: onActive?()
        case .onRecovered: break
        }
        appendLog("\(cbName)()")
    }

    func dismissWarning() {
        isDismissed = true
    }

    private func appendLog(_ entry: String) {
        log.insert(entry, at: 0)
        if log.count > 5 { log.removeLast() }
    }
}
