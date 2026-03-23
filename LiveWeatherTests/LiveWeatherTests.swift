//
//  LiveWeatherTests.swift
//  LiveWeatherTests
//
//  Created by Prashant Gautam on 20/03/26.
//

import XCTest
import Presentation
import Domain
@testable import LiveWeather

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
    func testContentViewCanBeInitializedWithInjectedViewModel() {
        let repository = WeatherRepositoryStub(result: .success(sampleWeather))
        let useCase = CurrentWeatherUsecase(repository: repository)
        let viewModel = WeatherOverviewViewModel(usecase: useCase)
        let view = ContentView(viewModel: viewModel)

        _ = view.body
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testContentViewAcceptsDistinctInjectedViewModels() {
        let first = WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: WeatherRepositoryStub(result: .success(sampleWeather))))
        let second = WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: WeatherRepositoryStub(result: .success(sampleWeather))))

        let firstView = ContentView(viewModel: first)
        let secondView = ContentView(viewModel: second)

        _ = firstView.body
        _ = secondView.body
        XCTAssertFalse(first === second)
    }

    @MainActor
    func testViewModelLoadTransitionsToLoadedStateOnSuccess() async {
        let viewModel = WeatherOverviewViewModel(
            usecase: CurrentWeatherUsecase(repository: WeatherRepositoryStub(result: .success(sampleWeather)))
        )

        await viewModel.load(for: "Ghaziabad")

        guard case .loaded(let overview) = viewModel.state else {
            return XCTFail("Expected .loaded state")
        }

        XCTAssertEqual(overview.locationName, "Ghaziabad")
        XCTAssertEqual(overview.current, sampleWeather)
    }

    @MainActor
    func testViewModelLoadTransitionsToFailedStateOnFailure() async {
        let viewModel = WeatherOverviewViewModel(
            usecase: CurrentWeatherUsecase(repository: WeatherRepositoryStub(result: .failure(WeatherRepositoryStubError.network)))
        )

        await viewModel.load(for: "Ghaziabad")

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected .failed state")
        }

        XCTAssertFalse(message.isEmpty)
    }

}

private let sampleWeather = WeatherNow(
    temperatureC: 29.8,
    conditionCode: 1000,
    conditionSummary: "Clear",
    conditionDescription: "clear sky"
)

private actor WeatherRepositoryStub: WeatherRepository {
    private let result: Result<WeatherNow, Error>

    init(result: Result<WeatherNow, Error>) {
        self.result = result
    }

    func getCurrentWeather(for location: Location) async throws -> WeatherNow {
        _ = location
        return try result.get()
    }
}

private enum WeatherRepositoryStubError: Error {
    case network
}
