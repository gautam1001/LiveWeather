import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import XCTest

@MainActor
final class CurrentWeatherFeatureTests: XCTestCase {
    func testLiveFactoryCreatesProvider() {
        let provider = CurrentWeatherFeatureFactory.live(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )

        let viewModel = provider.makeWeatherViewModel()

        XCTAssertNotNil(viewModel)
    }

    func testProviderCreatesIndependentViewModels() {
        let provider = CurrentWeatherFeatureFactory.live(
            weatherAPIKey: "test-key",
            weatherAPIURL: "https://api.weatherapi.com/v1/current.json"
        )

        let first = provider.makeWeatherViewModel()
        let second = provider.makeWeatherViewModel()

        XCTAssertFalse(first === second)
    }
}
