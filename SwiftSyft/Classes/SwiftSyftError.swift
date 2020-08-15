import Foundation
import Combine

public enum SwiftSyftError: Error, LocalizedError {
    case networkConstraintsFailure
    case batteryConstraintsFailure
    case authenticationFailure(underlyingError: Error)
    case cycleRejected(status: String, timeout: Int?, error: String?)
    case networkError(underlyingError: Error, urlResponse: URLResponse?)
    case networkResponseError(underlyingError: Error?)
    case unknownError(underlyingError: Error?)

    public var localizedDescription: String {
        switch self {
        case .networkConstraintsFailure:
            return "Network constraints failed"
        case .batteryConstraintsFailure:
            return "Battery constraints failed"
        case .authenticationFailure:
            return "Authentication failed"
        case .cycleRejected:
            return "Rejected from learning cycle"
        case .networkError:
            return "Network error"
        case .networkResponseError:
            return "Server response error"
        case .unknownError:
            return "Unknown error"
        }
    }

}

// Easier `mapError` for decode publisher
// Source: https://stackoverflow.com/questions/57768427/swift-combine-chaining-maperror
extension Publisher {
    //swiftlint:disable line_length
    func decode<Item, Coder>(type: Item.Type,
                             decoder: Coder,
                             errorTransform: @escaping (Error) -> Failure) -> Publishers.FlatMap<Publishers.MapError<Publishers.Decode<Just<Self.Output>, Item, Coder>, Self.Failure>, Self> where Item: Decodable, Coder: TopLevelDecoder, Self.Output == Coder.Input {
        return flatMap {
            Just($0)
                .decode(type: type, decoder: decoder)
                .mapError { errorTransform($0) }
        }
    }
}
