//
//  LiveWeatherTests.swift
//  LiveWeatherTests
//
//  Created by Prashant Gautam on 20/03/26.
//

import AppComposition
import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import ForecastFeatureAPI
@testable import LiveWeather
import SearchFeatureAPI
import WeatherHomeFeatureImpl
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
        let viewModelFactory = CurrentWeatherFeatureFactory.liveViewModelFactory(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )
        let builderSpy = CurrentWeatherFeatureBuilderSpy(viewModelFactory: viewModelFactory)

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
        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                CurrentWeatherFeatureFactory.liveViewModelFactory(
                    weatherAPIKey: "test-key",
                    weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
                )
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
    func testAppContainerBuildsWeatherHomeFeatureFromInjectedDependencies() {
        let forecastProviderSpy = ForecastFeatureProviderSpy(stubbedDays: [])
        let searchProviderSpy = SearchFeatureProviderSpy(stubbedResults: [])
        let weatherHomeBuilderSpy = WeatherHomeFeatureBuilderSpy()

        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                CurrentWeatherFeatureFactory.liveViewModelFactory(
                    weatherAPIKey: "test-key",
                    weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
                )
            },
            forecastFeatureBuilder: { _, _ in
                forecastProviderSpy
            },
            searchFeatureBuilder: {
                searchProviderSpy
            },
            weatherHomeFeatureBuilder: { currentFactory, forecastProvider, searchProvider in
                weatherHomeBuilderSpy.make(
                    currentWeatherViewModelFactory: currentFactory,
                    forecastProvider: forecastProvider,
                    searchProvider: searchProvider
                )
            }
        )
        LiveWeatherTestRetainer.retain(container)
        LiveWeatherTestRetainer.retain(weatherHomeBuilderSpy)

        _ = container.makeWeatherHomeViewModel()

        XCTAssertEqual(weatherHomeBuilderSpy.makeCallCount, 1)
    }

    @MainActor
    func testAppContainerCreatesIndependentWeatherHomeViewModels() {
        let forecastProviderSpy = ForecastFeatureProviderSpy(stubbedDays: [])
        let searchProviderSpy = SearchFeatureProviderSpy(stubbedResults: [])

        let container = AppContainer(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://example.com/v1/current.json",
            currentWeatherFeatureBuilder: { _, _ in
                CurrentWeatherFeatureFactory.liveViewModelFactory(
                    weatherAPIKey: "test-key",
                    weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
                )
            },
            forecastFeatureBuilder: { _, _ in
                forecastProviderSpy
            },
            searchFeatureBuilder: {
                searchProviderSpy
            }
        )
        LiveWeatherTestRetainer.retain(container)

        let first = container.makeWeatherHomeViewModel()
        let second = container.makeWeatherHomeViewModel()

        XCTAssertFalse(first === second)
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

private final class CurrentWeatherViewModelFactorySpy: @unchecked Sendable {
    private let backingProvider: any CurrentWeatherFeatureProviding
    private(set) var makeWeatherViewModelCallCount = 0

    init(backingProvider: any CurrentWeatherFeatureProviding = CurrentWeatherFeatureFactory.live(
        weatherAPIKey: "test-key",
        weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
    )) {
        self.backingProvider = backingProvider
    }

    func make() -> CurrentWeatherViewModel {
        makeWeatherViewModelCallCount += 1
        return backingProvider.makeWeatherViewModel()
    }
}

@MainActor
private final class WeatherHomeFeatureBuilderSpy {
    private(set) var makeCallCount = 0

    func make(
        currentWeatherViewModelFactory: @escaping CurrentWeatherViewModelFactory,
        forecastProvider: any ForecastFeatureProviding,
        searchProvider: any SearchFeatureProviding
    ) -> LiveWeatherHomeScreenViewModel {
        makeCallCount += 1
        return LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherViewModelFactory(),
            forecastProvider: forecastProvider,
            searchProvider: searchProvider
        )
    }
}

private enum LiveWeatherTestRetainer {
    static var retainedObjects: [AnyObject] = []

    static func retain(_ object: AnyObject) {
        retainedObjects.append(object)
    }
}

private actor ForecastFeatureProviderSpy: ForecastFeatureProviding {
    private let stubbedDays: [ForecastDay]

    init(stubbedDays: [ForecastDay]) {
        self.stubbedDays = stubbedDays
    }

    func fetchForecast(location _: String, days _: Int) async throws -> [ForecastDay] {
        stubbedDays
    }
}

private actor SearchFeatureProviderSpy: SearchFeatureProviding {
    private let stubbedResults: [SearchLocation]
    private let stubbedError: Error?
    private var queries: [String] = []

    init(stubbedResults: [SearchLocation], stubbedError: Error? = nil) {
        self.stubbedResults = stubbedResults
        self.stubbedError = stubbedError
    }

    func search(query: String) async throws -> [SearchLocation] {
        queries.append(query)
        if let stubbedError {
            throw stubbedError
        }
        return stubbedResults
    }

    func lastQuery() -> String? {
        queries.last
    }
}
