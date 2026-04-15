import Data
import Domain
import ForecastFeatureImpl
import Foundation
import XCTest

final class ForecastFeatureTests: XCTestCase {
    func testFetchForecastReturnsRequestedNumberOfDays() async throws {
        let dataSource = MockWeatherRemoteDataSource(
            forecastDTO: makeForecastDTO(days: 5, baseTemperature: 30)
        )
        let provider = LiveForecastFeatureProvider(service: LiveForecastFeatureService(dataSource: dataSource))

        let result = try await provider.fetchForecast(location: "New Delhi", days: 3)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.summary, "Condition 1")
    }

    func testFetchForecastCapsToFiveDays() async throws {
        let dataSource = MockWeatherRemoteDataSource(
            forecastDTO: makeForecastDTO(days: 7, baseTemperature: 25)
        )
        let provider = LiveForecastFeatureProvider(service: LiveForecastFeatureService(dataSource: dataSource))

        let result = try await provider.fetchForecast(location: "New Delhi", days: 7)

        XCTAssertEqual(result.count, 5)
    }

    func testFetchForecastThrowsErrorForInvalidInput() async {
        let dataSource = MockWeatherRemoteDataSource(
            forecastDTO: makeForecastDTO(days: 5, baseTemperature: 30)
        )
        let provider = LiveForecastFeatureProvider(service: LiveForecastFeatureService(dataSource: dataSource))

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.fetchForecast(location: "New Delhi", days: 0)
        }

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.fetchForecast(location: "New Delhi", days: -1)
        }
    }

    func testFetchForecastPropagatesDataLayerError() async {
        let dataSource = MockWeatherRemoteDataSource(
            forecastDTO: makeForecastDTO(days: 5, baseTemperature: 30),
            forecastError: WeatherAPIError.httpStatus(500)
        )
        let provider = LiveForecastFeatureProvider(service: LiveForecastFeatureService(dataSource: dataSource))

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.fetchForecast(location: "New Delhi", days: 5)
        }
    }

    func testFetchForecastThrowsWhenPayloadHasNoForecastDays() async {
        let dataSource = MockWeatherRemoteDataSource(
            forecastDTO: makeForecastDTO(days: 0, baseTemperature: 30)
        )
        let provider = LiveForecastFeatureProvider(service: LiveForecastFeatureService(dataSource: dataSource))

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.fetchForecast(location: "New Delhi", days: 5)
        }
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {}
}

private func makeForecastDTO(days: Int, baseTemperature: Double) -> ForecastResponseDTO {
    var forecastDays: [ForecastDayDTO] = []
    if days > 0 {
        for day in 1 ... days {
            let dayDTO = DayDTO(
                avgTempC: baseTemperature + Double(day),
                minTempC: baseTemperature + Double(day) - 2,
                maxTempC: baseTemperature + Double(day) + 2,
                condition: ConditionDTO(text: "Condition \(day)", code: 1000 + day)
            )
            forecastDays.append(
                ForecastDayDTO(
                    date: "2026-04-\(String(format: "%02d", day))",
                    day: dayDTO
                )
            )
        }
    }

    return ForecastResponseDTO(
        forecast: ForecastDTO(forecastDay: forecastDays)
    )
}

private actor MockWeatherRemoteDataSource: WeatherRemoteDataSource {
    let forecastDTO: ForecastResponseDTO
    let forecastError: Error?

    init(forecastDTO: ForecastResponseDTO, forecastError: Error? = nil) {
        self.forecastDTO = forecastDTO
        self.forecastError = forecastError
    }

    func fetchWeather(for _: Location) async throws -> CurrentWeatherResponseDTO {
        CurrentWeatherResponseDTO(
            current: CurrentDTO(
                tempC: 25,
                condition: ConditionDTO(text: "Clear", code: 1000)
            )
        )
    }

    func fetchForecast(for _: String, days _: Int) async throws -> ForecastResponseDTO {
        if let forecastError {
            throw forecastError
        }
        return forecastDTO
    }
}
