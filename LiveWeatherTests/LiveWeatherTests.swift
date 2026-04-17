//
//  LiveWeatherTests.swift
//  LiveWeatherTests
//
//  Created by Prashant Gautam on 20/03/26.
//

import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import ForecastFeatureAPI
@testable import LiveWeather
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
    func testAppContainerBuildsFeatureFromInjectedConfigValues() {
        let provider = CurrentWeatherFeatureFactory.live(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )
        let builderSpy = CurrentWeatherFeatureBuilderSpy(viewModelFactory: {
            provider.makeWeatherViewModel()
        })

        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { apiKey, apiURL in
                builderSpy.make(apiKey: apiKey, apiURL: apiURL)
            }
        )
        LiveWeatherTestRetainer.retain(builderSpy)
        LiveWeatherTestRetainer.retain(container)

        XCTAssertEqual(builderSpy.receivedInputs.count, 1)
        XCTAssertEqual(builderSpy.receivedInputs.first?.apiKey, "test-key")
        XCTAssertEqual(builderSpy.receivedInputs.first?.apiURL, "https://example.com/v1/current.json")
    }

    @MainActor
    func testAppContainerCreatesIndependentViewModels() {
        let provider = CurrentWeatherFeatureFactory.live(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                {
                    provider.makeWeatherViewModel()
                }
            }
        )
        LiveWeatherTestRetainer.retain(container)

        let first = container.makeWeatherViewModel()
        let second = container.makeWeatherViewModel()

        XCTAssertFalse(first === second)
    }

    @MainActor
    func testContainerUsesFeatureProviderToCreateViewModels() {
        let factorySpy = CurrentWeatherViewModelFactorySpy()
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                {
                    factorySpy.make()
                }
            }
        )
        LiveWeatherTestRetainer.retain(container)

        _ = container.makeWeatherViewModel()
        _ = container.makeWeatherViewModel()

        XCTAssertEqual(factorySpy.makeWeatherViewModelCallCount, 2)
    }

    @MainActor
    func testAppContainerFetchDefaultForecastUsesExpectedLocationAndDays() async throws {
        let currentWeatherProvider = CurrentWeatherFeatureFactory.live(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )
        let forecastProviderSpy = ForecastFeatureProviderSpy(
            stubbedDays: [ForecastDay(dateLabel: "Fri, 11 Apr", temperatureC: 31, summary: "Sunny")]
        )

        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                {
                    currentWeatherProvider.makeWeatherViewModel()
                }
            },
            forecastFeatureBuilder: { _, _ in
                forecastProviderSpy
            }
        )
        LiveWeatherTestRetainer.retain(container)

        let forecast = try await container.fetchDefaultForecast()

        XCTAssertEqual(forecast.count, 1)
        XCTAssertEqual(forecast.first?.summary, "Sunny")

        let call = await forecastProviderSpy.lastCall()
        XCTAssertEqual(call?.location, "New Delhi")
        XCTAssertEqual(call?.days, 5)
    }
}

private final class CurrentWeatherFeatureBuilderSpy {
    private(set) var receivedInputs: [(apiKey: String, apiURL: String)] = []
    private let viewModelFactory: CurrentWeatherViewModelFactory

    init(viewModelFactory: @escaping CurrentWeatherViewModelFactory) {
        self.viewModelFactory = viewModelFactory
    }

    func make(apiKey: String, apiURL: String) -> CurrentWeatherViewModelFactory {
        receivedInputs.append((apiKey: apiKey, apiURL: apiURL))
        return viewModelFactory
    }
}

private final class CurrentWeatherViewModelFactorySpy {
    private let backingProvider: any CurrentWeatherFeatureProviding
    private(set) var makeWeatherViewModelCallCount = 0

    init(backingProvider: any CurrentWeatherFeatureProviding = CurrentWeatherFeatureFactory.live(
        weatherAPIKey: "test-key",
        weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
    )) {
        self.backingProvider = backingProvider
    }

    @MainActor
    func make() -> CurrentWeatherViewModel {
        makeWeatherViewModelCallCount += 1
        return backingProvider.makeWeatherViewModel()
    }
}

private enum LiveWeatherTestRetainer {
    static var retainedObjects: [AnyObject] = []

    static func retain(_ object: AnyObject) {
        retainedObjects.append(object)
    }
}

private actor ForecastFeatureProviderSpy: ForecastFeatureProviding {
    struct Call {
        let location: String
        let days: Int
    }

    private let stubbedDays: [ForecastDay]
    private var calls: [Call] = []

    init(stubbedDays: [ForecastDay]) {
        self.stubbedDays = stubbedDays
    }

    func fetchForecast(location: String, days: Int) async throws -> [ForecastDay] {
        calls.append(Call(location: location, days: days))
        return stubbedDays
    }

    func lastCall() -> Call? {
        calls.last
    }
}
