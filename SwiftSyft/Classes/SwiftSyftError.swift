import Foundation
import Combine

enum SwiftSyftError: Error {
    case networkConstraintsFailure
    case batteryConstraintsFailure
    case authenticationFailure
    case cycleRejected
    case networkError(underlyingError: Error, urlResponse: URLResponse?)
    case unknownError(underlyingError: Error?)
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
