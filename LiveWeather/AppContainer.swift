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
        #if DEV
        print("DEV")
        #elseif QA
        print("QA")
        #elseif PROD
        print("PRODUCTION")
        #endif
        let apikey = AppConfig.weatherAPIKey
        let apiUrl = AppConfig.weatherAPIUrl
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: apikey, apiUrl: apiUrl)
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let dataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        self.repository = WeatherRemoteRepository(dataSource: dataSource)
    }
    
    func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: self.repository))
    }
}
