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
