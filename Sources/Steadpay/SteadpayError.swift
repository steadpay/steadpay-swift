public enum SteadpayError: Error, Equatable {
    case invalidURL
    case unauthorized
    case tenantNotFound
    case unexpectedStatus(Int)
}
