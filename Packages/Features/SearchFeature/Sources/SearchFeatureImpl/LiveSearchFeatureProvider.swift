import Foundation
import SearchFeatureAPI

public final class LiveSearchFeatureProvider {
    private let service: LiveSearchFeatureService

    public init(service: LiveSearchFeatureService = LiveSearchFeatureService()) {
        self.service = service
    }

    public func search(query: String) async throws -> [SearchLocation] {
        let locations = try await service.search(query: query)
        return locations.map(SearchLocation.init(name:))
    }
}

extension LiveSearchFeatureProvider: SearchFeatureProviding {}

public enum SearchFeatureFactory {
    public static func live() -> any SearchFeatureProviding {
        LiveSearchFeatureProvider()
    }
}
