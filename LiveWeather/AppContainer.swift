//
//  AppContainer.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 21/03/26.
//

import Data
import Domain
import Foundation
import Presentation

@MainActor
final class AppContainer {
    typealias WeatherRepositoryFactory = (_ apiKey: String, _ apiURL: String) -> WeatherRepository

    private let repository: WeatherRepository

    convenience init(repositoryFactory: WeatherRepositoryFactory = AppContainer.liveRepositoryFactory) {
        self.init(
            weatherAPIKey: AppConfig.weatherAPIKey,
            weatherAPIURL: AppConfig.weatherAPIUrl,
            repositoryFactory: repositoryFactory
        )
    }

    init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        repositoryFactory: WeatherRepositoryFactory = AppContainer.liveRepositoryFactory
    ) {
        #if DEV
            print("DEV")
        #elseif QA
            print("QA")
        #elseif PROD
            print("PRODUCTION")
        #endif
        repository = repositoryFactory(weatherAPIKey, weatherAPIURL)
    }

    func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: repository))
    }

    private nonisolated static func liveRepositoryFactory(apiKey: String, apiURL: String) -> WeatherRepository {
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: apiKey, apiUrl: apiURL)
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let dataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        return WeatherRemoteRepository(dataSource: dataSource)
    }
}
