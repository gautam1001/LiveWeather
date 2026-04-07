//
//  AppContainer.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 21/03/26.
//

import CurrentWeatherFeatureAPI
import CurrentWeatherFeatureImpl
import Foundation

final class AppContainer {
    typealias CurrentWeatherViewModelFactoryBuilder = (_ apiKey: String, _ apiURL: String) -> CurrentWeatherViewModelFactory

    private let weatherViewModelFactory: CurrentWeatherViewModelFactory

    convenience init(
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder = CurrentWeatherFeatureFactory.liveViewModelFactory
    ) {
        self.init(
            weatherAPIKey: AppConfig.weatherAPIKey,
            weatherAPIURL: AppConfig.weatherAPIUrl,
            currentWeatherFeatureBuilder: currentWeatherFeatureBuilder
        )
    }

    init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        currentWeatherFeatureBuilder: @escaping CurrentWeatherViewModelFactoryBuilder = CurrentWeatherFeatureFactory.liveViewModelFactory
    ) {
        #if DEV
            print("DEV")
        #elseif QA
            print("QA")
        #elseif PROD
            print("PRODUCTION")
        #endif
        weatherViewModelFactory = currentWeatherFeatureBuilder(weatherAPIKey, weatherAPIURL)
    }

    func makeWeatherViewModel() -> CurrentWeatherViewModel {
        weatherViewModelFactory()
    }
}
