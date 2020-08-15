import Foundation

enum SwiftSyftError: Error {
    case networkConstraintsFailure
    case batteryConstraintsFailure
    case authenticationFailure
    case cycleRejected
    case networkError(underlyingError: Error, urlResponse: URLResponse?)
    case unknownError(underlyingError: Error?)
}

