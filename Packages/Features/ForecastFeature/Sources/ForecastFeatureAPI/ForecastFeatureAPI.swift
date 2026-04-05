import ForecastFeatureImpl
import Foundation

public struct ForecastDay: Equatable, Sendable {
    public let dateLabel: String
    public let temperatureC: Double
    public let summary: String

    public init(dateLabel: String, temperatureC: Double, summary: String) {
        self.dateLabel = dateLabel
        self.temperatureC = temperatureC
        self.summary = summary
    }
}

public protocol ForecastFeatureProviding {
    func fetchForecast(location: String, days: Int) async throws -> [ForecastDay]
}

public final class LiveForecastFeatureProvider {
    private let service: LiveForecastFeatureService

    public init(service: LiveForecastFeatureService = LiveForecastFeatureService()) {
        self.service = service
    }

    public func fetchForecast(location: String, days: Int) async throws -> [ForecastDay] {
        let snapshots = try await service.fetchForecast(location: location, days: days)
        return snapshots.map { snapshot in
            ForecastDay(
                dateLabel: snapshot.dateLabel,
                temperatureC: snapshot.temperatureC,
                summary: snapshot.summary
            )
        }
    }
}

extension LiveForecastFeatureProvider: ForecastFeatureProviding {}

public enum ForecastFeatureFactory {
    public static func live() -> any ForecastFeatureProviding {
        LiveForecastFeatureProvider()
    }
}
