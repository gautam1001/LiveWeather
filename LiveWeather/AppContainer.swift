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
        
        let url = URL(string: "https://api.weatherapi.com/v1/forecast.json")!
        let config = WeatherAPIConfig(baseURL: url, apiKey: "7f3853a85ef941f2bed71713240110")
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let dataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        self.repository = WeatherRemoteRepository(dataSource: dataSource)
    }
    
    func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: self.repository))
    }
}
