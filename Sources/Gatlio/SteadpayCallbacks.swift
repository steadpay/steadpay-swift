public struct GatlioCallbacks {
    public var onLockout: ((String) -> Void)?
    public var onWarning: ((String) -> Void)?
    public var onActive: ((String) -> Void)?
    public var onRecovered: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    public init(
        onLockout: ((String) -> Void)? = nil,
        onWarning: ((String) -> Void)? = nil,
        onActive: ((String) -> Void)? = nil,
        onRecovered: ((String) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.onLockout = onLockout
        self.onWarning = onWarning
        self.onActive = onActive
        self.onRecovered = onRecovered
        self.onError = onError
    }
}
