import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import ForecastFeatureAPI
import ForecastFeatureImpl
import Foundation
import SearchFeatureAPI
import SearchFeatureImpl
import WeatherHomeFeatureAPI
import WeatherHomeFeatureImpl

public final class AppContainer {
    public typealias CurrentWeatherViewModelFactoryBuilder =
        (_ apiKey: String, _ apiURL: String) -> CurrentWeatherViewModelFactory
    public typealias ForecastFeatureBuilder =
        (_ apiKey: String, _ apiURL: String) -> any ForecastFeatureProviding
    public typealias SearchFeatureBuilder = () -> any SearchFeatureProviding
    public typealias WeatherHomeFeatureBuilder =
        @MainActor (
            _ currentWeatherViewModelFactory: @escaping CurrentWeatherViewModelFactory,
            _ forecastProvider: any ForecastFeatureProviding,
            _ searchProvider: any SearchFeatureProviding
        ) -> LiveWeatherHomeScreenViewModel

    private let weatherViewModelFactory: CurrentWeatherViewModelFactory
    private let weatherHomeViewModelFactory: @MainActor () -> LiveWeatherHomeScreenViewModel

    public init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live,
        searchFeatureBuilder: @escaping SearchFeatureBuilder = SearchFeatureFactory.live,
        weatherHomeFeatureBuilder: WeatherHomeFeatureBuilder? = nil
    ) {
        let resolvedWeatherHomeFeatureBuilder =
            weatherHomeFeatureBuilder ?? AppContainer.defaultWeatherHomeFeatureBuilder
        let currentWeatherFactory = currentWeatherFeatureBuilder(weatherAPIKey, weatherAPIURL)
        let forecastProvider = forecastFeatureBuilder(weatherAPIKey, weatherAPIURL)
        let searchProvider = searchFeatureBuilder()
        weatherViewModelFactory = currentWeatherFactory
        weatherHomeViewModelFactory = {
            resolvedWeatherHomeFeatureBuilder(currentWeatherFactory, forecastProvider, searchProvider)
        }
    }

    public func makeWeatherViewModel() -> CurrentWeatherViewModel {
        weatherViewModelFactory()
    }

    @MainActor
    public func makeWeatherHomeViewModel() -> LiveWeatherHomeScreenViewModel {
        weatherHomeViewModelFactory()
    }
}

@MainActor
private extension AppContainer {
    static func defaultWeatherHomeFeatureBuilder(
        currentWeatherViewModelFactory: @escaping CurrentWeatherViewModelFactory,
        forecastProvider: any ForecastFeatureProviding,
        searchProvider: any SearchFeatureProviding
    ) -> LiveWeatherHomeScreenViewModel {
        WeatherHomeFeatureFactory.live(
            currentWeatherViewModelFactory: currentWeatherViewModelFactory,
            forecastProvider: forecastProvider,
            searchProvider: searchProvider
        )
    }
}
