//
//  LiveWeatherApp.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import SwiftUI

@main
struct LiveWeatherApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: container.makeWeatherViewModel(),
                forecastLoader: {
                    try await container.fetchDefaultForecast()
                }
            )
        }
    }
}
