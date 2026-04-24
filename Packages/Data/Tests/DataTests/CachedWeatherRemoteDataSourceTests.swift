@testable import Data
@testable import Domain
import Foundation
import XCTest

final class CachedWeatherRemoteDataSourceTests: XCTestCase {
    func testFetchWeatherReturnsCachedValueWithinTTL() async throws {
        let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 1_000))
        let remoteDataSource = WeatherRemoteDataSourceSpy(
            currentWeatherResponses: [
                makeCurrentWeatherDTO(temperatureC: 28.5),
                makeCurrentWeatherDTO(temperatureC: 31.0),
            ]
        )
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: WeatherCachePolicy(currentWeatherTTL: 300, forecastTTL: 900),
            dateProvider: dateProvider.now
        )
        let location = makeLocation()

        let firstResponse = try await dataSource.fetchWeather(for: location)
        dateProvider.advance(by: 60)
        let secondResponse = try await dataSource.fetchWeather(for: location)

        XCTAssertEqual(firstResponse.current.tempC, 28.5)
        XCTAssertEqual(secondResponse.current.tempC, 28.5)
        let callCount = await remoteDataSource.currentWeatherCallCount()
        XCTAssertEqual(callCount, 1)
    }

    func testFetchWeatherRefetchesWhenCacheExpires() async throws {
        let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 1_000))
        let remoteDataSource = WeatherRemoteDataSourceSpy(
            currentWeatherResponses: [
                makeCurrentWeatherDTO(temperatureC: 28.5),
                makeCurrentWeatherDTO(temperatureC: 31.0),
            ]
        )
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: WeatherCachePolicy(currentWeatherTTL: 300, forecastTTL: 900),
            dateProvider: dateProvider.now
        )
        let location = makeLocation()

        let firstResponse = try await dataSource.fetchWeather(for: location)
        dateProvider.advance(by: 301)
        let secondResponse = try await dataSource.fetchWeather(for: location)

        XCTAssertEqual(firstResponse.current.tempC, 28.5)
        XCTAssertEqual(secondResponse.current.tempC, 31.0)
        let callCount = await remoteDataSource.currentWeatherCallCount()
        XCTAssertEqual(callCount, 2)
    }

    func testFetchForecastReturnsCachedValueForNormalizedLocationAndDays() async throws {
        let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 1_000))
        let remoteDataSource = WeatherRemoteDataSourceSpy(
            forecastResponses: [
                makeForecastDTO(temperatures: [24.0]),
                makeForecastDTO(temperatures: [30.0]),
            ]
        )
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: WeatherCachePolicy(currentWeatherTTL: 300, forecastTTL: 900),
            dateProvider: dateProvider.now
        )

        let firstResponse = try await dataSource.fetchForecast(for: " New Delhi ", days: 5)
        let secondResponse = try await dataSource.fetchForecast(for: "new delhi", days: 5)

        XCTAssertEqual(firstResponse.forecast.forecastDay.first?.day.avgTempC, 24.0)
        XCTAssertEqual(secondResponse.forecast.forecastDay.first?.day.avgTempC, 24.0)
        let callCount = await remoteDataSource.forecastCallCount()
        XCTAssertEqual(callCount, 1)
    }

    func testFetchWeatherSharesInFlightRequestForSameLocation() async throws {
        let remoteDataSource = WeatherRemoteDataSourceSpy(
            currentWeatherResponses: [makeCurrentWeatherDTO(temperatureC: 28.5)],
            delayNanoseconds: 150_000_000
        )
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: WeatherCachePolicy(currentWeatherTTL: 300, forecastTTL: 900)
        )
        let location = makeLocation()

        async let firstResponse = dataSource.fetchWeather(for: location)
        async let secondResponse = dataSource.fetchWeather(for: location)

        let (resolvedFirst, resolvedSecond) = try await (firstResponse, secondResponse)

        XCTAssertEqual(resolvedFirst.current.tempC, 28.5)
        XCTAssertEqual(resolvedSecond.current.tempC, 28.5)
        let callCount = await remoteDataSource.currentWeatherCallCount()
        XCTAssertEqual(callCount, 1)
    }

    private func makeLocation() -> Location {
        Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
    }

    private func makeCurrentWeatherDTO(temperatureC: Double) -> CurrentWeatherResponseDTO {
        CurrentWeatherResponseDTO(
            current: CurrentDTO(
                tempC: temperatureC,
                condition: ConditionDTO(text: "Sunny", code: 1000)
            )
        )
    }

    private func makeForecastDTO(temperatures: [Double]) -> ForecastResponseDTO {
        ForecastResponseDTO(
            forecast: ForecastDTO(
                forecastDay: temperatures.enumerated().map { index, temperature in
                    ForecastDayDTO(
                        date: "2026-04-\(String(format: "%02d", index + 1))",
                        day: DayDTO(
                            avgTempC: temperature,
                            minTempC: temperature - 2,
                            maxTempC: temperature + 2,
                            condition: ConditionDTO(text: "Clear", code: 1000)
                        )
                    )
                }
            )
        )
    }
}

private final class TestDateProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var currentDate: Date

    init(currentDate: Date) {
        self.currentDate = currentDate
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return currentDate
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        currentDate = currentDate.addingTimeInterval(interval)
        lock.unlock()
    }
}

private actor WeatherRemoteDataSourceSpy: WeatherRemoteDataSource {
    private let currentWeatherResponses: [CurrentWeatherResponseDTO]
    private let forecastResponses: [ForecastResponseDTO]
    private let delayNanoseconds: UInt64

    private var currentWeatherCallCounter = 0
    private var forecastCallCounter = 0

    init(
        currentWeatherResponses: [CurrentWeatherResponseDTO] = [],
        forecastResponses: [ForecastResponseDTO] = [],
        delayNanoseconds: UInt64 = 0
    ) {
        self.currentWeatherResponses = currentWeatherResponses
        self.forecastResponses = forecastResponses
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchWeather(for _: Location) async throws -> CurrentWeatherResponseDTO {
        currentWeatherCallCounter += 1

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return currentWeatherResponses[min(currentWeatherCallCounter - 1, currentWeatherResponses.count - 1)]
    }

    func fetchForecast(for _: String, days _: Int) async throws -> ForecastResponseDTO {
        forecastCallCounter += 1

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return forecastResponses[min(forecastCallCounter - 1, forecastResponses.count - 1)]
    }

    func currentWeatherCallCount() -> Int {
        currentWeatherCallCounter
    }

    func forecastCallCount() -> Int {
        forecastCallCounter
    }
}
