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

final class AppContainer {
    typealias CurrentWeatherViewModelFactoryBuilder =
        (_ apiKey: String, _ apiURL: String) -> CurrentWeatherViewModelFactory
    typealias ForecastFeatureBuilder =
        (_ apiKey: String, _ apiURL: String) -> any ForecastFeatureProviding

    private let weatherViewModelFactory: CurrentWeatherViewModelFactory
    private let forecastProvider: any ForecastFeatureProviding

    convenience init(
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live
    ) {
        self.init(
            weatherAPIKey: AppConfig.weatherAPIKey,
            weatherAPIURL: AppConfig.weatherAPIUrl,
            currentWeatherFeatureBuilder: currentWeatherFeatureBuilder,
            forecastFeatureBuilder: forecastFeatureBuilder
        )
    }

    init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live
    ) {
        #if DEV
            print("DEV")
        #elseif QA
            print("QA")
        #elseif PROD
            print("PRODUCTION")
        #endif
        weatherViewModelFactory = currentWeatherFeatureBuilder(weatherAPIKey, weatherAPIURL)
        forecastProvider = forecastFeatureBuilder(weatherAPIKey, weatherAPIURL)
    }

    func makeWeatherViewModel() -> CurrentWeatherViewModel {
        weatherViewModelFactory()
    }

    func fetchDefaultForecast() async throws -> [ForecastDay] {
        try await forecastProvider.fetchForecast(location: "New Delhi", days: 5)
    }
}
