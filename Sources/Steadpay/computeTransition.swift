public enum CallbackName: Equatable {
    case onLockout, onWarning, onActive, onRecovered
}

public func computeTransition(
    lastStatus: SteadpayStatus?,
    newStatus: SteadpayStatus,
    isRecoveryPath: Bool
) -> CallbackName? {
    guard lastStatus != newStatus else { return nil }

    switch newStatus {
    case .lockout:
        return .onLockout
    case .warning:
        guard lastStatus != nil else { return nil }
        return .onWarning
    case .active:
        guard lastStatus != nil else { return nil }
        if lastStatus == .lockout && isRecoveryPath { return .onRecovered }
        return .onActive
    case .loading, .error:
        return nil
    }
}
