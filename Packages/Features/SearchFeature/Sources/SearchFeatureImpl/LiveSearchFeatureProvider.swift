import Foundation
import SearchFeatureAPI

public actor LiveSearchFeatureProvider {
    private let service: LiveSearchFeatureService

    public init(service: LiveSearchFeatureService = LiveSearchFeatureService()) {
        self.service = service
    }

    public func search(query: String) async throws -> [SearchLocation] {
        let safeQuery = String(query)
        let locations = try service.search(query: safeQuery)
        return locations.map(SearchLocation.init(name:))
    }
}

extension LiveSearchFeatureProvider: SearchFeatureProviding {}

public enum SearchFeatureFactory {
    public static func live() -> any SearchFeatureProviding {
        LiveSearchFeatureProvider()
    }
}
