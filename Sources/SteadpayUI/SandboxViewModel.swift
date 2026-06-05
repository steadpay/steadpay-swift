import Foundation
import Steadpay

internal let sandboxRecoveredNote =
    "onRecovered requires a real card update — test against a live Steadpay environment."

internal final class SandboxViewModel {
    var currentStatus: SteadpayStatus = .active
    var log: [String] = []
    private(set) var lastStatus: SteadpayStatus? = .active

    var onLockout: (() -> Void)?
    var onWarning: (() -> Void)?
    var onActive: (() -> Void)?
    var onError: ((Error) -> Void)?

    func changeStatus(_ next: SteadpayStatus) {
        if next == .error {
            let err = NSError(
                domain: "SteadpaySandbox", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "sandbox_error"]
            )
            onError?(err)
            log.insert("onError(sandbox_error)", at: 0)
            if log.count > 5 { log.removeLast() }
            currentStatus = .error
            lastStatus = .error
            return
        }

        let cbName = computeTransition(lastStatus: lastStatus, newStatus: next, isRecoveryPath: false)
        currentStatus = next
        lastStatus = next

        guard let cbName else { return }
        switch cbName {
        case .onLockout: onLockout?()
        case .onWarning: onWarning?()
        case .onActive: onActive?()
        case .onRecovered: break
        }
        log.insert("\(cbName)()", at: 0)
        if log.count > 5 { log.removeLast() }
    }
}
