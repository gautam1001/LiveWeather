//
//  LiveWeatherTests.swift
//  LiveWeatherTests
//
//  Created by Prashant Gautam on 20/03/26.
//

import Domain
@testable import LiveWeather
import Presentation
import XCTest

final class LiveWeatherTests: XCTestCase {
    func testConfigKeysRawValuesMatchExpectedInfoPlistKeys() {
        XCTAssertEqual(ConfigKeys.weatherApiUrl.rawValue, "WeatherApiUrl")
        XCTAssertEqual(ConfigKeys.weatherApiKey.rawValue, "WeatherApiKey")
        XCTAssertEqual(ConfigKeys.appName.rawValue, "CFBundleName")
        XCTAssertEqual(ConfigKeys.bundleIdentifier.rawValue, "CFBundleIdentifier")
        XCTAssertEqual(ConfigKeys.appVersion.rawValue, "CFBundleShortVersionString")
        XCTAssertEqual(ConfigKeys.buildNumber.rawValue, "CFBundleVersion")
    }

    func testAppConfigProvidesWeatherAPIValues() {
        let key = AppConfig.weatherAPIKey
        let url = AppConfig.weatherAPIUrl

        XCTAssertFalse(key.isEmpty)
        XCTAssertFalse(url.isEmpty)
    }

    func testAppConfigWeatherAPIURLIsAValidHTTPSURL() throws {
        let urlString = AppConfig.weatherAPIUrl
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertEqual(url.scheme, "https")
        XCTAssertNotNil(url.host)
        XCTAssertEqual(url.host, "api.weatherapi.com")
    }

    @MainActor
    func testAppContainerBuildsRepositoryFromInjectedConfigValues() async {
        let repository = WeatherRepositoryStub(result: .success(sampleWeather))
        let factorySpy = RepositoryFactorySpy(repository: repository)

        _ = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            repositoryFactory: { apiKey, apiURL in
                factorySpy.make(apiKey: apiKey, apiURL: apiURL)
            }
        )

        XCTAssertEqual(factorySpy.receivedInputs.count, 1)
        XCTAssertEqual(factorySpy.receivedInputs.first?.apiKey, "test-key")
        XCTAssertEqual(factorySpy.receivedInputs.first?.apiURL, "https://example.com/v1/current.json")
        await Task.yield()
    }

    @MainActor
    func testAppContainerCreatesIndependentViewModels() async {
        let repository = WeatherRepositoryStub(result: .success(sampleWeather))
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            repositoryFactory: { _, _ in repository }
        )

        let first = container.makeWeatherViewModel()
        let second = container.makeWeatherViewModel()

        XCTAssertFalse(first === second)
        await Task.yield()
    }

    @MainActor
    func testContainerViewModelLoadTransitionsToLoadedStateOnSuccess() async {
        let repository = WeatherRepositoryStub(result: .success(sampleWeather))
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            repositoryFactory: { _, _ in repository }
        )
        let viewModel = container.makeWeatherViewModel()

        await viewModel.load(for: "Ghaziabad")

        guard case let .loaded(overview) = viewModel.state else {
            return XCTFail("Expected .loaded state")
        }

        XCTAssertEqual(overview.locationName, "Ghaziabad")
        XCTAssertEqual(overview.current, sampleWeather)
        let requested = repository.recordedLocations()
        XCTAssertEqual(requested.count, 1)
        XCTAssertEqual(requested.first?.name, "Ghaziabad")
    }

    @MainActor
    func testContainerViewModelLoadTransitionsToFailedStateOnFailure() async {
        let repository = WeatherRepositoryStub(result: .failure(WeatherRepositoryStubError.network))
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            repositoryFactory: { _, _ in repository }
        )
        let viewModel = container.makeWeatherViewModel()

        await viewModel.load(for: "Ghaziabad")

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected .failed state")
        }

        XCTAssertFalse(message.isEmpty)
        let requested = repository.recordedLocations()
        XCTAssertEqual(requested.count, 1)
        XCTAssertEqual(requested.first?.name, "Ghaziabad")
    }
}

private let sampleWeather = WeatherNow(
    temperatureC: 29.8,
    conditionCode: 1000,
    conditionSummary: "Clear",
    conditionDescription: "clear sky"
)

private final class WeatherRepositoryStub: WeatherRepository, @unchecked Sendable {
    private let result: Result<WeatherNow, Error>
    private var locations: [Location] = []

    init(result: Result<WeatherNow, Error>) {
        self.result = result
    }

    func getCurrentWeather(for location: Location) async throws -> WeatherNow {
        locations.append(location)
        return try result.get()
    }

    func recordedLocations() -> [Location] {
        return locations
    }
}

private final class RepositoryFactorySpy {
    private(set) var receivedInputs: [(apiKey: String, apiURL: String)] = []
    private let repository: WeatherRepository

    init(repository: WeatherRepository) {
        self.repository = repository
    }

    func make(apiKey: String, apiURL: String) -> WeatherRepository {
        receivedInputs.append((apiKey: apiKey, apiURL: apiURL))
        return repository
    }
}

private enum WeatherRepositoryStubError: Error {
    case network
}
