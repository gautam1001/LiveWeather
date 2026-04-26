//
//  LiveWeatherApp.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 20/03/26.
//

import AppComposition
import SwiftUI

@main
struct LiveWeatherApp: App {
    private let container = AppContainer(
        weatherAPIKey: AppConfig.weatherAPIKey,
        weatherAPIURL: AppConfig.weatherAPIUrl
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: container.makeWeatherHomeViewModel())
        }
    }
}
