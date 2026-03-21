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
        self.repository = WeatherRemoteRepository()
    }
    
    func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: self.repository))
    }
}
