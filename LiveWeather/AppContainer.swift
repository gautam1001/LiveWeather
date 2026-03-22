//
//  AppContainer.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

import Data
import Domain
import Presentation

final class AppContainer {
    
    private let repository: WeatherRepository
    
    public init() {
        let apikey = AppConfig.weatherAPIKey
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: apikey)
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let dataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        self.repository = WeatherRemoteRepository(dataSource: dataSource)
    }
    
    func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: self.repository))
    }
}
