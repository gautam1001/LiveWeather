import Foundation

public struct SearchLocation: Equatable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

public protocol SearchFeatureProviding: Sendable {
    func search(query: String) async throws -> [SearchLocation]
}
