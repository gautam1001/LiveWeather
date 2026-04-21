//
//  AppContainer.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 21/03/26.
//

import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import ForecastFeatureAPI
import ForecastFeatureImpl
import Foundation
import SearchFeatureAPI
import SearchFeatureImpl
import WeatherHomeFeatureAPI
import WeatherHomeFeatureImpl

final class AppContainer {
    typealias CurrentWeatherViewModelFactoryBuilder =
        (_ apiKey: String, _ apiURL: String) -> CurrentWeatherViewModelFactory
    typealias ForecastFeatureBuilder =
        (_ apiKey: String, _ apiURL: String) -> any ForecastFeatureProviding
    typealias SearchFeatureBuilder = () -> any SearchFeatureProviding
    typealias WeatherHomeFeatureBuilder =
        @MainActor (
            _ currentWeatherViewModelFactory: @escaping CurrentWeatherViewModelFactory,
            _ forecastProvider: any ForecastFeatureProviding,
            _ searchProvider: any SearchFeatureProviding
        ) -> LiveWeatherHomeScreenViewModel

    private let weatherViewModelFactory: CurrentWeatherViewModelFactory
    private let weatherHomeViewModelFactory: @MainActor () -> LiveWeatherHomeScreenViewModel

    convenience init(
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live,
        searchFeatureBuilder: @escaping SearchFeatureBuilder = SearchFeatureFactory.live,
        weatherHomeFeatureBuilder: @escaping WeatherHomeFeatureBuilder =
            AppContainer.defaultWeatherHomeFeatureBuilder
    ) {
        self.init(
            weatherAPIKey: AppConfig.weatherAPIKey,
            weatherAPIURL: AppConfig.weatherAPIUrl,
            currentWeatherFeatureBuilder: currentWeatherFeatureBuilder,
            forecastFeatureBuilder: forecastFeatureBuilder,
            searchFeatureBuilder: searchFeatureBuilder,
            weatherHomeFeatureBuilder: weatherHomeFeatureBuilder
        )
    }

    init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live,
        searchFeatureBuilder: @escaping SearchFeatureBuilder = SearchFeatureFactory.live,
        weatherHomeFeatureBuilder: @escaping WeatherHomeFeatureBuilder =
            AppContainer.defaultWeatherHomeFeatureBuilder
    ) {
        #if DEV
            print("DEV")
        #elseif QA
            print("QA")
        #elseif PROD
            print("PRODUCTION")
        #endif
        let currentWeatherFactory = currentWeatherFeatureBuilder(weatherAPIKey, weatherAPIURL)
        let forecastProvider = forecastFeatureBuilder(weatherAPIKey, weatherAPIURL)
        let searchProvider = searchFeatureBuilder()
        weatherViewModelFactory = currentWeatherFactory
        weatherHomeViewModelFactory = {
            weatherHomeFeatureBuilder(currentWeatherFactory, forecastProvider, searchProvider)
        }
    }

    func makeWeatherViewModel() -> CurrentWeatherViewModel {
        weatherViewModelFactory()
    }

    @MainActor
    func makeWeatherHomeViewModel() -> LiveWeatherHomeScreenViewModel {
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
