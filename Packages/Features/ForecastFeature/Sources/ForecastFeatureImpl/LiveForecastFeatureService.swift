import Data
import ForecastFeatureAPI
import Foundation

public enum ForecastFeatureServiceError: Error {
    case invalidInput
}

public struct LiveForecastFeatureService: Sendable {
    private let dataSource: any WeatherRemoteDataSource

    public init(dataSource: any WeatherRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func fetchForecast(location: String, days: Int) async throws -> [ForecastDay] {
        guard days > 0 else {
            throw ForecastFeatureServiceError.invalidInput
        }

        let safeLocation = String(location)
        let requestedDays = min(days, 5)
        let dto = try await dataSource.fetchForecast(for: safeLocation, days: requestedDays)
        let forecastDays = Array(dto.forecast.forecastDay.prefix(requestedDays))

        guard !forecastDays.isEmpty else {
            throw WeatherAPIError.emptyPayload
        }

        var resolvedForecast: [ForecastDay] = []
        resolvedForecast.reserveCapacity(forecastDays.count)

        for day in forecastDays {
            let dateLabel = await ForecastDateLabelFormatter.shared.label(from: day.date)
            resolvedForecast.append(
                ForecastDay(
                    dateLabel: dateLabel,
                    temperatureC: makeTemperature(from: day.day),
                    summary: day.day.condition.text
                )
            )
        }

        return resolvedForecast
    }

    private func makeTemperature(from day: DayDTO) -> Double {
        day.avgTempC
    }
}

private actor ForecastDateLabelFormatter {
    static let shared = ForecastDateLabelFormatter()

    private let parser: DateFormatter
    private let formatter: DateFormatter

    init() {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        self.parser = parser

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM"
        self.formatter = formatter
    }

    func label(from apiDate: String) -> String {
        guard let date = parser.date(from: apiDate) else {
            return apiDate
        }

        return formatter.string(from: date)
    }
}
