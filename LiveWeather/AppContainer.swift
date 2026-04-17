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

@MainActor
final class AppContainer {
    typealias CurrentWeatherViewModelFactoryBuilder =
        (_ apiKey: String, _ apiURL: String) -> CurrentWeatherViewModelFactory
    typealias ForecastFeatureBuilder =
        (_ apiKey: String, _ apiURL: String) -> any ForecastFeatureProviding
    typealias SearchFeatureBuilder = () -> any SearchFeatureProviding

    private let weatherViewModelFactory: CurrentWeatherViewModelFactory
    private let forecastProvider: any ForecastFeatureProviding
    private let searchProvider: any SearchFeatureProviding
    private var selectedLocation = "New Delhi"

    convenience init(
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live,
        searchFeatureBuilder: @escaping SearchFeatureBuilder = SearchFeatureFactory.live
    ) {
        self.init(
            weatherAPIKey: AppConfig.weatherAPIKey,
            weatherAPIURL: AppConfig.weatherAPIUrl,
            currentWeatherFeatureBuilder: currentWeatherFeatureBuilder,
            forecastFeatureBuilder: forecastFeatureBuilder,
            searchFeatureBuilder: searchFeatureBuilder
        )
    }

    init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder =
            CurrentWeatherFeatureFactory.liveViewModelFactory,
        forecastFeatureBuilder: @escaping ForecastFeatureBuilder = ForecastFeatureFactory.live,
        searchFeatureBuilder: @escaping SearchFeatureBuilder = SearchFeatureFactory.live
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
        searchProvider = searchFeatureBuilder()
    }

    func makeWeatherViewModel() -> CurrentWeatherViewModel {
        weatherViewModelFactory()
    }

    func fetchDefaultForecast() async throws -> [ForecastDay] {
        let safeLocation = String(selectedLocation)
        return try await forecastProvider.fetchForecast(location: safeLocation, days: 5)
    }

    func searchLocations(query: String) async throws -> [SearchLocation] {
        let safeQuery = String(query)
        return try await searchProvider.search(query: safeQuery)
    }

    func selectLocation(_ location: String) {
        selectedLocation = location
    }
}
