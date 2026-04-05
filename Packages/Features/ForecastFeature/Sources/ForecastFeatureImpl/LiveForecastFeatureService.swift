import Foundation

public enum ForecastFeatureServiceError: Error {
    case invalidInput
}

public struct ForecastSnapshot: Equatable, Sendable {
    public let dateLabel: String
    public let temperatureC: Double
    public let summary: String

    public init(dateLabel: String, temperatureC: Double, summary: String) {
        self.dateLabel = dateLabel
        self.temperatureC = temperatureC
        self.summary = summary
    }
}

public final class LiveForecastFeatureService {
    public init() {}

    public func fetchForecast(location: String, days: Int) async throws -> [ForecastSnapshot] {
        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || days <= 0 {
            throw ForecastFeatureServiceError.invalidInput
        }

        let maxDays = min(days, 7)
        return (1...maxDays).map { day in
            ForecastSnapshot(
                dateLabel: "Day \(day)",
                temperatureC: 26 + Double(day),
                summary: "Sunny"
            )
        }
    }
}
